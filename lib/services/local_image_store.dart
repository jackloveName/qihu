import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract final class LocalImageStore {
  static const _ownedPrefixes = ['profile_avatar_', 'pet_photo_', 'health_'];
  static bool get _testMode => Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> deleteAll() async {
    if (_testMode) return;
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (_ownedPrefixes.any(name.startsWith)) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Continue clearing local records even if one image is locked.
        }
      }
    }
  }
}
