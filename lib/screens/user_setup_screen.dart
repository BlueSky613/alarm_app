import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/screens/legal_page.dart';
import 'package:solana/solana.dart';
import 'package:solana/dto.dart';
import 'package:solana_wallet_adapter/solana_wallet_adapter.dart';

import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawn_weaver/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dawn_weaver/utils/api_base_url.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

/// Primary green from login.html (SolRise Onboarding).
const Color _kPrimary = Color(0xFF0EF196);

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  ZodiacSign _selectedZodiacSign = ZodiacSign.taurus;
  String _selectedLanguage = 'en';
  late SolanaClient _solanaClient;
  String _cluster = 'mainnet-beta';
  SolanaWalletAdapter? _adapter;
  String? _walletAddress;
  double? _walletBalance;
  bool _isConnectingWallet = false;
  bool _isSubmittingProfile = false;
  bool _agreedToTerms = false;

  final Map<ZodiacSign, String> _zodiacNames = {
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

  final Map<ZodiacSign, String> _zodiacDates = {
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

  /// Short unique description per sign (English).
  final Map<ZodiacSign, String> _zodiacShortDescEn = {
    ZodiacSign.aries:
        'Bold, energetic pioneer. Fire drives your path and your courage to lead. Your alignment strengthens initiative and confidence within SolRise.',
    ZodiacSign.taurus:
        'Steady, grounded builder. Earth anchors your abundance and your love for beauty. This alignment supports stability and lasting growth in the ecosystem.',
    ZodiacSign.gemini:
        'Curious, communicative twin. Air fuels your wit and your need to connect. Your alignment enhances learning and exchange within SolRise.',
    ZodiacSign.cancer:
        'Intuitive, nurturing soul. The Moon guides your heart and your care for others. This alignment deepens emotional wisdom and inner security.',
    ZodiacSign.leo:
        'Confident, creative leader. The Sun crowns your presence and your generosity. Your alignment amplifies self-expression and radiant impact.',
    ZodiacSign.virgo:
        'Precise, devoted perfectionist. Earth refines your craft and your service. This alignment sharpens discernment and practical mastery.',
    ZodiacSign.libra:
        'Balanced, diplomatic harmonizer. Air seeks beauty and peace in all things. Your alignment fosters partnership and fair exchange.',
    ZodiacSign.scorpio:
        'Deep, transformative intensity. Water reveals hidden truth and renews from within. This alignment empowers regeneration and depth in SolRise.',
    ZodiacSign.sagittarius:
        'Free, philosophical explorer. Fire chases the horizon and higher meaning. Your alignment expands vision and adventurous growth.',
    ZodiacSign.capricorn:
        'Ambitious, disciplined achiever. Earth climbs the mountain with patience. This alignment rewards long-term focus and responsible success.',
    ZodiacSign.aquarius:
        'Innovative, humanitarian visionary. Air breaks the mold for the collective. Your alignment supports originality and community progress.',
    ZodiacSign.pisces:
        'Dreamy, empathetic mystic. Water flows between worlds and hearts. This alignment deepens intuition and creative flow within SolRise.',
  };

  /// Short unique description per sign (Spanish).
  final Map<ZodiacSign, String> _zodiacShortDescEs = {
    ZodiacSign.aries:
        'Pionero audaz y enérgico. El fuego marca tu camino y tu valor para liderar. Tu alineación fortalece la iniciativa y la confianza en SolRise.',
    ZodiacSign.taurus:
        'Constructor estable y arraigado. La tierra ancla tu abundancia y tu amor por lo bello. Esta alineación favorece la estabilidad y el crecimiento duradero.',
    ZodiacSign.gemini:
        'Gemelo curioso y comunicativo. El aire alimenta tu ingenio y tu necesidad de conectar. Tu alineación mejora el aprendizaje y el intercambio.',
    ZodiacSign.cancer:
        'Alma intuitiva y nutricia. La Luna guía tu corazón y tu cuidado por los demás. Esta alineación profundiza la sabiduría emocional y la seguridad interior.',
    ZodiacSign.leo:
        'Líder seguro y creativo. El Sol corona tu presencia y tu generosidad. Tu alineación amplifica la expresión y el impacto radiante.',
    ZodiacSign.virgo:
        'Perfeccionista preciso y dedicado. La tierra refina tu arte y tu servicio. Esta alineación afina el discernimiento y el dominio práctico.',
    ZodiacSign.libra:
        'Armonizador equilibrado y diplomático. Busca belleza y paz en todo. Tu alineación fomenta la colaboración y el intercambio justo.',
    ZodiacSign.scorpio:
        'Intensidad profunda y transformadora. El agua revela la verdad oculta y renueva desde dentro. Esta alineación potencia la regeneración y la profundidad.',
    ZodiacSign.sagittarius:
        'Explorador libre y filosófico. El fuego persigue el horizonte y un sentido superior. Tu alineación amplía la visión y el crecimiento aventurero.',
    ZodiacSign.capricorn:
        'Logrador ambicioso y disciplinado. La tierra escala la cumbre con paciencia. Esta alineación premia el enfoque a largo plazo y el éxito responsable.',
    ZodiacSign.aquarius:
        'Visionario innovador y humanitario. El aire rompe moldes por el bien colectivo. Tu alineación apoya la originalidad y el progreso comunitario.',
    ZodiacSign.pisces:
        'Místico soñador y empático. El agua fluye entre mundos y corazones. Esta alineación profundiza la intuición y el flujo creativo en SolRise.',
  };

  /// Icons that reflect each zodiac sign's symbol and element.
  static const Map<ZodiacSign, IconData> _zodiacIcons = {
    ZodiacSign.aries: Icons.local_fire_department, // ♈ Ram, fire sign
    ZodiacSign.taurus: Icons.terrain, // ♉ Bull, earth sign
    ZodiacSign.gemini: Icons.people, // ♊ Twins, duality
    ZodiacSign.cancer: Icons.nightlight_round, // ♋ Crab, moon-ruled
    ZodiacSign.leo: Icons.wb_sunny, // ♌ Lion, sun-ruled
    ZodiacSign.virgo: Icons.eco, // ♍ Maiden, earth/nature
    ZodiacSign.libra: Icons.balance, // ♎ Scales
    ZodiacSign.scorpio: Icons.water_drop, // ♏ Scorpion, water sign
    ZodiacSign.sagittarius: Icons.travel_explore, // ♐ Archer, journey
    ZodiacSign.capricorn: Icons.landscape, // ♑ Sea goat, mountain
    ZodiacSign.aquarius: Icons.waves, // ♒ Water bearer
    ZodiacSign.pisces: Icons.opacity, // ♓ Two fish, fluid/water
  };

  /// Converts base64-encoded wallet address from adapter to base58 (for RPC/display).
  String? _base64AddressToBase58(String? base64Address) {
    if (base64Address == null || base64Address.isEmpty) return null;
    try {
      final bytes = base64.decode(base64Address);
      return Ed25519HDPublicKey(bytes).toBase58();
    } catch (_) {
      return null;
    }
  }

  Cluster get _walletCluster {
    switch (_cluster) {
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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _setupSolanaClient();
    SolanaWalletAdapter.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _adapter = SolanaWalletAdapter(
          AppIdentity(
            name: 'SolRise',
            uri: Uri.parse('https://solrise.cloud')
          ),
          cluster: _walletCluster,
        );
      });
      // _restoreWalletFromAdapter();
    });
  }

  void _restoreWalletFromAdapter() async {
    final adapter = _adapter;
    if (adapter == null || !adapter.isAuthorized) return;
    final accounts = adapter.authorizeResult?.accounts ?? const [];
    final account =
        adapter.connectedAccount ??
        (accounts.isNotEmpty ? accounts.first : null);
    if (account == null) return;
    final address = _base64AddressToBase58(account.address) ?? account.address;

    print('Adapter Address: $address');

    const skrMint = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';

    try {
      // 1. Fetch all token accounts owned by this address for the SKR mint
      final result = await _solanaClient.rpcClient.getTokenAccountsByOwner(
        address,
        const TokenAccountsFilter.byMint(skrMint),
        encoding: Encoding.jsonParsed,
      );

      double totalBalance = 0.0;

      if (result.value.isNotEmpty) {
        for (var account in result.value) {
          final data = account.account.data;
          if (data is ParsedAccountData) {
            // Navigate the parsed JSON structure to find the uiAmount
            final info = data.toJson()['parsed']['info'];
            final tokenAmount = info['tokenAmount'];
            totalBalance += double.parse(tokenAmount['uiAmountString']);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _walletAddress = address;
        _walletBalance = totalBalance;
      });

      print('SKR Balance: $totalBalance');
    } catch (e) {
      print('Error fetching SKR balance: $e');
    }

    // _solanaClient.rpcClient
    //     .getBalance(address)
    //     .then((res) {
    //       if (!mounted) return;
    //       setState(() {
    //         _walletAddress = address;
    //         _walletBalance = res.value / 1000000000.0;
    //       });
    //     })
    //     .catchError((_) {
    //       if (mounted) {
    //         setState(() {
    //           _walletAddress = address;
    //           _walletBalance = null;
    //         });
    //       }
    //     });
  }

  void _setupSolanaClient() {
    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse(
        _cluster == 'mainnet-beta'
            ? 'https://api.mainnet-beta.solana.com'
            : 'https://api.testnet.solana.com',
      ),
      websocketUrl: Uri.parse(
        _cluster == 'mainnet-beta'
            ? 'wss://api.mainnet-beta.solana.com'
            : 'wss://api.testnet.solana.com',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroHeight = size.height * 0.35;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Bottom gradient (login.html: from-primary/5 to-transparent, h-64)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 256,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_kPrimary.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(heroHeight),
                        // Content: -mt-8 (overlap), px-6, gap-8, pb-32
                        Transform.translate(
                          offset: const Offset(0, -48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWalletSection(),
                                const SizedBox(height: 32),
                                _buildCosmicAlignmentSection(),
                                const SizedBox(height: 32),
                                _buildZodiacDetailCardWithIdentity(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(double heroHeight) {
    final theme = Theme.of(context);
    final isSpanish = _selectedLanguage == 'es';
    final width = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Overlay: from-primary/10 to-transparent opacity-40
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kPrimary.withOpacity(0.1 * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Cosmic blob: top-left -10%, 120% size, opacity 0.3, blur, gradient primary->transparent->purple-900
          Positioned(
            left: -0.1 * width,
            top: -0.1 * heroHeight,
            width: 1.2 * width,
            height: 1.2 * heroHeight,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(9999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _kPrimary.withOpacity(0.3),
                      Colors.transparent,
                      const Color(0xFF581C87).withOpacity(0.25),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Content: logo + title + subtitle
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: _kPrimary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/solrise_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'BIENVENIDO, BUSCADOR' : 'WELCOME, SEEKER',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSpanish ? 'INICIALIZANDO SOLRISE' : 'INITIALIZING SOLRISE ALARM',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 4,
                    color: _kPrimary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    final theme = Theme.of(context);
    final isSpanish = _selectedLanguage == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSpanish ? 'IDENTIDAD UNIVERSAL' : 'UNIVERSAL IDENTITY',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 3,
            color: _kPrimary.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: isSpanish
                ? 'Usuario o ID de buscador'
                : 'Username or Seeker ID',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(
              Icons.alternate_email,
              color: _kPrimary.withOpacity(0.5),
              size: 22,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _kPrimary.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicAlignmentSection() {
    final theme = Theme.of(context);
    final isSpanish = _selectedLanguage == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            isSpanish ? 'ALINEACIÓN CÓSMICA' : 'COSMIC ALIGNMENT',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 4,
              color: _kPrimary.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ZodiacSign.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final sign = ZodiacSign.values[index];
              final isSelected = _selectedZodiacSign == sign;
              final icon = _zodiacIcons[sign] ?? Icons.star;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedZodiacSign = sign;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? _kPrimary.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        border: Border.all(
                          color: isSelected
                              ? _kPrimary.withOpacity(0.6)
                              : _kPrimary.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 24,
                          color: isSelected
                              ? _kPrimary
                              : _kPrimary.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _zodiacNames[sign]!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isSelected
                            ? _kPrimary
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZodiacDetailCardWithIdentity() {
    final theme = Theme.of(context);
    final isSpanish = _selectedLanguage == 'es';
    final signName = _zodiacNames[_selectedZodiacSign] ?? '';
    final hasUniversalIdentity = _nameController.text.trim().isNotEmpty;
    final isWalletConnected = _walletAddress != null;
    final canConfirm = hasUniversalIdentity && isWalletConnected && _agreedToTerms;
    final dateRange = _zodiacDates[_selectedZodiacSign];
    final shortDesc = isSpanish
        ? (_zodiacShortDescEs[_selectedZodiacSign] ?? '')
        : (_zodiacShortDescEn[_selectedZodiacSign] ?? '');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: _kPrimary.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    signName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (dateRange != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      dateRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                shortDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              // Gradient divider like login.html
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      _kPrimary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildNameInput(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: _kPrimary,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: isSpanish ? 'Acepto la ' : 'I agree to the ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LegalPage(
                                      title: 'Privacy Policy',
                                      type: LegalPageType.privacy,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isSpanish ? 'Política de Privacidad' : 'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _kPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: isSpanish ? ' y los ' : ' and ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LegalPage(
                                      title: 'Terms of Service',
                                      type: LegalPageType.license,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isSpanish ? 'Términos de Servicio' : 'Terms of Service',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _kPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: (canConfirm && !_isSubmittingProfile)
                      ? _saveProfile
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: canConfirm
                        ? _kPrimary
                        : _kPrimary.withOpacity(0.1),
                    foregroundColor: canConfirm ? Colors.white : _kPrimary,
                    side: BorderSide(color: _kPrimary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmittingProfile
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isSpanish
                              ? 'CONFIRMAR ALINEACIÓN'
                              : 'CONFIRM ALIGNMENT',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: canConfirm ? Colors.white : _kPrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shield with heart icon matching reference HTML (material-symbols: shield_with_heart).
  Widget _shieldWithHeartIcon({required double size, required Color color}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_outlined, size: size, color: color),
          Icon(Icons.favorite, size: size * 0.42, color: color),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    final isConnected = _walletAddress != null;
    final theme = Theme.of(context);
    final isSpanish = _selectedLanguage == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              if (_walletAddress != null) {
                await _showWalletConnectModal();
              } else {
                await _handleConnectWallet();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _shieldWithHeartIcon(size: 26, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  isConnected
                      ? (isSpanish ? 'Billetera conectada' : 'Wallet Connected')
                      : (isSpanish
                            ? 'Conectar Billetera Seeker'
                            : 'Connect Seeker Wallet'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              isSpanish ? 'IMPULSADO POR SEED VAULT' : 'POWERED BY SEED VAULT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // if (isConnected) ...[
        //   const SizedBox(height: 10),
        //   SelectableText(
        //     _walletAddress!,
        //     textAlign: TextAlign.center,
        //     style: theme.textTheme.bodySmall?.copyWith(color: _kPrimary),
        //   ),
        //   if (_walletBalance != null) ...[
        //     const SizedBox(height: 4),
        //     Text(
        //       _selectedLanguage == 'es'
        //           ? 'Balance: ${_walletBalance!} SKR'
        //           : 'Balance: ${_walletBalance!} SKR',
        //       style: theme.textTheme.bodySmall?.copyWith(
        //         color: Colors.white.withOpacity(0.8),
        //       ),
        //     ),
        //   ],
        // ],
      ],
    );
  }

  Future<void> _showWalletConnectModal() async {
    final isConnected = _walletAddress != null;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _selectedLanguage == 'es'
                    ? 'Selecciona tu billetera'
                    : 'Select your wallet',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage == 'es'
                    ? 'Al continuar se abrirá tu app de billetera compatible con Solana para autorizar la conexión.'
                    : 'When you continue, your installed Solana wallet app will open so you can approve the connection.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_adapter == null || _isConnectingWallet)
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await _handleConnectWallet();
                            },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(
                        isConnected
                            ? (_selectedLanguage == 'es'
                                  ? 'Cambiar billetera'
                                  : 'Change wallet')
                            : (_selectedLanguage == 'es'
                                  ? 'Conectar billetera'
                                  : 'Connect wallet'),
                      ),
                    ),
                  ),
                ],
              ),
              if (_walletAddress != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _handleDisconnectWallet();
                  },
                  child: Text(
                    _selectedLanguage == 'es'
                        ? 'Desconectar billetera'
                        : 'Disconnect wallet',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleConnectWallet() async {
    final adapter = _adapter;
    if (adapter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'es'
                  ? 'Espera a que la billetera esté lista.'
                  : 'Please wait for wallet to initialize.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isConnectingWallet = true);

    const skrMint = 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3';

    try {
      // If not yet authorized, show wallet selection modal via authorize()
      if (!adapter.isAuthorized) {
        final result = await adapter.authorize();

        print('Authorize Result: $result');

        final account = result.accounts.isNotEmpty
            ? result.accounts.first
            : null;
        if (account == null || !mounted) {
          setState(() => _isConnectingWallet = false);
          return;
        }
      }

      final accounts = adapter.authorizeResult?.accounts ?? const [];
      final account =
          adapter.connectedAccount ??
          (accounts.isNotEmpty ? accounts.first : null);
      if (account == null) {
        if (mounted) setState(() => _isConnectingWallet = false);
        return;
      }
      final address =
          _base64AddressToBase58(account.address) ?? account.address;

      // Fetch all token accounts owned by this address for the SKR mint
      final skrResult = await _solanaClient.rpcClient.getTokenAccountsByOwner(
        address,
        const TokenAccountsFilter.byMint(skrMint),
        encoding: Encoding.jsonParsed,
      );

      double totalBalance = 0.0;

      if (skrResult.value.isNotEmpty) {
        for (var acc in skrResult.value) {
          final data = acc.account.data;
          if (data is ParsedAccountData) {
            final info = data.toJson()['parsed']['info'];
            final tokenAmount = info['tokenAmount'];
            totalBalance += double.parse(tokenAmount['uiAmountString']);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _walletAddress = address;
        _walletBalance = totalBalance;
        _isConnectingWallet = false;
      });

      print('Wallet Address: $address');
      print('SKR Balance: $totalBalance');
    } catch (e) {
      print('Error connecting wallet / fetching SKR balance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'es'
                  ? 'Error al conectar la billetera: $e'
                  : 'Failed to connect wallet: $e',
            ),
          ),
        );
        setState(() => _isConnectingWallet = false);
      }
    } finally {
      if (mounted && _isConnectingWallet) {
        setState(() => _isConnectingWallet = false);
      }
    }
  }

  Future<void> _handleDisconnectWallet() async {
    if (_walletAddress == null) return;

    try {
      await _adapter?.deauthorize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'es'
                  ? 'No se pudo desconectar la billetera: $e'
                  : 'Failed to disconnect wallet: $e',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _walletAddress = null;
      _walletBalance = null;
    });
  }

  Future<void> _saveProfile() async {
    final trimmedName = _nameController.text.trim();
    final wallet = _walletAddress;
    if (wallet == null || trimmedName.isEmpty) return;

    final baseUrl = resolveApiBaseUrl(dotenv.env['base_url']);
    final isSpanish = _selectedLanguage == 'es';
    if (baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpanish
                ? 'Configura base_url para completar el registro.'
                : 'Set base_url to complete registration.',
          ),
        ),
      );
      return;
    }

    String authToken = '';
    bool isPremiumFromServer = false;
    setState(() => _isSubmittingProfile = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/wallet-users'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': trimmedName,
          'wallet_address': wallet,
          'cluster': _cluster,
          'premium': false,
        }),
      );

      if (response.statusCode == 422) {
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (_) {}
        final msg =
            body?['message'] as String? ??
            (isSpanish
                ? 'Este nombre de usuario ya está en uso.'
                : 'This username is already taken.');
        if (mounted) {
          setState(() => _isSubmittingProfile = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (mounted) {
          setState(() => _isSubmittingProfile = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSpanish
                    ? 'No se pudo registrar (${response.statusCode}).'
                    : 'Registration failed (${response.statusCode}).',
              ),
            ),
          );
        }
        return;
      }
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      authToken = (body?['token'] as String?) ?? '';
      final userMap = body?['user'] as Map<String, dynamic>?;
      isPremiumFromServer =
          (userMap?['premium'] as bool?) ?? false;
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() => _isSubmittingProfile = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSpanish
                    ? 'Token inválido recibido del servidor.'
                    : 'Invalid token received from server.',
              ),
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? 'Sin conexión con el servidor. Comprueba la URL en .env y que el panel esté en marcha.'
                  : 'Could not reach server. Check base_url in .env and that the admin panel is running.',
            ),
          ),
        );
      }
      return;
    }
    if (mounted) {
      setState(() => _isSubmittingProfile = false);
    }

    final profile = UserProfile(
      name: trimmedName,
      zodiacSign: _selectedZodiacSign,
      language: _selectedLanguage,
      firstTimeSetup: false,
      horoscope: "",
      weather: "",
      solanaAddress: wallet,
      solanaBalance: _walletBalance,
      isPremium: isPremiumFromServer,
    );

    await StorageService.saveUserProfile(profile);
    await StorageService.saveAuthToken(authToken);
    await StorageService.setFirstRun(false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);

    await languageService.changeLanguage(_selectedLanguage);

    if (mounted) {
      setState(() => _isSubmittingProfile = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
