import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class PrivacyConsentStore {
  static const currentVersion = 2;
  static const _key = 'qihu.privacy.agreedVersion';

  static bool get _testMode => Platform.environment.containsKey('FLUTTER_TEST');

  static Future<bool> hasCurrentConsent() async {
    if (_testMode) return true;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_key) == currentVersion;
  }

  static Future<void> accept() async {
    if (_testMode) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_key, currentVersion);
  }
}
