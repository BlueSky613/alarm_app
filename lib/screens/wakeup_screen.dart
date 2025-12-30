import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/content_service.dart';
import 'package:dawn_weaver/services/audio_service.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';

class WakeupScreen extends StatefulWidget {
  final Alarms alarm;
  final int id;

  const WakeupScreen({super.key, required this.alarm, required this.id});

  @override
  State<WakeupScreen> createState() => _WakeupScreenState();
}

class _WakeupScreenState extends State<WakeupScreen>
    with TickerProviderStateMixin {
  UserProfile? _userProfile;
  String? _weatherData;
  String? _horoscope;
  String? _motivationMessage;
  String audioString = "";
  List<String> _contentList = [];
  int _currentContentIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late VideoPlayerController _controller;
  DateTime _currentTime = DateTime.now();
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _startTimeStream();
    _startWakeupSequence();
  }

  void _startTimeStream() {
    _timeStream =
        Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    _timeStream.listen((time) {
      if (mounted) {
        setState(() {
          _currentTime = time;
        });
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    _userProfile = await StorageService.getUserProfile();

    if (widget.alarm.virtualCharacter != 'default') {
      _controller = VideoPlayerController.networkUrl(Uri.parse(
          "${dotenv.env['base_url']}/storage/${widget.alarm.virtualCharacter}")) // or .network for online video
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
        });
    }

    if (widget.alarm.hasMotivation) {
      _motivationMessage = widget.alarm.motivationMessage;
    }

    if (widget.alarm.hasWeather) {
      _weatherData = _userProfile!.weather;
    }

    if (widget.alarm.hasHoroscope) {
      _horoscope = _userProfile!.horoscope;
    }

    if (_userProfile != null) {
      _contentList = ContentService.getWakeupContentList(
        profile: _userProfile!,
        includeHoroscope: widget.alarm.hasHoroscope,
        includeMotivation: widget.alarm.hasMotivation,
        includeWeather: widget.alarm.hasWeather,
        weatherData: _weatherData,
        horoscope: _horoscope,
        motivationMessage: _motivationMessage,
      );

      setState(() {});
    }
  }

  Future<void> _startWakeupSequence() async {
    // Wait a moment for the user to wake up
    await Future.delayed(const Duration(seconds: 3));

    // Start speaking content
    if (_contentList.isNotEmpty && _userProfile != null) {
      _speakCurrentContent();
    }
  }

  void _speakCurrentContent() async {
    if (_currentContentIndex < _contentList.length) {
      for (var i = 0; i < _contentList.length; i++) {
        audioString += _contentList[i];
      }
      _contentList.clear();
      var translation = await GoogleTranslator().translate(
        audioString,
        to: _userProfile?.language ?? 'en',
      );
      await AudioService.speakGreeting(
        translation.text,
        language: _userProfile?.language ?? 'en',
      );
    }
  }

  void _snoozeAlarm() async {
    // await AudioService.stopAlarmSound();
    await AlarmService.snoozeAlarm(widget.alarm.id, widget.alarm.snoozeMinutes);

    if (mounted) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Alarm snoozed for ${widget.alarm.snoozeMinutes} minutes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _dismissAlarm() async {
    // await AudioService.stopAlarmSound();
    await AudioService.stopSpeaking();
    await Alarm.stop(widget.id);

    final prefs = await SharedPreferences.getInstance();

    if (widget.alarm.label == "Quick Alarm" ||
        widget.alarm.label == "Power Nap") {
      await StorageService.deleteAlarm(widget.alarm.id);
      await AlarmService.cancelAlarm(widget.alarm.id);
    }

    prefs.setInt('alarmActive', 0);
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          if (widget.alarm.virtualCharacter != 'default' &&
              _controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
            ),
          // Main content
          SafeArea(
              child: Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                widget.alarm.label.isNotEmpty
                    ? Text(
                        widget.alarm.label,
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                    : Text(
                        'ALARM',
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    DateFormat('HH:mm').format(_currentTime),
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildNeonButton(
                      label: l10n.snoozedForMinutes(widget.alarm.snoozeMinutes),
                      color: Colors.blueAccent.shade200,
                      icon: Icons.snooze,
                      onTap: _snoozeAlarm,
                    ),
                    const SizedBox(width: 16),
                    _buildNeonButton(
                      label: l10n.awake,
                      color: Colors.tealAccent.shade200,
                      icon: Icons.check,
                      onTap: _dismissAlarm,
                    ),
                  ],
                )
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNeonButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.9), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: color.withOpacity(0.08),
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
              Text(
                label.toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    AudioService.stopSpeaking();
    super.dispose();
  }
}
