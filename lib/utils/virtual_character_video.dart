import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:dawn_weaver/utils/api_base_url.dart';

/// Resolves the network [Uri] for a [virtualCharacter] string (full URL or
/// storage-relative path).
Uri resolveVirtualCharacterVideoUri(String virtualCharacter) {
  if (virtualCharacter.startsWith('http://') ||
      virtualCharacter.startsWith('https://')) {
    return Uri.parse(virtualCharacter);
  }
  return Uri.parse(
    '${resolveApiBaseUrl(dotenv.env['base_url'])}/storage/$virtualCharacter',
  );
}

/// Pre-initializes and starts playback so [WakeupScreen] can show the first
/// frame immediately (no black placeholder).
Future<VideoPlayerController?> preloadVirtualCharacterVideo(
  String virtualCharacter, {
  required bool mute,
}) async {
  if (virtualCharacter == 'default') return null;
  try {
    final uri = resolveVirtualCharacterVideoUri(virtualCharacter);
    final controller = VideoPlayerController.networkUrl(uri)
      ..setLooping(true)
      ..setVolume(mute ? 0 : 1);
    await controller.initialize();
    await controller.play();
    return controller;
  } catch (_) {
    return null;
  }
}
