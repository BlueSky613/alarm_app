import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

/// Returns a locally-cached [File] for the given video URL.
/// Downloads from network on first access; subsequent calls return the cache.
Future<File?> _cachedVideoFile(Uri uri) async {
  final dir = await getApplicationDocumentsDirectory();
  final safeName = '${uri.toString().hashCode.abs()}.mp4';
  final file = File(p.join(dir.path, 'video_cache', safeName));
  if (await file.exists()) return file;

  try {
    await file.parent.create(recursive: true);
    final resp = await http.get(uri).timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      await file.writeAsBytes(resp.bodyBytes);
      return file;
    }
  } catch (_) {}
  return null;
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
    final cached = await _cachedVideoFile(uri);

    final VideoPlayerController controller;
    if (cached != null) {
      controller = VideoPlayerController.file(cached);
    } else {
      controller = VideoPlayerController.networkUrl(uri);
    }

    controller
      ..setLooping(true)
      ..setVolume(mute ? 0 : 1);
    await controller.initialize();
    await controller.play();
    return controller;
  } catch (_) {
    return null;
  }
}
