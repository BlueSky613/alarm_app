import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  static Future<void> setLanguage(String languageCode) async {
    await initialize();
    
    final language = languageCode == 'es' ? 'es-ES' : 'en-US';
    await _tts.setLanguage(language);
  }

  static Future<void> speakGreeting(
    String message, {
    String language = 'en',
  }) async {
    await initialize();
    await setLanguage(language);
    
    await _tts.speak(message);
  }

  static Future<void> speakContent(
    String content, {
    String language = 'en',
    double speechRate = 0.6,
  }) async {
    await initialize();
    await setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    
    await _tts.speak(content);
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  static Future<void> playAlarmSound({String? soundPath}) async {
    try {
      if (soundPath != null && soundPath != 'default') {
        await _audioPlayer.play(DeviceFileSource(soundPath));
      } else {
        // Play default alarm sound
        await _audioPlayer.play(AssetSource('sounds/default_alarm.mp3'));
      }
    } catch (e) {
      // Fallback to system notification sound if custom sound fails
      print('Error playing alarm sound: $e');
    }
  }

  static Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }

  static Future<void> pauseAlarmSound() async {
    await _audioPlayer.pause();
  }

  static Future<void> resumeAlarmSound() async {
    await _audioPlayer.resume();
  }

  static Future<bool> isPlaying() async {
    return _audioPlayer.state == PlayerState.playing;
  }

  static Future<bool> isSpeaking() async {
    return await _tts.getEngines.then((_) async {
      // Check if TTS is currently speaking
      return false; // FlutterTTS doesn't have a direct way to check this
    });
  }

  static Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }

  static Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.1, 2.0));
  }

  static Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.1, 2.0));
  }

  static Future<List<String>> getAvailableLanguages() async {
    await initialize();
    final languages = await _tts.getLanguages;
    return languages?.cast<String>() ?? ['en-US', 'es-ES'];
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _tts.stop();
  }
}