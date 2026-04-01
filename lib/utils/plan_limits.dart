import 'package:dawn_weaver/utils/constants.dart';

/// Free vs premium content rules for alarms (virtual characters & bundled music).
class PlanLimits {
  PlanLimits._();

  /// Free tier: 5th, 8th, 13th, 21st, and 34th character (1-based) → 0-based indices.
  static const Set<int> freeVirtualCharacterIndices = {4, 7, 12, 20, 33};

  /// Free tier: odd positions in the bundled list (1st, 3rd, 5th, …), max 20 tracks → indices 0,2,…,38.
  static bool isBundledMusicIndexFree(int index) {
    if (index < 0) return false;
    if (index % 2 != 0) return false;
    return index <= 38;
  }

  static bool isVirtualCharacterIndexFree(int index) =>
      freeVirtualCharacterIndices.contains(index);

  static bool _isDeviceMusicPath(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('/') ||
        lower.startsWith('file://') ||
        lower.contains(':\\');
  }

  static bool isBundledMusicUrlFree(String link, List<String> bundledLinks) {
    if (link.isEmpty || link == 'default') return true;
    if (_isDeviceMusicPath(link)) return true;
    final idx = bundledLinks.indexOf(link);
    if (idx < 0) return false;
    return isBundledMusicIndexFree(idx);
  }

  static bool isVirtualCharacterUrlFree(
    String videoUrl,
    List<Map<String, String>> characters,
  ) {
    if (videoUrl == 'default') return true;
    final idx = characters.indexWhere((c) => c['videoUrl'] == videoUrl);
    if (idx < 0) return true;
    return freeVirtualCharacterIndices.contains(idx);
  }

  static String clampVirtualCharacter(
    String videoUrl,
    List<Map<String, String>> characters,
  ) {
    if (isVirtualCharacterUrlFree(videoUrl, characters)) return videoUrl;
    return 'default';
  }

  static String clampBundledMusic(String link, List<String> bundledLinks) {
    if (isBundledMusicUrlFree(link, bundledLinks)) return link;
    return AppConstants.defaultAlarmSoundUrl;
  }
}
