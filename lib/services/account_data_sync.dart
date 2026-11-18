import 'dart:async';

import '../models.dart';
import '../storage/session_token_store.dart';
import 'api/api_client.dart';
import 'api/config_api.dart';

class AccountDataSync {
  AccountDataSync(this.state, {ApiClient? apiClient})
    : _api = apiClient ?? ApiClient() {
    _config = ConfigApi(_api);
  }

  static const storageKey = 'QIHU_APP_STATE_V1';
  static AccountDataSync? active;

  final AppState state;
  final ApiClient _api;
  late final ConfigApi _config;
  Timer? _debounce;
  String? _token;
  bool _restoring = false;
  bool _disposed = false;

  Future<void> initialize() async {
    active = this;
    state.addListener(_onStateChanged);
    _token = await SessionTokenStore.read();
    if (state.signedIn && !state.isGuest && _token?.isNotEmpty == true) {
      await _restoreOrSeed();
    }
  }

  Future<void> handleSignIn() async {
    _token = await SessionTokenStore.read();
    if (_token?.isNotEmpty != true || !state.signedIn || state.isGuest) return;
    await _restoreOrSeed();
  }

  Future<void> _restoreOrSeed() async {
    if (_restoring || !state.signedIn || state.isGuest) return;
    _restoring = true;
    try {
      await state.preparePhotosForCloud();
      final remote = await _config.readUser(storageKey, _token!);
      final restored = await state.restoreCloudSnapshot(remote);
      if (!restored) await _save();
    } on Object {
      // Local data remains available if cloud synchronization is unavailable.
    } finally {
      _restoring = false;
    }
  }

  void _onStateChanged() {
    if (_restoring || _disposed || !state.signedIn || state.isGuest) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1800), () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    if (_restoring || !state.signedIn || state.isGuest || _disposed) return;
    _token ??= await SessionTokenStore.read();
    if (_token?.isNotEmpty != true) return;
    await _save();
  }

  Future<void> _save() async {
    try {
      await state.preparePhotosForCloud();
      await _config.saveUser(
        key: storageKey,
        value: state.exportCloudSnapshot(),
        remark: '栖护账号数据',
        token: _token!,
      );
    } on Object {
      // The local snapshot remains authoritative until the next successful sync.
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounce?.cancel();
    state.removeListener(_onStateChanged);
    if (identical(active, this)) active = null;
    _api.close();
  }
}
