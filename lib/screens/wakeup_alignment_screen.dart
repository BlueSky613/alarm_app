import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/services/wake_flow_completion.dart';
import 'package:dawn_weaver/services/wallet_balance_service.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';

/// Post-wake “daily alignment” view — layout and style aligned with
/// `success_bridge_nav_match/code.html` (OLED black, #0ef196, glass, Space Grotesk).
const Color _kPrimary = Color(0xFF0EF196);
const Color _kBgDark = Color(0xFF000000);
final Color _kGlassFill = Color.fromRGBO(16, 34, 27, 0.4);

class WakeupAlignmentScreen extends StatefulWidget {
  const WakeupAlignmentScreen({
    super.key,
    required this.alarm,
    required this.profile,
  });

  final Alarms alarm;
  final UserProfile? profile;

  @override
  State<WakeupAlignmentScreen> createState() => _WakeupAlignmentScreenState();
}

class _WakeupAlignmentScreenState extends State<WakeupAlignmentScreen> {
  Future<({double skr, double sol})?>? _walletFuture;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.profile?.solanaAddress?.trim() ?? '';
    if (addr.isNotEmpty) {
      _walletFuture = WalletBalanceService.fetchSkrAndSol(addr);
    }
  }

  Future<void> _leaveAlignment() async {
    if (_leaving) return;
    _leaving = true;
    await applyWakeExitSideEffects(widget.alarm, isPreview: false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.isSpanish;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _leaveAlignment();
      },
      child: Scaffold(
      backgroundColor: _kBgDark,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            decoration: BoxDecoration(
              color: _kBgDark,
              border: Border.symmetric(
                vertical: BorderSide.none,
                horizontal: BorderSide(color: _kPrimary.withValues(alpha: 0.1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHero(isSpanish)),
                    SliverToBoxAdapter(
                      child: _buildWalletCard(l10n, isSpanish),
                    ),
                    if (widget.alarm.hasHoroscope || widget.alarm.hasWeather)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _sectionTitle(l10n.dailyAlignment),
                            const SizedBox(height: 16),
                            if (widget.alarm.hasHoroscope)
                              _horoscopeCard(l10n, isSpanish),
                            if (widget.alarm.hasHoroscope &&
                                widget.alarm.hasWeather)
                              const SizedBox(height: 16),
                            if (widget.alarm.hasWeather)
                              _weatherCard(l10n, isSpanish),
                          ]),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomCta(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHero(bool isSpanish) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.35),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded, size: 52, color: _kBgDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isSpanish ? 'SECUENCIA DE DESPERTAR' : 'WAKE SEQUENCE COMPLETE',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: _kPrimary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(AppLocalizations l10n, bool isSpanish) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: _glassPanel(
        borderOpacity: 0.2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                isSpanish ? 'BALANCE DE BILLETERA' : 'WALLET BALANCE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _kPrimary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              _buildWalletBody(l10n, isSpanish),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBody(AppLocalizations l10n, bool isSpanish) {
    final addr = widget.profile?.solanaAddress?.trim() ?? '';
    if (addr.isEmpty) {
      return Text(
        isSpanish ? 'No hay billetera en el perfil.' : 'No wallet in profile.',
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      );
    }
    if (_walletFuture == null) return const SizedBox.shrink();

    return FutureBuilder<({double skr, double sol})?>(
      future: _walletFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
          );
        }
        final data = snapshot.data;
        final skr = data?.skr;
        final sol = data?.sol;

        return Column(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: skr != null ? skr.toStringAsFixed(2) : '—',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: ' SKR',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: _kPrimary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: sol != null ? sol.toStringAsFixed(6) : '—',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: ' SOL',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _horoscopeCard(AppLocalizations l10n, bool isSpanish) {
    final text =
        (widget.profile?.horoscope != null &&
            widget.profile!.horoscope.isNotEmpty)
        ? widget.profile!.horoscope
        : (isSpanish
              ? 'Sin datos de horóscopo en el perfil.'
              : 'No horoscope data in profile.');

    return _glassPanel(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.auto_awesome, size: 72, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: _kPrimary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isSpanish ? 'HORÓSCOPO DIARIO' : 'DAILY HOROSCOPE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherCard(AppLocalizations l10n, bool isSpanish) {
    final raw =
        (widget.profile?.weather != null && widget.profile!.weather.isNotEmpty)
        ? widget.profile!.weather
        : (isSpanish
              ? 'Sin datos del tiempo en el perfil.'
              : 'No weather data in profile.');

    return _glassPanel(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _kPrimary.withValues(alpha: 0.1),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.wb_sunny_rounded, color: _kPrimary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                raw,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isSpanish ? 'RESUMEN' : 'BRIEF',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: _kPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish ? 'Hoy' : 'Today',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPanel({required Widget child, double borderOpacity = 0.1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kGlassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _kPrimary.withValues(alpha: borderOpacity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomCta(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _kBgDark,
            _kBgDark.withValues(alpha: 0.92),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        28,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Material(
        color: _kPrimary,
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        shadowColor: _kPrimary.withValues(alpha: 0.35),
        child: InkWell(
          onTap: _leaveAlignment,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.35),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.returnToDashboard.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _kBgDark,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: _kBgDark, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slide-up + fade route (modal-like full screen).
Route<void> wakeupAlignmentRoute({
  required Alarms alarm,
  required UserProfile? profile,
}) {
  return PageRouteBuilder<void>(
    opaque: true,
    pageBuilder: (context, animation, secondaryAnimation) {
      return WakeupAlignmentScreen(alarm: alarm, profile: profile);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 380),
  );
}
