import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Resolves [base_url] from .env for HTTP calls to the Laravel admin.
///
/// On **Android emulator**, `127.0.0.1` points at the emulator itself, not your
/// PC. The host loopback is `10.0.2.2:8000`. This function replaces
/// `127.0.0.1` with `10.0.2.2` for Android only.
///
/// On a **physical Android phone**, use your PC's LAN IP in `.env` (e.g. `http://192.168.1.x:8000`).
String resolveApiBaseUrl(String? raw) {
  var u = (raw ?? '').trim().replaceAll(RegExp(r'/$'), '');
  if (u.isEmpty) return u;
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      u.contains('127.0.0.1')) {
    u = u.replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return u;
}
