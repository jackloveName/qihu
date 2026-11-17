import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:petcare_manager/services/agreement_service.dart';
import 'package:petcare_manager/services/api/api_client.dart';
import 'package:petcare_manager/services/api/api_settings.dart';
import 'package:petcare_manager/services/app_update_service.dart';
import 'package:petcare_manager/services/auth_service.dart';

void main() {
  test('后端应用标识默认使用金灵优记', () {
    expect(ApiSettings.appBrand, '金灵优记');
  });

  test('协议配置使用 BC 对应的隐私政策和注册协议键', () {
    expect(ApiSettings.privacyProtocolKey, 'BC_PRIVACY_PROTOC');
    expect(ApiSettings.registerProtocolKey, 'BC_REGISTER_PROTOC');
    expect(AgreementService.privacyKey, 'BC_PRIVACY_PROTOC');
    expect(AgreementService.registerKey, 'BC_REGISTER_PROTOC');
  });

  test('API 客户端解析成功响应并携带 Token', () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {'ok': true},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await client.get('/user', token: 'session-token');

    expect(result, {'ok': true});
    expect(captured.headers['Authorization'], 'session-token');
  });

  test('密码登录请求向后端传递金灵优记应用标识', () async {
    late Map<String, dynamic> payload;
    final auth = AuthService(
      bypassNetworkForTests: false,
      client: MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'accessToken': 'access-token'}), 200);
      }),
    );

    final session = await auth.loginWithPassword(
      phone: '13800138000',
      password: '123456',
    );

    expect(session.token, 'access-token');
    expect(payload['appBrand'], '金灵优记');
    expect(payload['loginStatus'], 2);
    expect(payload['passWord'], isNot('123456'));
  });

  test('云端已有资料时不会被视为待完善资料', () {
    expect(
      const UserProfile(
        name: '13800138000',
        phone: '13800138000',
      ).hasProfileDetails,
      isFalse,
    );
    expect(
      const UserProfile(name: '小王', phone: '13800138000').hasProfileDetails,
      isTrue,
    );
  });

  test('用户资料解析 borrowFlag 并仅接受数字 1', () async {
    final auth = AuthService(
      bypassNetworkForTests: false,
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {
              'userInfo': {'nickName': 'User', 'borrowFlag': 1},
            },
          }),
          200,
        );
      }),
    );

    final profile = await auth.getUserProfile(
      'token',
      fallbackPhone: '13800138000',
    );
    expect(profile.borrowFlag, 1);

    expect(
      const UserProfile(name: '小王', phone: '13800138000').borrowFlag,
      isNull,
    );

    final stringFlagAuth = AuthService(
      bypassNetworkForTests: false,
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {
              'userInfo': {'nickName': 'User', 'borrowFlag': '1'},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final stringFlagProfile = await stringFlagAuth.getUserProfile(
      'token',
      fallbackPhone: '13800138000',
    );
    expect(stringFlagProfile.borrowFlag, isNull);
  });

  test('协议服务将 HTML 转换为可读文本', () {
    final content = AgreementService.parseResponseBody(
      jsonEncode({'code': '00000', 'data': '<p>隐私政策</p><p>联系：\${email}</p>'}),
      operatorName: '栖护运营者',
      contactEmail: 'support@example.com',
    );

    expect(content, contains('隐私政策'));
    expect(content, contains('support@example.com'));
    expect(content, isNot(contains('<p>')));
  });

  test('版本号按数字逐段比较并解析平台字段', () {
    expect(AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    final update = AppUpdateService.parseUpdateInfo(
      {
        'iosAppVersion': '1.10.0',
        'iosAppDownloadUrl': 'https://example.test/app',
        'iosUpdateType': '2',
        'iosVersionDesc': '修复问题',
      },
      currentVersion: '1.9.9',
      isIOS: true,
    );

    expect(update, isNotNull);
    expect(update!.version, '1.10.0');
    expect(update.force, isTrue);
    expect(update.downloadUrl, 'https://example.test/app');
    expect(update.notes, '修复问题');
    expect(update.platform, AppUpdatePlatform.ios);

    final android = AppUpdateService.parseUpdateInfo(
      {
        'androidVersion': '2.1.0',
        'androidAppDownloadUrl': 'https://example.test/qihu.apk',
        'androidUpdateType': '1',
        'androidUpdateWay': '2',
        'androidVersionDesc': '安卓应用内安装',
      },
      currentVersion: '2.0.0',
      isIOS: false,
    );
    expect(android!.platform, AppUpdatePlatform.android);
    expect(android.androidMode, AndroidUpdateMode.inApp);
    expect(android.notes, '安卓应用内安装');
  });
}
