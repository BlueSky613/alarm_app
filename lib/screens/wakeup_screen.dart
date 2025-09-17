import 'package:alarm/alarm.dart';
import 'package:dawn_weaver/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:dawn_weaver/models/alarm.dart';
import 'package:dawn_weaver/models/user_profile.dart';
import 'package:dawn_weaver/services/storage_service.dart';
import 'package:dawn_weaver/services/content_service.dart';
import 'package:dawn_weaver/services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawn_weaver/services/alarm_service.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  bool _isPlaying = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _startWakeupSequence();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

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
      print(widget.alarm.virtualCharacter);

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
    // Play alarm sound
    // await AudioService.playAlarmSound(soundPath: widget.alarm.soundPath);
    setState(() {
      _isPlaying = true;
    });

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
      await AudioService.speakGreeting(
        audioString,
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
                    TimeOfDay.now().format(context),
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
                      label: 'Snooze ${widget.alarm.snoozeMinutes}m',
                      color: Colors.blueAccent.shade200,
                      icon: Icons.snooze,
                      onTap: _snoozeAlarm,
                    ),
                    const SizedBox(width: 16),
                    _buildNeonButton(
                      label: 'I\'m Awake!',
                      color: Colors.tealAccent.shade200,
                      icon: Icons.check,
                      onTap: _dismissAlarm,
                    ),
                  ],
                )
                // Row(
                //   children: [
                //     Expanded(
                //       child: ElevatedButton(
                //         onPressed: _snoozeAlarm,
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.orange,
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(vertical: 16),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //         ),
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             const Icon(Icons.snooze),
                //             const SizedBox(width: 8),
                //             Text('Snooze ${widget.alarm.snoozeMinutes}m'),
                //           ],
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 16),
                //     Expanded(
                //       child: ElevatedButton(
                //         onPressed: _dismissAlarm,
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.green,
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(vertical: 16),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //         ),
                //         child: const Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Icon(Icons.check),
                //             SizedBox(width: 8),
                //             Text('I\'m Awake!'),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ],
                // )
              ],
            ),
          )),
        ],
      ),
    );
    // return Scaffold(
    //   backgroundColor: Colors.black,
    //   body: Container(
    //     decoration: const BoxDecoration(
    //       gradient: LinearGradient(
    //         begin: Alignment.topCenter,
    //         end: Alignment.bottomCenter,
    //         colors: [
    //           Color(0xFF1a1a2e),
    //           Color(0xFF16213e),
    //           Color(0xFF0f3460),
    //         ],
    //       ),
    //     ),
    //     child: SafeArea(
    //       child: Column(
    //         children: [
    //           _buildHeader(),
    //           Expanded(
    //             child: _buildVirtualCharacterSection(),
    //           ),
    //           _buildControls(),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
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
                  fontSize: 16,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              TimeOfDay.now().format(context),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          if (widget.alarm.label.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.alarm.label,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVirtualCharacterSection() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.alarm.virtualCharacter != 'default'
                      ? Image.network(
                          widget.alarm.virtualCharacter,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCharacter();
                          },
                        )
                      : _buildDefaultCharacter(),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_userProfile != null) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Hello, ${_userProfile!.name}! 🌅',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ContentService.getRandomEncouragingWord(_userProfile!.language),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCharacter() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.wb_sunny,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  // Widget _buildContentSection() {
  //   if (_contentList.isEmpty) return const SizedBox();

  //   return Container(
  //     margin: const EdgeInsets.all(20),
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(
  //         color: Colors.white.withValues(alpha: 0.2),
  //       ),
  //     ),
  //     child: Column(
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             IconButton(
  //               onPressed: _currentContentIndex > 0 ? _previousContent : null,
  //               icon: Icon(
  //                 Icons.chevron_left,
  //                 color:
  //                     _currentContentIndex > 0 ? Colors.white : Colors.white38,
  //                 size: 28,
  //               ),
  //             ),
  //             Expanded(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     '${_currentContentIndex + 1} of ${_contentList.length}',
  //                     style: const TextStyle(
  //                       color: Colors.white70,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   _currentContentIndex == 2 && _contentList.length > 3
  //                       ? SizedBox(
  //                           height:
  //                               150, // Adjust as needed to fit inside the 160 container
  //                           child: SingleChildScrollView(
  //                             child: Text(
  //                               _currentContentIndex < _contentList.length
  //                                   ? _contentList[_currentContentIndex]
  //                                   : '',
  //                               textAlign: TextAlign.center,
  //                               style: const TextStyle(
  //                                 fontSize: 16,
  //                                 color: Colors.white,
  //                                 height: 1.4,
  //                               ),
  //                             ),
  //                           ),
  //                         )
  //                       : Text(
  //                           _currentContentIndex < _contentList.length
  //                               ? _contentList[_currentContentIndex]
  //                               : '',
  //                           textAlign: TextAlign.center,
  //                           style: const TextStyle(
  //                             fontSize: 16,
  //                             color: Colors.white,
  //                             height: 1.4,
  //                           ),
  //                         ),
  //                 ],
  //               ),
  //             ),
  //             IconButton(
  //               onPressed: _currentContentIndex < _contentList.length - 1
  //                   ? _nextContent
  //                   : null,
  //               icon: Icon(
  //                 Icons.chevron_right,
  //                 color: _currentContentIndex < _contentList.length - 1
  //                     ? Colors.white
  //                     : Colors.white38,
  //                 size: 28,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         LinearProgressIndicator(
  //           value: _contentList.isNotEmpty
  //               ? (_currentContentIndex + 1) / _contentList.length
  //               : 0,
  //           backgroundColor: Colors.white.withValues(alpha: 0.2),
  //           valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Sound controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isPlaying ? Icons.volume_off : Icons.volume_up,
                label: _isPlaying ? 'Mute' : 'Unmute',
                onTap: () async {
                  if (_isPlaying) {
                    await FlutterVolumeController.setMute(true);
                  } else {
                    await FlutterVolumeController.setMute(false);
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
              _buildControlButton(
                icon: Icons.replay,
                label: 'Repeat',
                onTap: _speakCurrentContent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Main action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _snoozeAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.snooze),
                      const SizedBox(width: 8),
                      Text('Snooze ${widget.alarm.snoozeMinutes}m'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _dismissAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check),
                      SizedBox(width: 8),
                      Text('I\'m Awake!'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
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
