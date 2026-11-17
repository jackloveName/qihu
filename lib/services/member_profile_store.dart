import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api/api_client.dart';
import 'api/config_api.dart';

class MemberProfileSnapshot {
  const MemberProfileSnapshot({
    required this.completed,
    required this.nickname,
    required this.city,
    required this.careTags,
  });

  final bool completed;
  final String nickname;
  final String city;
  final List<String> careTags;
}

class MemberProfileStore {
  MemberProfileStore({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const storageKey = 'QIHU_PROFILE_V1';
  final ApiClient _api;
  late final ConfigApi _config;

  Future<MemberProfileSnapshot?> read(String token) async {
    try {
      final raw = await _config.readUser(storageKey, token);
      final data = _extractMap(raw);
      if (data == null) return null;
      final completedValue = data['completed'];
      final completed =
          completedValue == true || completedValue?.toString() == 'true';
      final tags = (data['careTags'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(growable: false);
      return MemberProfileSnapshot(
        completed: completed,
        nickname: data['nickname']?.toString() ?? '',
        city: data['city']?.toString() ?? '',
        careTags: tags,
      );
    } on Object {
      return null;
    }
  }

  Future<void> save({
    required String token,
    required String nickname,
    required String city,
    required List<String> careTags,
  }) async {
    await _config.saveUser(
      key: storageKey,
      value: {
        'completed': true,
        'nickname': nickname,
        'city': city,
        'careTags': careTags,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      remark: '栖护会员资料',
      token: token,
    );
  }

  void close() => _api.close();

  static Map<String, Object?>? _extractMap(Object? value, [int depth = 0]) {
    if (depth > 6 || value == null) return null;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        return _extractMap(jsonDecode(text), depth + 1);
      } on FormatException {
        return null;
      }
    }
    if (value is! Map) return null;
    final map = value.map((key, value) => MapEntry(key.toString(), value));
    if (const {
      'completed',
      'nickname',
      'city',
      'careTags',
    }.any(map.containsKey)) {
      return map;
    }
    for (final key in const [
      'data',
      'config',
      'paramValue',
      'value',
      'content',
    ]) {
      final nested = _extractMap(map[key], depth + 1);
      if (nested != null) return nested;
    }
    return null;
  }
}
