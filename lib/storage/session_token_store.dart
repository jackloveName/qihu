import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class SessionTokenStore {
  static const _key = 'qihu.sessionToken';
  static const _storage = FlutterSecureStorage();

  static bool get _testMode => Platform.environment.containsKey('FLUTTER_TEST');

  static Future<String?> read() {
    if (_testMode) return Future.value(null);
    return _storage.read(key: _key);
  }

  static Future<void> write(String token) {
    if (_testMode) return Future.value();
    return _storage.write(key: _key, value: token);
  }

  static Future<void> clear() {
    if (_testMode) return Future.value();
    return _storage.delete(key: _key);
  }
}
