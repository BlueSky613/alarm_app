import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:dawn_weaver/services/wallet_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dawn_weaver/utils/api_base_url.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:dawn_weaver/main.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/screens/alarms_list_screen.dart';
import 'package:dawn_weaver/screens/avatar_selection_screen.dart';
import 'package:dawn_weaver/screens/premium_screen.dart';
import 'package:dawn_weaver/utils/profile_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  UserProfile? _userProfile;
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _hapticEnabled = true;
  bool _soundNotificationsEnabled = true;
  ImageProvider _avatarImage = const AssetImage('assets/solrise_logo.png');

  static const Color _kPrimaryGreen = Color(0xFF0EF196);
  static const String _skrMint = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';

  late SolanaClient _solanaClient;
  final String _walletClusterName = 'mainnet-beta';
  SolanaWalletAdapter? _walletAdapter;
  bool _isChangingWallet = false;
  Timer? _walletChangeFailsafeTimer;
  int _walletChangeGeneration = 0;
  bool _appLeftForegroundDuringWalletChange = false;

  static const Map<ZodiacSign, IconData> _zodiacIcons = {
    ZodiacSign.aries: Icons.local_fire_department,
    ZodiacSign.taurus: Icons.terrain,
    ZodiacSign.gemini: Icons.people,
    ZodiacSign.cancer: Icons.nightlight_round,
    ZodiacSign.leo: Icons.wb_sunny,
    ZodiacSign.virgo: Icons.eco,
    ZodiacSign.libra: Icons.balance,
    ZodiacSign.scorpio: Icons.water_drop,
    ZodiacSign.sagittarius: Icons.travel_explore,
    ZodiacSign.capricorn: Icons.landscape,
    ZodiacSign.aquarius: Icons.waves,
    ZodiacSign.pisces: Icons.opacity,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSolanaClient();
    _loadUserProfile();
    _initWalletAdapter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_isChangingWallet) {
          _appLeftForegroundDuringWalletChange = true;
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (_isChangingWallet && _appLeftForegroundDuringWalletChange) {
          _appLeftForegroundDuringWalletChange = false;
          _scheduleWalletSpinnerRecoveryAfterResume();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Wallet sheet / external app can leave `authorize()` hanging; when user returns here, clear UI.
  void _scheduleWalletSpinnerRecoveryAfterResume() {
    final gen = _walletChangeGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _walletChangeGeneration || !_isChangingWallet) {
        return;
      }
      setState(() => _isChangingWallet = false);
    });
  }

  void _armWalletChangeFailsafe() {
    _walletChangeFailsafeTimer?.cancel();
    final gen = _walletChangeGeneration;
    _walletChangeFailsafeTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || gen != _walletChangeGeneration || !_isChangingWallet) {
        return;
      }
      setState(() => _isChangingWallet = false);
    });
  }

  void _disarmWalletChangeFailsafe() {
    _walletChangeFailsafeTimer?.cancel();
    _walletChangeFailsafeTimer = null;
  }

  void _setupSolanaClient() {
    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse(
        _walletClusterName == 'mainnet-beta'
            ? 'https://api.mainnet-beta.solana.com'
            : 'https://api.testnet.solana.com',
      ),
      websocketUrl: Uri.parse(
        _walletClusterName == 'mainnet-beta'
            ? 'wss://api.mainnet-beta.solana.com'
            : 'wss://api.testnet.solana.com',
      ),
    );
  }

  Cluster get _walletCluster {
    switch (_walletClusterName) {
      case 'mainnet-beta':
        return Cluster.mainnet;
      case 'devnet':
        return Cluster.devnet;
      case 'testnet':
        return Cluster.testnet;
      default:
        return Cluster.mainnet;
    }
  }

  String? _base64AddressToBase58(String? base64Address) {
    if (base64Address == null || base64Address.isEmpty) return null;
    try {
      final bytes = base64.decode(base64Address);
      return Ed25519HDPublicKey(bytes).toBase58();
    } catch (_) {
      return null;
    }
  }

  Future<void> _initWalletAdapter() async {
    await SolanaWalletAdapter.initialize();
    if (!mounted) return;
    setState(() {
      _walletAdapter = SolanaWalletAdapter(
        AppIdentity(
          name: 'SolRise',
          uri: Uri.parse('https://solrise.cloud')
        ),
        cluster: _walletCluster,
      );
    });
  }

  bool get _isSpanish => _userProfile?.language == 'es';

  Future<void> _onChangeWalletPressed() async {
    if (_userProfile == null || _isChangingWallet) return;

    final baseUrl = resolveApiBaseUrl(dotenv.env['base_url']);
    if (baseUrl.isEmpty) return;

    final apiToken = await StorageService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) return;

    final adapter = _walletAdapter;
    if (adapter == null) return;

    _walletChangeGeneration++;
    _appLeftForegroundDuringWalletChange = false;
    setState(() => _isChangingWallet = true);
    _armWalletChangeFailsafe();

    const authorizeTimeout = Duration(seconds: 90);
    const deauthorizeTimeout = Duration(seconds: 45);

    try {
      if (adapter.isAuthorized) {
        try {
          await adapter.deauthorize().timeout(deauthorizeTimeout);
        } catch (_) {}
      }

      // Closing the wallet UI may update storage before `authorize()`'s Future completes — reset next frame.
      void onAdapterStorageChanged() {
        if (!_isChangingWallet) return;
        final authorized =
            adapter.isAuthorized &&
            (adapter.authorizeResult?.accounts.isNotEmpty ?? false);
        if (authorized) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_isChangingWallet) return;
          setState(() => _isChangingWallet = false);
        });
      }

      adapter.addListener(onAdapterStorageChanged);
      try {
        try {
          await adapter.authorize().timeout(authorizeTimeout);
        } on TimeoutException {
          rethrow;
        } catch (_) {
          if (mounted) setState(() => _isChangingWallet = false);
          return;
        }
      } finally {
        adapter.removeListener(onAdapterStorageChanged);
      }

      final accounts = adapter.authorizeResult?.accounts ?? const [];
      final account =
          adapter.connectedAccount ??
          (accounts.isNotEmpty ? accounts.first : null);
      if (account == null) return;

      final address =
          _base64AddressToBase58(account.address) ?? account.address;
      final current = _userProfile!.solanaAddress?.trim() ?? '';
      if (address == current) return;

      double totalBalance = 0.0;
      try {
        final skrResult = await _solanaClient.rpcClient.getTokenAccountsByOwner(
          address,
          const TokenAccountsFilter.byMint(_skrMint),
          encoding: Encoding.jsonParsed,
        );
        if (skrResult.value.isNotEmpty) {
          for (final acc in skrResult.value) {
            final data = acc.account.data;
            if (data is ParsedAccountData) {
              final info = data.toJson()['parsed']['info'];
              final tokenAmount = info['tokenAmount'];
              totalBalance += double.parse(
                tokenAmount['uiAmountString'] as String,
              );
            }
          }
        }
      } catch (_) {
        // Balance is optional for profile; continue with 0
      }

      final result = await changeWalletWithApiToken(
        apiToken: apiToken,
        newWalletAddress: address,
        cluster: _walletClusterName,
      );

      if (!mounted) return;

      if (result.token != null && result.token!.isNotEmpty) {
        await StorageService.saveAuthToken(result.token!);
        final updated = _userProfile!.copyWith(
          solanaAddress: address,
          solanaBalance: totalBalance,
        );
        await StorageService.saveUserProfile(updated);
        if (!mounted) return;
        setState(() => _userProfile = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSpanish ? 'Billetera actualizada.' : 'Wallet updated.',
            ),
          ),
        );
        return;
      }
    } on TimeoutException {
      // Silent — no error UI for change-wallet flow.
    } catch (_) {
      // Silent.
    } finally {
      _disarmWalletChangeFailsafe();
      if (mounted) {
        setState(() => _isChangingWallet = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _isChangingWallet = false);
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await StorageService.getUserProfile();
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
        _hapticEnabled = profile.hapticEnabled;
        _soundNotificationsEnabled = profile.soundNotificationsEnabled;
        _avatarImage = avatarImageProviderFromRef(profile.avatarRef);
      });
    }
  }

  Future<void> _persistToggleHaptic() async {
    if (_userProfile == null) return;
    final next = !_hapticEnabled;
    setState(() => _hapticEnabled = next);
    final updated = _userProfile!.copyWith(hapticEnabled: next);
    await StorageService.saveUserProfile(updated);
    if (mounted) setState(() => _userProfile = updated);
  }

  Future<void> _persistToggleSound() async {
    if (_userProfile == null) return;
    final next = !_soundNotificationsEnabled;
    setState(() => _soundNotificationsEnabled = next);
    final updated = _userProfile!.copyWith(soundNotificationsEnabled: next);
    await StorageService.saveUserProfile(updated);
    if (mounted) setState(() => _userProfile = updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              decoration: const BoxDecoration(color: Colors.black),
              child: _userProfile == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Header with back + centered title + edit
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white.withOpacity(0.03),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    l10n.settings.toUpperCase(),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProfileSection(),
                                const SizedBox(height: 32),
                                _buildGeneralPreferencesSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildGeneralPreferencesSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final currentLanguageLabel = _userProfile?.language == 'es'
        ? 'Español (ES)'
        : 'English (US)';
    final currentZodiac = _getZodiacName(_userProfile!.zodiacSign);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(left: 4),
        //   child: Text(
        //     l10n.generalSettings.toUpperCase(),
        //     style: theme.textTheme.labelSmall?.copyWith(
        //       fontSize: 11,
        //       letterSpacing: 4,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.white.withOpacity(0.4),
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: <Widget>[
                  // _buildGlassRow(
                  //   icon: Icons.language,
                  //   title: l10n.language,
                  //   value: currentLanguageLabel,
                  //   showDivider: true,
                  //   onTap: _showLanguageSheet,
                  // ),
                  _buildGlassRow(
                    icon: Icons.stars,
                    title: l10n.selectZodiacSign,
                    value: currentZodiac,
                    showDivider: true,
                    onTap: _showZodiacSheet,
                  ),
                  _buildToggleGlassRow(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    value: _hapticEnabled,
                    showDivider: true,
                    onToggle: () => _persistToggleHaptic(),
                  ),
                  _buildToggleGlassRow(
                    icon: Icons.notifications_active,
                    title: 'Sound Notifications',
                    value: _soundNotificationsEnabled,
                    showDivider: false,
                    onToggle: () => _persistToggleSound(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassRow({
    required IconData icon,
    required String title,
    required String value,
    required bool showDivider,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleGlassRow({
    required IconData icon,
    required String title,
    required bool value,
    required bool showDivider,
    required VoidCallback onToggle,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: value
                    ? theme.colorScheme.primary
                    : Colors.white.withOpacity(0.12),
              ),
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet() async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    String tempLanguage = _userProfile?.language ?? 'en';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.language,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(
                                  Icons.language,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLanguageChoiceTile(
                                  label: 'English (US)',
                                  code: 'en',
                                  isSelected: tempLanguage == 'en',
                                  onTap: () {
                                    setStateDialog(() {
                                      tempLanguage = 'en';
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildLanguageChoiceTile(
                                  label: 'Español (ES)',
                                  code: 'es',
                                  isSelected: tempLanguage == 'es',
                                  onTap: () {
                                    setStateDialog(() {
                                      tempLanguage = 'es';
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      backgroundColor: Colors.white.withOpacity(
                                        0.05,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                    child: Text(
                                      l10n.cancel,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 8,
                                      shadowColor: theme.colorScheme.primary
                                          .withOpacity(0.4),
                                    ),
                                    onPressed: () async {
                                      Navigator.of(dialogContext).pop();
                                      if (tempLanguage !=
                                          _userProfile?.language) {
                                        await _updateLanguage(tempLanguage);
                                      }
                                    },
                                    child: Text(
                                      l10n.save,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditNameSheet() async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, bottom: bottomInset),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SafeArea(
                  top: false,
                  child: _EditUsernameSheetContent(
                    theme: theme,
                    initialName: _userProfile?.name ?? '',
                    onSave: (trimmed) {
                      if (!mounted) return;
                      _nameController.text = trimmed;
                      _saveProfile();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageChoiceTile({
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showZodiacSheet() async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final bottomPadding = mediaQuery.viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(left: 0, right: 0, bottom: bottomPadding),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 4,
                        width: 56,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Text(
                        l10n.selectZodiacSign,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Align your daily insights with the stars',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 360,
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            for (final sign in ZodiacSign.values)
                              _buildZodiacGridItem(
                                sign: sign,
                                isSelected: _userProfile!.zodiacSign == sign,
                                onTap: () async {
                                  await _updateZodiacSign(sign);
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildZodiacGridItem({
    required ZodiacSign sign,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final icon = _zodiacIcons[sign] ?? Icons.star;
    final name = _getZodiacName(sign).toUpperCase();

    final Color primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(isSelected ? 0.06 : 0.03),
          border: Border.all(
            color: isSelected
                ? primary.withOpacity(0.8)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? primary.withOpacity(0.12)
                    : Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                icon,
                color: isSelected ? primary : Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: isSelected ? primary : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const Color _kBackgroundDark = Color(0xFF000000);
    const Color _kPrimary = Color(0xFF0EF196);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kBackgroundDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.home_outlined,
            label: 'HOME',
            isSelected: false,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
          _buildNavButton(
            icon: Icons.alarm_outlined,
            label: 'MY ALARMS',
            isSelected: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlarmsListScreen(),
                ),
              );
            },
          ),
          _buildNavButton(
            icon: Icons.diamond_outlined,
            label: 'PREMIUM',
            isSelected: false,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PremiumScreen()),
              );
            },
          ),
          _buildNavButton(
            icon: Icons.settings_outlined,
            label: 'SETTINGS',
            isSelected: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const Color _kPrimary = Color(0xFF0EF196);
    final inactiveColor = Colors.white.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isSelected ? _kPrimary : inactiveColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _kPrimary : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow behind avatar
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              // Avatar image with border
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF171717),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image(image: _avatarImage, fit: BoxFit.cover),
                ),
              ),
              // Edit avatar button (top-right)
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: _showEditAvatarSheet,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.85),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
              // Verified badge (bottom-right)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.9),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isEditing)
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).editProfile,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userProfile!.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _showEditNameSheet,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        if ((_userProfile?.solanaAddress ?? '').isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _shortWallet(_userProfile!.solanaAddress!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: const Color.fromRGBO(14, 241, 150, 0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        final addr = _userProfile!.solanaAddress!;
                        Clipboard.setData(ClipboardData(text: addr));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isSpanish
                                  ? 'Dirección copiada'
                                  : 'Wallet address copied',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isChangingWallet ? null : _onChangeWalletPressed,
                icon: Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: _kPrimaryGreen.withOpacity(0.95),
                ),
                label: Text(
                  _isSpanish ? 'Cambiar billetera' : 'Change wallet',
                  style: TextStyle(
                    color: _kPrimaryGreen.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _shortWallet(String full) {
    if (full.length <= 8) return full;
    return '${full.substring(0, 4)}...${full.substring(full.length - 4)}';
  }

  Future<void> _showEditAvatarSheet() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          initialAvatarRef: _userProfile?.avatarRef ?? 'default',
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null && _userProfile != null) {
      final updated = _userProfile!.copyWith(avatarRef: selected);
      await StorageService.saveUserProfile(updated);
      if (!mounted) return;
      setState(() {
        _userProfile = updated;
        _avatarImage = avatarImageProviderFromRef(selected);
      });
    }
  }

  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      title: l10n.language,
      icon: Icons.language,
      children: [
        _buildLanguageOption('es', '🇪🇸', l10n.spanish),
        const SizedBox(height: 8),
        _buildLanguageOption('en', '🇺🇸', l10n.english),
      ],
    );
  }

  Widget _buildLanguageOption(String code, String flag, String name) {
    final isSelected = _userProfile!.language == code;

    return GestureDetector(
      onTap: _isEditing ? () => _updateLanguage(code) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      title: l10n.selectZodiacSign,
      icon: Icons.star,
      children: [
        if (_isEditing)
          DropdownButtonFormField<ZodiacSign>(
            value: _userProfile!.zodiacSign,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ZodiacSign.values.map((sign) {
              final profile = UserProfile(name: '', zodiacSign: sign);
              return DropdownMenuItem<ZodiacSign>(
                value: sign,
                child: Row(
                  children: [
                    Text(
                      profile.zodiacEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(_getZodiacName(sign)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ZodiacSign? value) {
              if (value != null) {
                _updateZodiacSign(value);
              }
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Text(
                  _userProfile!.zodiacEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getZodiacName(_userProfile!.zodiacSign),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getZodiacDates(_userProfile!.zodiacSign),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSection(
      title: l10n.generalSettings,
      icon: Icons.settings,
      children: [
        _buildPreferenceItem(
          icon: Icons.notifications,
          title: l10n.notificationPermission,
          subtitle: l10n.allowNotifications,
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onTap: _openNotificationSettings,
        ),
        const SizedBox(height: 12),
        _buildPreferenceItem(
          icon: Icons.volume_up,
          title: l10n.audioSettings,
          subtitle: l10n.manageAudio,
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          onTap: _openAudioSettings,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children.expand((w) => [w]).toList()),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDanger = titleColor == theme.colorScheme.error;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (titleColor ?? theme.colorScheme.primary).withOpacity(
                    isDanger ? 0.08 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: titleColor ?? theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: titleColor ?? Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  String _getZodiacName(ZodiacSign sign) {
    const names = {
      ZodiacSign.aries: 'Aries',
      ZodiacSign.taurus: 'Taurus',
      ZodiacSign.gemini: 'Gemini',
      ZodiacSign.cancer: 'Cancer',
      ZodiacSign.leo: 'Leo',
      ZodiacSign.virgo: 'Virgo',
      ZodiacSign.libra: 'Libra',
      ZodiacSign.scorpio: 'Scorpio',
      ZodiacSign.sagittarius: 'Sagittarius',
      ZodiacSign.capricorn: 'Capricorn',
      ZodiacSign.aquarius: 'Aquarius',
      ZodiacSign.pisces: 'Pisces',
    };
    return names[sign] ?? '';
  }

  String _getZodiacDates(ZodiacSign sign) {
    const dates = {
      ZodiacSign.aries: 'Mar 21 - Apr 19',
      ZodiacSign.taurus: 'Apr 20 - May 20',
      ZodiacSign.gemini: 'May 21 - Jun 20',
      ZodiacSign.cancer: 'Jun 21 - Jul 22',
      ZodiacSign.leo: 'Jul 23 - Aug 22',
      ZodiacSign.virgo: 'Aug 23 - Sep 22',
      ZodiacSign.libra: 'Sep 23 - Oct 22',
      ZodiacSign.scorpio: 'Oct 23 - Nov 21',
      ZodiacSign.sagittarius: 'Nov 22 - Dec 21',
      ZodiacSign.capricorn: 'Dec 22 - Jan 19',
      ZodiacSign.aquarius: 'Jan 20 - Feb 18',
      ZodiacSign.pisces: 'Feb 19 - Mar 20',
    };
    return dates[sign] ?? '';
  }

  Future<void> _updateLanguage(String language) async {
    if (_userProfile == null) return;
    final updated = _userProfile!.copyWith(language: language);
    setState(() => _userProfile = updated);
    await languageService.changeLanguage(language);
    await StorageService.saveUserProfile(updated);
    if (mounted) setState(() => _userProfile = updated);
  }

  Future<void> _updateZodiacSign(ZodiacSign zodiacSign) async {
    if (_userProfile == null) return;
    final updated = _userProfile!.copyWith(zodiacSign: zodiacSign);
    await StorageService.saveUserProfile(updated);
    if (mounted) setState(() => _userProfile = updated);
  }

  void _saveProfile() async {
    if (_userProfile != null && _nameController.text.trim().isNotEmpty) {
      final updatedProfile = _userProfile!.copyWith(
        name: _nameController.text.trim(),
        hapticEnabled: _hapticEnabled,
        soundNotificationsEnabled: _soundNotificationsEnabled,
      );

      await StorageService.saveUserProfile(updatedProfile);
      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageService.isSpanish
                  ? 'Perfil actualizado exitosamente'
                  : 'Profile updated successfully',
            ),
          ),
        );
      }
    }
  }

  void _openNotificationSettings() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationPermission),
        content: Text(l10n.openDeviceSettings),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _openAudioSettings() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.audioSettings),
        content: Text(l10n.manageAudio),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.confirmClearData,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Text(l10n.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            child: Text(
              l10n.deleteEverything,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllData() async {
    // Cancel all scheduled alarms first
    await AlarmService.rescheduleAllAlarms();

    // Clear all stored data
    await StorageService.clearAll();

    if (mounted) {
      // Navigate back and show confirmation
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageService.isSpanish
                ? 'Todos los datos eliminados exitosamente'
                : 'All data cleared successfully',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _walletChangeFailsafeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }
}

class _EditUsernameSheetContent extends StatefulWidget {
  const _EditUsernameSheetContent({
    required this.theme,
    required this.initialName,
    required this.onSave,
  });

  final ThemeData theme;
  final String initialName;
  final ValueChanged<String> onSave;

  @override
  State<_EditUsernameSheetContent> createState() =>
      _EditUsernameSheetContentState();
}

class _EditUsernameSheetContentState extends State<_EditUsernameSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    widget.onSave(trimmed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Update Username',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your username will be visible to other SolRise users in the ecosystem.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'NEW USERNAME',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withOpacity(0.4),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Text(
                '@',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: _controller,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'sol_traveler',
                    hintStyle: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.25),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.cancel,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                ),
                onPressed: _controller.text.trim().isEmpty ? null : _handleSave,
                label: Text(
                  'Save Changes',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
