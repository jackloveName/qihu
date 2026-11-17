import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
  });

  final String version;
  final String downloadUrl;
  final String notes;
  final bool force;
}

class AppUpdateService {
  AppUpdateService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const _skipKey = 'qihu.appUpdate.skipped';
  final ApiClient _api;
  late final ConfigApi _config;

  Future<void> checkAndShow(BuildContext context) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final raw = await _config.readPublic(ApiSettings.appBrand);
      final config = _configMap(raw);
      final package = await PackageInfo.fromPlatform();
      final update = parseUpdateInfo(
        config,
        currentVersion: package.version,
        isIOS: defaultTargetPlatform == TargetPlatform.iOS,
      );
      if (update == null) return;
      final preferences = await SharedPreferences.getInstance();
      if (!update.force) {
        final skipped = preferences.getString(_skipKey) ?? '';
        final parts = skipped.split('|');
        if (parts.length == 2 && parts.first == update.version) {
          final skippedAt = DateTime.tryParse(parts.last);
          if (skippedAt != null &&
              DateTime.now().difference(skippedAt) <
                  const Duration(hours: 24)) {
            return;
          }
        }
      }
      if (!context.mounted) return;
      final invalidForce = update.force && update.downloadUrl.isEmpty;
      final canDismiss = !update.force || invalidForce;
      await showDialog<void>(
        context: context,
        barrierDismissible: canDismiss,
        barrierColor: const Color(0x990D1512),
        builder: (dialogContext) => PopScope(
          canPop: canDismiss,
          child: _UpdateDialog(
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
                : () => _openDownload(dialogContext, update.downloadUrl),
          ),
        ),
      );
    } on Object catch (error) {
      if (kDebugMode) debugPrint('App update check failed: $error');
    } finally {
      _api.close();
    }
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
    return AppUpdateInfo(
      version: latest,
      downloadUrl: url,
      notes: notes,
      force: type == 2,
    );
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

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({
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
    final notes = info.notes.isEmpty ? '包含体验优化和问题修复。' : info.notes;
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
              Text(
                info.force ? '发现重要更新' : '发现新版本',
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
              const SizedBox(height: 18),
              if (onLater == null)
                PrimaryButton(
                  label: onUpdate == null ? '下载地址未配置' : '立即更新',
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
                        label: onUpdate == null ? '地址未配置' : '立即更新',
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
