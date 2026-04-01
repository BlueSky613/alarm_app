import 'dart:io';

import 'package:flutter/painting.dart';

/// Resolves [UserProfile.avatarRef] to an [ImageProvider] (settings + home header).
ImageProvider avatarImageProviderFromRef(String ref) {
  final v = ref.trim();
  if (v.isEmpty || v == 'default') {
    return const AssetImage('assets/solrise_logo.png');
  }
  if (v.startsWith('file:')) {
    final p = v.substring(5);
    final f = File(p);
    if (f.existsSync()) return FileImage(f);
    return const AssetImage('assets/solrise_logo.png');
  }
  if (v.startsWith('asset:')) {
    return AssetImage(v.substring(6));
  }
  return AssetImage(v);
}
