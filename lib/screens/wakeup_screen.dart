import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/wakeup_alignment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dawn_weaver/utils/virtual_character_video.dart';
import 'package:intl/intl.dart';

class WakeupScreen extends StatefulWidget {
  final Alarms alarm;
  final int id;
  final bool isPreview;

  /// When set, video is already initialized so the first frame shows immediately.
  final VideoPlayerController? preloadedVideoController;

  const WakeupScreen({
    super.key,
    required this.alarm,
    required this.id,
    this.isPreview = false,
    this.preloadedVideoController,
  });

  @override
  State<WakeupScreen> createState() => _WakeupScreenState();
}

class _WakeupScreenState extends State<WakeupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  VideoPlayerController? _videoController;
  DateTime _currentTime = DateTime.now();
  late Stream<DateTime> _timeStream;
  UserProfile? _profile;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    _loadProfile();
    if (widget.preloadedVideoController != null) {
      _videoController = widget.preloadedVideoController;
      if (mounted) setState(() {});
    } else {
      _loadCharacterVideo();
    }
    _startTimeStream();
  }

  Future<void> _loadProfile() async {
    _profile = await StorageService.getUserProfile();
    if (mounted) setState(() {});
  }

  void _startTimeStream() {
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
    _timeStream.listen((time) {
      if (mounted) {
        setState(() {
          _currentTime = time;
        });
      }
    });
  }

  Future<void> _loadCharacterVideo() async {
    if (widget.alarm.virtualCharacter == 'default') return;

    final videoUri = resolveVirtualCharacterVideoUri(
      widget.alarm.virtualCharacter,
    );
    _videoController = VideoPlayerController.networkUrl(videoUri)
      ..setLooping(true)
      ..setVolume(widget.alarm.muteVirtualCharacterAudio ? 0 : 1)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController?.play();
        }
      });
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.audioVolumeDown ||
         event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
         event.logicalKey == LogicalKeyboardKey.audioVolumeMute)) {
      if (!_muted) {
        _muted = true;
        AlarmService.clearWakeupScreenActive();
        Alarm.stop(widget.id);
        AlarmService.cancelAlarm(widget.alarm.id);
      }
      return true;
    }
    return false;
  }

  String _formatTimeAmPm(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.jm(locale).format(_currentTime);
  }

  Future<void> _snoozeAlarm() async {
    if (widget.isPreview) return;

    AlarmService.clearWakeupScreenActive();
    await Alarm.stop(widget.id);
    await AlarmService.cancelAlarm(widget.alarm.id);
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('alarmActive', 0);
    await AlarmService.snoozeAlarm(widget.alarm.id, widget.alarm.snoozeMinutes);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarm snoozed for ${widget.alarm.snoozeMinutes} minutes',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _onWakePressed() async {
    if (widget.isPreview) return;

    // Suppress stale ring events BEFORE stopping, so any queued
    // ringStream event that fires during the async gap is blocked.
    AlarmService.clearWakeupScreenActive();
    await Alarm.stop(widget.id);
    await AlarmService.cancelAlarm(widget.alarm.id);
    // Clear the alarmActive pref so a cold-start won't re-show this alarm.
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('alarmActive', 0);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WakeupAlignmentScreen(
          alarm: widget.alarm,
          profile: _profile,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          if (widget.alarm.virtualCharacter != 'default' &&
              (_videoController?.value.isInitialized ?? false))
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else if (widget.alarm.virtualCharacter != 'default')
            const ColoredBox(color: Colors.black)
          else
            Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                Opacity(
                  opacity: 0.8,
                  child: Image.asset(
                    'assets/solrise_logo.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.alarm.label.isNotEmpty
                        ? Text(
                            widget.alarm.label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          )
                        : Text(
                            'ALARM',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _formatTimeAmPm(context),
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNeonButton(
                        label: l10n.snoozedForMinutes(
                          widget.alarm.snoozeMinutes,
                        ),
                        color: Colors.blueAccent.shade200,
                        icon: Icons.snooze,
                        onTap: _snoozeAlarm,
                        interactive: !widget.isPreview,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNeonButton(
                        label: l10n.awake,
                        color: Colors.tealAccent.shade200,
                        icon: Icons.check,
                        onTap: _onWakePressed,
                        interactive: !widget.isPreview,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
    bool interactive = true,
  }) {
    Widget child = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!interactive) {
      child = IgnorePointer(
        ignoring: true,
        child: Opacity(opacity: 0.45, child: child),
      );
    }
    return child;
  }

  @override
  void dispose() {
    AlarmService.clearWakeupScreenActive();
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}
