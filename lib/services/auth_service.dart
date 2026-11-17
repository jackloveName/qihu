import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.phone,
    required this.userName,
  });

  final String token;
  final String phone;
  final String userName;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    this.avatarPath = '',
    this.birthday = '',
    this.gender = '',
    this.borrowFlag,
  });

  final String name;
  final String phone;
  final String avatarPath;
  final String birthday;
  final String gender;
  final int? borrowFlag;

  bool get hasProfileDetails {
    final displayName = name.trim();
    return (displayName.isNotEmpty && displayName != phone.trim()) ||
        avatarPath.trim().isNotEmpty ||
        birthday.trim().isNotEmpty ||
        gender.trim().isNotEmpty;
  }
}

class AuthService {
  AuthService({
    http.Client? client,
    ApiClient? apiClient,
    void Function()? onUnauthorized,
    bool? bypassNetworkForTests,
  }) : _api =
           apiClient ??
           ApiClient(client: client, onUnauthorized: onUnauthorized),
       _bypassNetwork =
           bypassNetworkForTests ??
           Platform.environment.containsKey('FLUTTER_TEST');

  final ApiClient _api;
  final bool _bypassNetwork;
  static const _passwordSecret = String.fromEnvironment(
    'LOGIN_PASSWORD_SECRET',
    defaultValue: '-mall--password-',
  );

  bool get _testMode => _bypassNetwork;

  Future<void> sendLoginCode(String phone) async {
    if (_testMode) return;
    await _api.put(
      '/mall_biz/ua/sms/verification_code/login_whocode',
      body: {'mobile': phone},
      timeout: ApiSettings.configTimeout,
      silent: true,
    );
  }

  Future<AuthSession> loginWithCode({
    required String phone,
    required String code,
  }) async {
    if (_testMode) {
      return AuthSession(token: 'test-token', phone: phone, userName: phone);
    }
    final result = await _api.post(
      '/mall_auth/ua/login_with_code',
      body: {
        ..._baseLoginPayload(phone, loginStatus: 1),
        'mobile': phone,
        'validCode': code,
      },
    );
    return _sessionFromResponse(result, phone);
  }

  Future<AuthSession> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    if (_testMode) {
      return AuthSession(token: 'test-token', phone: phone, userName: phone);
    }
    final encrypted = _encryptPassword(
      '${DateTime.now().millisecondsSinceEpoch}$password',
    );
    final result = await _api.post(
      '/mall_auth/ua/login',
      body: {
        ..._baseLoginPayload(phone, loginStatus: 2),
        'passWord': encrypted,
      },
    );
    return _sessionFromResponse(result, phone);
  }

  Future<UserProfile> getUserProfile(
    String token, {
    required String fallbackPhone,
  }) async {
    if (_testMode) {
      return UserProfile(name: fallbackPhone, phone: fallbackPhone);
    }
    try {
      final result = await _api.get(
        '/mall_user/user/ma/user_detail_info',
        token: token,
      );
      final user = _unwrapUser(result);
      return UserProfile(
        name:
            (user['nickName'] ??
                    user['nickname'] ??
                    user['userName'] ??
                    user['name'] ??
                    user['phone'] ??
                    fallbackPhone)
                .toString(),
        phone: (user['phone'] ?? user['mobile'] ?? fallbackPhone).toString(),
        avatarPath: _resolveAvatarPath(
          (user['pic'] ??
                  user['avatar'] ??
                  user['avatarUrl'] ??
                  user['headImg'] ??
                  user['headImgUrl'] ??
                  '')
              .toString(),
        ),
        birthday: (user['birthDate'] ?? user['birthday'] ?? '').toString(),
        gender: (user['sex'] ?? user['gender'] ?? '').toString(),
        borrowFlag: _parseFlag(user['borrowFlag']),
      );
    } on Object {
      return UserProfile(name: fallbackPhone, phone: fallbackPhone);
    }
  }

  Future<void> logout(String token) async {
    if (_testMode || token.isEmpty) return;
    await _api.post('/mall_auth/ma/login_out', token: token);
  }

  Future<void> destroyAccount(String token, {bool forceDestroy = false}) async {
    if (_testMode || token.isEmpty) return;
    await _api.get(
      '/mall_user/user/destroy_user',
      query: {'forceDestroy': forceDestroy},
      token: token,
    );
  }

  void close() => _api.close();

  AuthSession _sessionFromResponse(Object? result, String phone) {
    if (result is! Map) throw const FormatException('登录响应格式错误');
    final token = result['accessToken']?.toString().trim();
    if (token == null || token.isEmpty) {
      throw const FormatException('登录响应中缺少访问凭证');
    }
    return AuthSession(token: token, phone: phone, userName: phone);
  }

  Map<String, Object?> _baseLoginPayload(
    String phone, {
    required int loginStatus,
  }) {
    return {
      'sysType': 0,
      'socialType': switch (defaultTargetPlatform) {
        TargetPlatform.android => 5,
        TargetPlatform.iOS => 6,
        _ => 4,
      },
      'tempUid': '',
      'userName': phone,
      'appBrand': ApiSettings.appBrand,
      'osName': AppConfig.platformName,
      'loginStatus': loginStatus,
    };
  }

  String _encryptPassword(String value) {
    final encrypter = Encrypter(
      AES(Key.fromUtf8(_passwordSecret), mode: AESMode.ecb),
    );
    return encrypter.encrypt(value, iv: IV.fromLength(0)).base64;
  }

  String _resolveAvatarPath(String value) {
    final path = value.trim();
    if (path.startsWith('/') &&
        !path.startsWith('//') &&
        AppConfig.resourceBaseUrl.isNotEmpty) {
      return '${AppConfig.resourceBaseUrl}$path';
    }
    return path;
  }

  Map<String, Object?> _unwrapUser(Object? value) {
    var current = value;
    for (var index = 0; index < 4; index++) {
      if (current is! Map) break;
      final map = current.map((key, value) => MapEntry(key.toString(), value));
      current = map['userInfo'] ?? map['user'] ?? map['data'] ?? map;
      if (identical(current, map)) return map;
    }
    return current is Map
        ? current.map((key, value) => MapEntry(key.toString(), value))
        : const {};
  }

  static int? _parseFlag(Object? value) {
    return value is num && value == 1 ? 1 : null;
  }
}
