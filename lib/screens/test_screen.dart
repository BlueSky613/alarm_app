import 'package:elevenlabs_flutter/elevenlabs_config.dart';
import 'package:elevenlabs_flutter/elevenlabs_types.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:elevenlabs_flutter/elevenlabs_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:just_audio/just_audio.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  final elevenLabs = ElevenLabsAPI();
  final AudioPlayer _elevenPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    generateSpeech();
    // _controller = VideoPlayerController.networkUrl(Uri.parse(
    //     '${dotenv.env['base_url']}/storage/virtual-images/8PdCcLhfG3paIQPSeXOhX2KLIzebYUvbet9nSfms.mp4')) // or .network for online video
    //   ..setLooping(true)
    //   ..setVolume(0)
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _controller.play();
    //   });

    // _controller = VideoPlayerController.asset(
    //     'assets/back1.mp4') // or .network for online video
    //   ..setLooping(true)
    //   ..setVolume(0)
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _controller.play();
    //   });
  }

  Future<void> generateSpeech() async {
    final elevenLabs = ElevenLabsAPI();
    await elevenLabs.init(
        config:
            ElevenLabsConfig(apiKey: dotenv.env['ELEVENLABS_API_KEY'] ?? ''));
    final voices = await elevenLabs.listVoices();
    if (voices.isNotEmpty) {
      final voiceId = voices[1].voiceId; // Select the first voice
      final audioBytes = await elevenLabs.synthesize(
          TextToSpeechRequest(voiceId: voiceId, text: "text to speech"));
      await _elevenPlayer.play(DeviceFileSource(audioBytes.path));
    }
    // await _elevenPlayer.play(AssetSource('4.mp3'));
  }

  @override
  void dispose() {
    _elevenPlayer.dispose();
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          // if (_controller.value.isInitialized)
          //   SizedBox.expand(
          //     child: FittedBox(
          //       fit: BoxFit.cover,
          //       child: SizedBox(
          //         width: _controller.value.size.width,
          //         height: _controller.value.size.height,
          //         child: VideoPlayer(_controller),
          //       ),
          //     ),
          //   ),
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'ALARM',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '7:00',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'PM',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ...rest of your code...
}
