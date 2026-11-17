import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../widgets/app_widgets.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'api/config_api.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.notes,
    required this.force,
    this.platform = AppUpdatePlatform.android,
    this.androidMode = AndroidUpdateMode.browser,
  });

  final String version;
  final String downloadUrl;
  final String notes;
  final bool force;
  final AppUpdatePlatform platform;
  final AndroidUpdateMode androidMode;
}

enum AppUpdatePlatform { ios, android }

enum AndroidUpdateMode { browser, inApp }

enum UpdateCheckStatus { updateAvailable, upToDate, failed }

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.status,
    this.info,
    this.message = '',
  });

  final UpdateCheckStatus status;
  final AppUpdateInfo? info;
  final String message;
}

class AppUpdateService {
  AppUpdateService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const _skipKey = 'qihu.appUpdate.skipped';
  static const _platformChannel = MethodChannel('qihu/app_update');
  final ApiClient _api;
  late final ConfigApi _config;

  Future<AppUpdateCheckResult> checkAndShow(
    BuildContext context, {
    bool manual = false,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      if (manual && context.mounted) {
        showAppMessage(context, '测试环境不执行远程更新检查');
      }
      return const AppUpdateCheckResult(
        status: UpdateCheckStatus.upToDate,
        message: '当前已是最新版本',
      );
    }
    try {
      final raw = await _config.readPublic(ApiSettings.appBrand);
      final config = _configMap(raw);
      final package = await PackageInfo.fromPlatform();
      final update = parseUpdateInfo(
        config,
        currentVersion: package.version,
        isIOS: defaultTargetPlatform == TargetPlatform.iOS,
      );
      if (update == null) {
        if (manual && context.mounted) showAppMessage(context, '当前已是最新版本');
        return const AppUpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          message: '当前已是最新版本',
        );
      }
      final preferences = await SharedPreferences.getInstance();
      if (!update.force && !manual) {
        final skipped = preferences.getString(_skipKey) ?? '';
        final parts = skipped.split('|');
        if (parts.length == 2 && parts.first == update.version) {
          final skippedAt = DateTime.tryParse(parts.last);
          if (skippedAt != null &&
              DateTime.now().difference(skippedAt) <
                  const Duration(hours: 24)) {
            return AppUpdateCheckResult(
              status: UpdateCheckStatus.updateAvailable,
              info: update,
              message: '此版本已设置稍后提醒',
            );
          }
        }
      }
      if (!context.mounted) {
        return AppUpdateCheckResult(
          status: UpdateCheckStatus.updateAvailable,
          info: update,
        );
      }
      final invalidForce = update.force && update.downloadUrl.isEmpty;
      final canDismiss = !update.force || invalidForce;
      await showDialog<void>(
        context: context,
        barrierDismissible: canDismiss,
        barrierColor: const Color(0x990D1512),
        builder: (dialogContext) => PopScope(
          canPop: canDismiss,
          child: AppUpdateDialog(
            currentVersion: package.version,
            info: update,
            onLater: canDismiss
                ? () async {
                    if (!invalidForce && update.downloadUrl.isNotEmpty) {
                      await preferences.setString(
                        _skipKey,
                        '${update.version}|${DateTime.now().toIso8601String()}',
                      );
                    }
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  }
                : null,
            onUpdate: update.downloadUrl.isEmpty
                ? null
                : () => _handleUpdate(dialogContext, update),
          ),
        ),
      );
      return AppUpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        info: update,
      );
    } on Object catch (error) {
      if (kDebugMode) debugPrint('App update check failed: $error');
      if (manual && context.mounted) {
        showAppMessage(context, '检查更新失败，请稍后重试');
      }
      return AppUpdateCheckResult(
        status: UpdateCheckStatus.failed,
        message: error.toString(),
      );
    } finally {
      _api.close();
    }
  }

  Future<void> _handleUpdate(BuildContext context, AppUpdateInfo info) async {
    if (info.platform == AppUpdatePlatform.android &&
        info.androidMode == AndroidUpdateMode.inApp) {
      await _downloadAndInstall(context, info);
      return;
    }
    await _openDownload(context, info.downloadUrl);
  }

  Future<void> _openDownload(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        showAppMessage(context, '无法打开下载地址，已复制到剪贴板');
      }
    }
  }

  Future<void> _downloadAndInstall(
    BuildContext context,
    AppUpdateInfo info,
  ) async {
    final uri = Uri.tryParse(info.downloadUrl);
    if (uri == null) {
      if (context.mounted) showAppMessage(context, '下载地址无效');
      return;
    }
    final progress = ValueNotifier<double?>(null);
    var progressOpen = false;
    final client = http.Client();
    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _DownloadProgressDialog(
            version: info.version,
            progress: progress,
          ),
        ),
      );
      progressOpen = true;
      final request = http.Request('GET', uri);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 400) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final total = response.contentLength;
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/qihu_update_${DateTime.now().millisecondsSinceEpoch}.apk',
      );
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total != null && total > 0) {
            progress.value = (received / total).clamp(0.0, 1.0);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (progressOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }
      await _platformChannel.invokeMethod<void>('installApk', {
        'path': file.path,
      });
    } on Object catch (error) {
      if (progressOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }
      if (context.mounted) {
        showAppMessage(
          context,
          '更新包下载或安装失败：${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      client.close();
    }
  }

  @visibleForTesting
  static AppUpdateInfo? parseUpdateInfo(
    Map<String, Object?> config, {
    required String currentVersion,
    required bool isIOS,
  }) {
    final latest =
        _text(
          isIOS
              ? config['iosAppVersion']
              : config['androidVersion'] ?? config['androidAppVersion'],
        ) ??
        _text(config['version']) ??
        _text(config['versionName']) ??
        _text(config['latestVersion']) ??
        _text(config['newVersion']) ??
        _text(config['appVersion']) ??
        '';
    if (latest.isEmpty) return null;
    final type = int.tryParse(
      _text(isIOS ? config['iosUpdateType'] : config['androidUpdateType']) ??
          '1',
    );
    if (type == 0 || compareVersions(latest, currentVersion) <= 0) return null;
    final url =
        _text(
          isIOS
              ? config['iosAppDownloadUrl']
              : config['androidAppDownloadUrl'] ?? config['androidUrl'],
        ) ??
        _text(config['h5DownloadUrl']) ??
        _text(config['url']) ??
        _text(config['downloadUrl']) ??
        _text(config['storeUrl']) ??
        _text(config['apkUrl']) ??
        '';
    final notes =
        _text(
          isIOS
              ? config['iosVersionDesc'] ?? config['iosUpdateContent']
              : config['androidVersionDesc'] ?? config['androidUpdateContent'],
        ) ??
        _text(config['notes']) ??
        _text(config['note']) ??
        _text(config['content']) ??
        _text(config['desc']) ??
        _text(config['description']) ??
        _text(config['updateLog']) ??
        _text(config['versionDesc']) ??
        '';
    final isIOSPlatform = isIOS;
    final androidMode = _androidUpdateMode(config);
    return AppUpdateInfo(
      version: latest,
      downloadUrl: url,
      notes: notes,
      force: type == 2,
      platform: isIOSPlatform
          ? AppUpdatePlatform.ios
          : AppUpdatePlatform.android,
      androidMode: androidMode,
    );
  }

  static AndroidUpdateMode _androidUpdateMode(Map<String, Object?> config) {
    final value =
        _text(
          config['androidUpdateWay'] ??
              config['androidUpdateMode'] ??
              config['androidDownloadMode'] ??
              config['androidInstallMode'],
        )?.toLowerCase() ??
        '';
    if (value == '2' ||
        value.contains('inapp') ||
        value.contains('in_app') ||
        value.contains('download') ||
        value.contains('install')) {
      return AndroidUpdateMode.inApp;
    }
    return AndroidUpdateMode.browser;
  }

  @visibleForTesting
  static int compareVersions(String first, String second) {
    List<int> parts(String value) {
      return value
          .trim()
          .replaceFirst(RegExp(r'^[vV]'), '')
          .split(RegExp(r'[.+-]'))
          .map((part) => int.tryParse(part) ?? 0)
          .toList();
    }

    final a = parts(first);
    final b = parts(second);
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final av = index < a.length ? a[index] : 0;
      final bv = index < b.length ? b[index] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static Map<String, Object?> _configMap(Object? value) {
    var current = value;
    for (var depth = 0; depth < 6; depth++) {
      if (current is String) {
        try {
          current = jsonDecode(current);
          continue;
        } on FormatException {
          break;
        }
      }
      if (current is Map) {
        final map = current.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (map.keys.any(
          (key) => const {
            'iosAppVersion',
            'androidVersion',
            'androidAppVersion',
            'version',
            'versionName',
            'latestVersion',
          }.contains(key),
        )) {
          return map;
        }
        for (final key in const [
          'data',
          'config',
          'paramValue',
          'value',
          'content',
        ]) {
          if (map[key] != null) {
            current = map[key];
            break;
          }
        }
        if (current == map) break;
        continue;
      }
      break;
    }
    return const {};
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

@visibleForTesting
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    required this.currentVersion,
    required this.info,
    required this.onLater,
    required this.onUpdate,
  });

  final String currentVersion;
  final AppUpdateInfo info;
  final VoidCallback? onLater;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final isIOS = info.platform == AppUpdatePlatform.ios;
    final notes = info.notes.isEmpty
        ? isIOS
              ? '包含 App Store 版本的体验优化和问题修复。'
              : '包含最新版本的体验优化和问题修复。'
        : info.notes;
    final actionLabel = isIOS
        ? '打开 App Store'
        : info.androidMode == AndroidUpdateMode.inApp
        ? '下载并安装'
        : '浏览器下载';
    return Dialog(
      key: const ValueKey('app-update-dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D0D1512),
              blurRadius: 36,
              offset: Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: Color(0xFFF4F1E6),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (info.force) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.roseWash,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.rose.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      '必须更新',
                      style: AppText.body(
                        9.5,
                        color: AppColors.rose,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
              ],
              Text(
                info.force
                    ? isIOS
                          ? 'iOS 版本必须更新'
                          : 'Android 版本必须更新'
                    : '发现新版本',
                textAlign: TextAlign.center,
                style: AppText.display(23),
              ),
              const SizedBox(height: 6),
              Text(
                '当前 $currentVersion  →  ${info.version}',
                textAlign: TextAlign.center,
                style: AppText.number(
                  11,
                  color: AppColors.muted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  notes,
                  style: AppText.body(11.5, color: AppColors.ink2, height: 1.7),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isIOS
                    ? '更新将跳转 App Store，请完成下载后重新打开 App。'
                    : info.androidMode == AndroidUpdateMode.inApp
                    ? '应用内下载完成后将打开系统安装程序，安装结束后 App 会自动重启。'
                    : '将在浏览器中打开安装包下载页面，下载完成后请按系统提示安装。',
                textAlign: TextAlign.center,
                style: AppText.body(10, color: AppColors.muted, height: 1.55),
              ),
              const SizedBox(height: 18),
              if (onLater == null)
                PrimaryButton(
                  label: onUpdate == null ? '下载地址未配置' : actionLabel,
                  onPressed: onUpdate,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: '稍后',
                        ghost: true,
                        onPressed: onLater,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: PrimaryButton(
                        label: onUpdate == null ? '地址未配置' : actionLabel,
                        onPressed: onUpdate,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog({
    required this.version,
    required this.progress,
  });

  final String version;
  final ValueListenable<double?> progress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      title: Text('正在下载 $version', style: AppText.display(19)),
      content: ValueListenableBuilder<double?>(
        valueListenable: progress,
        builder: (context, value, _) {
          final percent = value == null ? null : (value * 100).round();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: value,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: AppColors.paper3,
                color: AppColors.brand,
              ),
              const SizedBox(height: 10),
              Text(
                percent == null ? '正在连接下载服务器…' : '已完成 $percent%',
                style: AppText.body(11, color: AppColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }
}
