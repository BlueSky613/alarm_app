import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dawn_weaver/screens/alarms_list_screen.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/screens/settings_screen.dart';
import 'package:dawn_weaver/services/premium_payment_service.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/wallet_api_service.dart';
import 'package:dawn_weaver/services/wallet_balance_service.dart';
import 'package:flutter/material.dart';
import 'package:solana/dto.dart' show Encoding;
import 'package:solana/solana.dart';
import 'package:solana_common/models.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';

const Color _kPrimary = Color(0xFF0EF196);
const Color _kSolanaPurple = Color(0xFF9945FF);
const Color _kGold = Color(0xFFFFD700);
const Color _kBackgroundDark = Color(0xFF000000);

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _upgrading = false;
  bool _isPremium = false;

  late SolanaClient _solanaClient;
  SolanaWalletAdapter? _walletAdapter;

  @override
  void initState() {
    super.initState();
    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse('https://api.mainnet-beta.solana.com'),
      websocketUrl: Uri.parse('wss://api.mainnet-beta.solana.com'),
    );
    _loadPremiumFlag();
    SolanaWalletAdapter.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _walletAdapter = SolanaWalletAdapter(
          AppIdentity(
            name: 'SolRise',
            uri: Uri.parse('https://solrise.cloud')
          ),
          cluster: Cluster.mainnet,
        );
      });
    });
  }

  Future<void> _loadPremiumFlag() async {
    final p = await StorageService.getUserProfile();
    if (!mounted) return;
    setState(() => _isPremium = p?.isPremium ?? false);
  }

  String? _base64AddressToBase58(String base64Address) {
    try {
      final bytes = base64.decode(base64Address);
      return Ed25519HDPublicKey(bytes).toBase58();
    } catch (_) {
      return null;
    }
  }

  /// Read the already-connected wallet from the adapter (no extra prompt).
  String? _connectedWalletBase58(SolanaWalletAdapter adapter) {
    final accounts = adapter.authorizeResult?.accounts ?? const [];
    final account =
        adapter.connectedAccount ??
        (accounts.isNotEmpty ? accounts.first : null);
    if (account == null) return null;
    return _base64AddressToBase58(account.address) ?? account.address;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onUpgradeToPro() async {
    if (PremiumPaymentService.clientTreasuryAddress() == null) {
      _snack(
        'Premium treasury not configured (client_wallet_address in .env).',
      );
      return;
    }

    final profile = await StorageService.getUserProfile();
    final wallet = profile?.solanaAddress?.trim();
    if (wallet == null || wallet.isEmpty) {
      _snack('Connect a wallet in Settings first.');
      return;
    }

    final adapter = _walletAdapter;
    if (adapter == null) {
      _snack('Wallet adapter not ready. Try again in a moment.');
      return;
    }

    setState(() => _upgrading = true);

    try {
      // Check wallet balances before proceeding.
      final balances = await WalletBalanceService.fetchSkrAndSol(wallet);
      if (balances.skr < premiumPriceSkr || balances.sol < 0.0001) {
        if (mounted) {
          setState(() => _upgrading = false);
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              title: const Text(
                'Insufficient Balance',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (balances.skr < premiumPriceSkr)
                    Text(
                      'SKR: ${balances.skr.toStringAsFixed(2)} (need $premiumPriceSkr)',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  if (balances.sol < 0.0001)
                    Text(
                      'SOL: ${balances.sol.toStringAsFixed(6)} (need ≥ 0.0001)',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Please top up your wallet before upgrading.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: _kPrimary)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Build the tx first — we already have the sender address from the profile.
      final unsigned = await PremiumPaymentService.buildPremiumSkrPaymentTx(
        client: _solanaClient,
        senderWalletBase58: wallet,
      );

      final wrapped = UnsignedPremiumPaymentTx(unsigned);
      final payload = adapter.encodeTransaction(
        wrapped,
        config: const TransactionSerializableConfig(
          requireAllSignatures: false,
          verifySignatures: false,
        ),
      );

      // signTransactions internally reauthorizes using the stored token in the
      // same MWA session before requesting the signature — one session, one modal.
      // If the stored token is stale, Phantom silently drops that session.
      // We catch that, refresh the token with a fresh authorize, then retry once.
      SignTransactionsResult signResult;
      try {
        signResult = await adapter.signTransactions([payload]).timeout(
          const Duration(seconds: 120),
        );
      } on SolanaWalletAdapterException catch (e) {
        debugPrint('[Premium] signTransactions failed (${e.code}): ${e.message}');
        // Stale/invalid token — get a fresh one then retry.
        await adapter.reauthorizeOrAuthorize().timeout(
          const Duration(seconds: 90),
        );
        signResult = await adapter.signTransactions([payload]).timeout(
          const Duration(seconds: 120),
        );
      }

      final connected = _connectedWalletBase58(adapter);
      if (connected == null) {
        throw Exception('No connected wallet account.');
      }
      if (connected != wallet) {
        _snack(
          'Active wallet does not match your profile. Update it in Settings.',
        );
        return;
      }
      if (signResult.signedPayloads.isEmpty) {
        throw Exception('No signed transaction returned.');
      }
      // Submit the wallet-signed transaction to the RPC ourselves.
      await _solanaClient.rpcClient.sendTransaction(
        signResult.signedPayloads.first,
        encoding: Encoding.base64,
      );

      // Sync premium flag with backend.
      final ok = await syncWalletPremium(walletAddress: wallet, premium: true);
      if (!ok) {
        _snack(
          'Payment sent but server could not confirm. Check base_url / Laravel.',
        );
        return;
      }

      await StorageService.saveUserProfile(profile!.copyWith(isPremium: true));
      if (!mounted) return;
      setState(() => _isPremium = true);
      _snack('Welcome to Pro — premium unlocked.');
    } on TimeoutException {
      _snack('Timed out waiting for wallet response.');
    } on SolanaWalletAdapterException catch (e) {
      // This tells us exactly where the MWA flow is failing.
      debugPrint('[Premium] SolanaWalletAdapterException code=${e.code} msg=${e.message}');
      _snack('Wallet error [${e.code}]: ${e.message}');
    } on PremiumPaymentException catch (e) {
      _snack(e.message);
    } catch (e, st) {
      debugPrint('[Premium] Unexpected error: $e\n$st');
      _snack('Upgrade failed: $e');
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 100 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildPlanCards(context),
                const SizedBox(height: 48),
                _buildWhyPremium(context),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_kPrimary, _kSolanaPurple, _kGold],
            ).createShader(bounds),
            child: const Text(
              'Choose Your Path',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBasicCard(context),
        const SizedBox(height: 24),
        _buildPremiumCard(context),
      ],
    );
  }

  Widget _buildBasicCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BASIC',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF9945FF),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'Free',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Forever',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _featureRow(
                Icons.check_circle_rounded,
                _kPrimary,
                '5 AI Characters',
              ),
              const SizedBox(height: 12),
              _featureRow(
                Icons.check_circle_rounded,
                _kPrimary,
                '20 Alarm Musics',
              ),
              const SizedBox(height: 12),
              _featureRow(
                Icons.check_circle_rounded,
                _kPrimary,
                'Daily Horoscope',
              ),
              const SizedBox(height: 12),
              _featureRow(
                Icons.check_circle_rounded,
                _kPrimary,
                'Weather Updates',
              ),
              if (!_isPremium) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      foregroundColor: Colors.white.withValues(alpha: 0.8),
                    ),
                    child: const Text('Current Plan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _kSolanaPurple.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kSolanaPurple.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'PREMIUM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF9945FF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$premiumPriceSkr SKR',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _featureRow(
                    Icons.star_rounded,
                    _kSolanaPurple,
                    'All AI Characters',
                  ),
                  const SizedBox(height: 12),
                  _featureRow(
                    Icons.star_rounded,
                    _kSolanaPurple,
                    'All Alarm Musics',
                  ),
                  const SizedBox(height: 12),
                  _featureRow(
                    Icons.star_rounded,
                    _kSolanaPurple,
                    'Daily Horoscope',
                  ),
                  const SizedBox(height: 12),
                  _featureRow(
                    Icons.star_rounded,
                    _kSolanaPurple,
                    'Weather Updates',
                  ),
                  const SizedBox(height: 12),
                  _featureRow(
                    Icons.star_rounded,
                    _kSolanaPurple,
                    'Priority Support',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _isPremium
                        ? OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: _kPrimary.withValues(alpha: 0.6),
                              ),
                              foregroundColor: _kPrimary,
                            ),
                            child: const Text(
                              "You're Pro",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _upgrading ? null : _onUpgradeToPro,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _upgrading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Upgrade to Pro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kSolanaPurple, _kGold],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhyPremium(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kSolanaPurple.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why Go Premium?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock the full potential of SolRise with exclusive AI personalities, custom Solana-themed soundscapes, and advanced blockchain analytics.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
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
          _navButton(
            context,
            icon: Icons.home_outlined,
            label: 'HOME',
            isSelected: false,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          ),
          _navButton(
            context,
            icon: Icons.alarm_outlined,
            label: 'MY ALARMS',
            isSelected: false,
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AlarmsListScreen()),
            ),
          ),
          _navButton(
            context,
            icon: Icons.diamond_outlined,
            label: 'PREMIUM',
            isSelected: true,
            onTap: () {},
          ),
          _navButton(
            context,
            icon: Icons.settings_outlined,
            label: 'SETTINGS',
            isSelected: false,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final displayLabel = label == 'PREMIUM' ? 'PREMIUM' : label;
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
              displayLabel,
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
}
