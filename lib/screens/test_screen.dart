import 'package:elevenlabs_flutter/elevenlabs_config.dart';
import 'package:elevenlabs_flutter/elevenlabs_types.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:elevenlabs_flutter/elevenlabs_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dawn_weaver/l10n/app_localizations.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  final elevenLabs = ElevenLabsAPI();
  final AudioPlayer _elevenPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    generateSpeech();
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
  }

  @override
  void dispose() {
    _elevenPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context).alarms.toUpperCase(),
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
                    AppLocalizations.of(context).pm,
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
}
