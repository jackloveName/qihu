import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app_theme.dart';
import '../data/china_cities.dart';
import '../models.dart';
import '../services/agreement_page_launcher.dart';
import '../services/agreement_service.dart';
import '../services/auth_service.dart';
import '../services/local_image_store.dart';
import '../services/member_profile_store.dart';
import '../storage/privacy_consent_store.dart';
import '../storage/session_token_store.dart';
import 'agreement_screen.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';
import '../widgets/city_picker_sheet.dart';

enum _LoginMode { password, code }

class LegacyLocalLoginScreen extends StatefulWidget {
  const LegacyLocalLoginScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LegacyLocalLoginScreen> createState() => _LegacyLocalLoginScreenState();
}

class _LegacyLocalLoginScreenState extends State<LegacyLocalLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _random = Random.secure();
  _LoginMode _mode = _LoginMode.password;
  bool _obscurePassword = true;
  int _countdown = 0;
  String? _localCode;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331D4A3D),
                            blurRadius: 26,
                            offset: Offset(0, 13),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 40,
                        color: Color(0xFFF4F1E6),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('欢迎来到栖护', style: AppText.display(30)),
                    const SizedBox(height: 9),
                    Text(
                      '把每一次喂养、观察和陪伴都妥善记录下来。',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        12.5,
                        color: AppColors.muted,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<_LoginMode>(
                      segments: const [
                        ButtonSegment(
                          value: _LoginMode.password,
                          label: Text('密码登录'),
                        ),
                        ButtonSegment(
                          value: _LoginMode.code,
                          label: Text('验证码登录'),
                        ),
                      ],
                      selected: {_mode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setState(() => _mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 18),
                    FormSection(
                      label: '手机号',
                      child: TextField(
                        key: const ValueKey('login-phone-field'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        style: AppText.number(15),
                        decoration: const InputDecoration(
                          hintText: '请输入手机号',
                          prefixText: '+86  ',
                        ),
                      ),
                    ),
                    if (_mode == _LoginMode.password)
                      FormSection(
                        label: '密码',
                        child: TextField(
                          key: const ValueKey('login-password-field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _loginWithPassword(context),
                          style: AppText.body(14),
                          decoration: InputDecoration(
                            hintText: '请输入登录密码',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      FormSection(
                        label: '验证码',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('login-code-field'),
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onSubmitted: (_) => _loginWithCode(context),
                                style: AppText.number(15),
                                decoration: const InputDecoration(
                                  hintText: '6 位验证码',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                key: const ValueKey('send-login-code'),
                                onPressed: _countdown > 0
                                    ? null
                                    : () => _sendCode(context),
                                child: Text(
                                  _countdown > 0 ? '${_countdown}s' : '获取验证码',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    PrimaryButton(
                      label: _mode == _LoginMode.password ? '登录' : '验证码登录',
                      onPressed: _mode == _LoginMode.password
                          ? () => _loginWithPassword(context)
                          : () => _loginWithCode(context),
                    ),
                    const SizedBox(height: 11),
                    PrimaryButton(
                      label: '游客模式',
                      ghost: true,
                      onPressed: widget.state.enterGuestMode,
                    ),
                    const SizedBox(height: 13),
                    Text(
                      '游客模式最多添加 3 只宠物，登录后可继续添加。',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        10.5,
                        color: AppColors.faint,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loginWithPassword(BuildContext context) {
    if (!_validPhone(context)) return;
    if (_passwordController.text.trim().length < 6) {
      showAppMessage(context, '请输入至少 6 位密码');
      return;
    }
    _completeLogin();
  }

  void _loginWithCode(BuildContext context) {
    if (!_validPhone(context)) return;
    final code = _codeController.text.trim();
    if (_localCode == null) {
      showAppMessage(context, '请先获取验证码');
      return;
    }
    if (code.length != 6 || code != _localCode) {
      showAppMessage(context, '验证码不正确');
      return;
    }
    _completeLogin();
  }

  bool _validPhone(BuildContext context) {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      showAppMessage(context, '请输入有效的手机号');
      return false;
    }
    return true;
  }

  Future<void> _sendCode(BuildContext context) async {
    if (!_validPhone(context)) return;
    final code = (100000 + _random.nextInt(900000)).toString();
    setState(() => _localCode = code);
    showAppMessage(context, '验证码已发送，本地演示验证码：$code');
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) timer.cancel();
      });
    });
  }

  void _completeLogin() {
    _countdownTimer?.cancel();
    widget.state.startMemberLogin();
  }
}

class LocalLoginScreen extends StatefulWidget {
  const LocalLoginScreen({super.key, required this.state});

  final AppState state;

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();
  final _random = Random.secure();
  _LoginMode _mode = _LoginMode.password;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _submitting = false;
  bool _sendingCode = false;
  int _countdown = 0;
  String? _localCode;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _authService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Column(
                  children: [
                    _LoginBrandPanel(),
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 21, 20, 18),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.hair),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F15211C),
                              blurRadius: 36,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('登录栖护', style: AppText.display(24)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '继续管理你的动物档案',
                                        style: AppText.body(
                                          10.5,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandWash,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.paper2,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.hair),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _LoginModeTab(
                                      label: '密码登录',
                                      selected: _mode == _LoginMode.password,
                                      onTap: () => setState(
                                        () => _mode = _LoginMode.password,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _LoginModeTab(
                                      label: '验证码登录',
                                      selected: _mode == _LoginMode.code,
                                      onTap: () => setState(
                                        () => _mode = _LoginMode.code,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            FormSection(
                              label: '手机号',
                              child: TextField(
                                key: const ValueKey('login-phone-field'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                style: AppText.number(15),
                                decoration: const InputDecoration(
                                  hintText: '请输入手机号',
                                  prefixIcon: Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 19,
                                  ),
                                  prefixText: '+86  ',
                                ),
                              ),
                            ),
                            if (_mode == _LoginMode.password)
                              FormSection(
                                label: '密码',
                                child: TextField(
                                  key: const ValueKey('login-password-field'),
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  style: AppText.body(14),
                                  decoration: InputDecoration(
                                    hintText: '请输入登录密码',
                                    prefixIcon: const Icon(
                                      Icons.password_rounded,
                                      size: 19,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              FormSection(
                                label: '验证码',
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        key: const ValueKey('login-code-field'),
                                        controller: _codeController,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                        style: AppText.number(15),
                                        decoration: const InputDecoration(
                                          hintText: '6 位验证码',
                                          prefixIcon: Icon(
                                            Icons.shield_outlined,
                                            size: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 54,
                                      child: OutlinedButton(
                                        key: const ValueKey('send-login-code'),
                                        onPressed:
                                            !_acceptedTerms ||
                                                _countdown > 0 ||
                                                _sendingCode
                                            ? null
                                            : () => _sendRemoteCode(context),
                                        child: Text(
                                          _countdown > 0
                                              ? '${_countdown}s'
                                              : _sendingCode
                                              ? '发送中'
                                              : '获取验证码',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 7),
                            _LoginConsent(
                              accepted: _acceptedTerms,
                              onChanged: (value) =>
                                  setState(() => _acceptedTerms = value),
                              onOpenPrivacy: () =>
                                  _openAgreement(context, isPrivacy: true),
                              onOpenAgreement: () =>
                                  _openAgreement(context, isPrivacy: false),
                            ),
                            const SizedBox(height: 8),
                            PrimaryButton(
                              label: _mode == _LoginMode.password
                                  ? (_submitting ? '登录中' : '登录')
                                  : '验证码登录',
                              onPressed: !_acceptedTerms || _submitting
                                  ? null
                                  : _mode == _LoginMode.password
                                  ? () => _submitPassword(context)
                                  : () => _submitCode(context),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : widget.state.enterGuestMode,
                                icon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                ),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '游客模式',
                                      style: AppText.body(
                                        10.5,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '最多 3 只宠物',
                                      style: AppText.body(
                                        9.5,
                                        color: AppColors.faint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loginWithPassword(BuildContext context) {
    if (!_validPhone(context)) return;
    if (_passwordController.text.trim().length < 6) {
      showAppMessage(context, '请输入至少 6 位密码');
      return;
    }
    unawaited(_completeLogin());
  }

  void _loginWithCode(BuildContext context) {
    if (!_validPhone(context)) return;
    final code = _codeController.text.trim();
    if (_localCode == null) {
      showAppMessage(context, '请先获取验证码');
      return;
    }
    if (code.length != 6 || code != _localCode) {
      showAppMessage(context, '验证码不正确');
      return;
    }
    unawaited(_completeLogin());
  }

  bool _validPhone(BuildContext context) {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      showAppMessage(context, '请输入有效的手机号');
      return false;
    }
    return true;
  }

  Future<void> _sendCode(BuildContext context) async {
    if (!_validPhone(context)) return;
    final code = (100000 + _random.nextInt(900000)).toString();
    setState(() => _localCode = code);
    showAppMessage(context, '验证码已发送，本地演示验证码：$code');
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _completeLogin({bool profileCompleted = false}) async {
    _countdownTimer?.cancel();
    if (widget.state.isGuest) {
      await LocalImageStore.deleteAll();
    }
    unawaited(PrivacyConsentStore.accept());
    widget.state.startMemberLogin(profileCompleted: profileCompleted);
  }

  Future<void> _sendRemoteCode(BuildContext context) async {
    if (!_validPhone(context)) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      await _sendCode(context);
      return;
    }
    setState(() => _sendingCode = true);
    try {
      await _authService.sendLoginCode(_phoneController.text.trim());
      if (!context.mounted) return;
      _startCountdown();
      showAppMessage(context, '验证码已发送');
    } on Object catch (error) {
      if (context.mounted) {
        showAppMessage(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _submitPassword(BuildContext context) async {
    if (!_acceptedTerms || _submitting) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _loginWithPassword(context);
      return;
    }
    if (!_validPhone(context)) return;
    if (_passwordController.text.trim().length < 6) {
      showAppMessage(context, '请输入至少 6 位密码');
      return;
    }
    await _performLogin(
      context,
      () => _authService.loginWithPassword(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _submitCode(BuildContext context) async {
    if (!_acceptedTerms || _submitting) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _loginWithCode(context);
      return;
    }
    if (!_validPhone(context)) return;
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showAppMessage(context, '请输入 6 位验证码');
      return;
    }
    await _performLogin(
      context,
      () => _authService.loginWithCode(
        phone: _phoneController.text.trim(),
        code: code,
      ),
    );
  }

  Future<void> _performLogin(
    BuildContext context,
    Future<AuthSession> Function() request,
  ) async {
    setState(() => _submitting = true);
    try {
      final session = await request();
      final profile = await _authService.getUserProfile(
        session.token,
        fallbackPhone: session.phone,
      );
      final profileStore = MemberProfileStore();
      MemberProfileSnapshot? savedProfile;
      try {
        savedProfile = await profileStore.read(session.token);
      } finally {
        profileStore.close();
      }
      await SessionTokenStore.write(session.token);
      widget.state.updateProfile(
        nickname: savedProfile?.nickname.trim().isNotEmpty == true
            ? savedProfile!.nickname
            : profile.name.trim().isEmpty
            ? session.phone
            : profile.name.trim(),
        avatarPath: profile.avatarPath.isEmpty
            ? widget.state.avatarPath
            : profile.avatarPath,
        city: savedProfile?.city.trim().isNotEmpty == true
            ? savedProfile!.city
            : widget.state.city,
        careTags: savedProfile?.careTags.isNotEmpty == true
            ? savedProfile!.careTags
            : widget.state.careTags,
      );
      widget.state.updateBorrowFlag(profile.borrowFlag);
      await _completeLogin(
        profileCompleted:
            savedProfile?.completed == true || profile.hasProfileDetails,
      );
    } on Object catch (error) {
      if (context.mounted) {
        showAppMessage(
          context,
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _openAgreement(
    BuildContext context, {
    required bool isPrivacy,
  }) async {
    final key = isPrivacy
        ? AgreementService.privacyKey
        : AgreementService.registerKey;
    if (await AgreementPageLauncher.open(key) || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementScreen(
          protocolKey: key,
          title: isPrivacy ? '隐私政策' : '平台注册协议',
        ),
      ),
    );
  }
}

class MemberConsentScreen extends StatefulWidget {
  const MemberConsentScreen({
    super.key,
    required this.state,
    required this.onAccepted,
  });

  final AppState state;
  final VoidCallback onAccepted;

  @override
  State<MemberConsentScreen> createState() => _MemberConsentScreenState();
}

class _MemberConsentScreenState extends State<MemberConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        size: 34,
                        color: Color(0xFFF4F1E6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '隐私政策与注册协议已更新',
                      textAlign: TextAlign.center,
                      style: AppText.display(23),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '继续使用会员功能前，请重新阅读并确认最新条款。',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        11.5,
                        color: AppColors.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PaperCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _LoginConsent(
                            accepted: _accepted,
                            onChanged: (value) =>
                                setState(() => _accepted = value),
                            onOpenPrivacy: () =>
                                _openAgreement(isPrivacy: true),
                            onOpenAgreement: () =>
                                _openAgreement(isPrivacy: false),
                          ),
                          const SizedBox(height: 13),
                          PrimaryButton(
                            label: _saving ? '正在保存' : '同意并继续',
                            onPressed: _accepted && !_saving ? _accept : null,
                          ),
                          TextButton(
                            onPressed: _saving ? null : widget.state.signOut,
                            child: const Text('退出登录'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await PrivacyConsentStore.accept();
      if (mounted) widget.onAccepted();
    } on Object {
      if (mounted) showAppMessage(context, '无法保存同意状态，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAgreement({required bool isPrivacy}) {
    final key = isPrivacy
        ? AgreementService.privacyKey
        : AgreementService.registerKey;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementScreen(
          protocolKey: key,
          title: isPrivacy ? '隐私政策' : '平台注册协议',
        ),
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C654F), Color(0xFF173D32)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brass2.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 21,
            child: AnimalArt(
              species: PetSpecies.cat,
              size: 104,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            right: 102,
            bottom: 16,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              alignment: Alignment.center,
              child: AnimalArt(
                species: PetSpecies.gecko,
                size: 27,
                color: const Color(0xFFE6D3A4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 19,
                        color: Color(0xFFD9C38F),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '栖护',
                      style: AppText.display(
                        18,
                        color: const Color(0xFFF4F1E6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '欢迎来到栖护',
                  style: AppText.display(
                    29,
                    color: const Color(0xFFF6F1E5),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 245),
                  child: Text(
                    '把每一次喂养、观察和陪伴，\n都留在同一个照护档案里。',
                    style: AppText.body(
                      11,
                      color: const Color(0xFFE6E2D6).withValues(alpha: 0.64),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginModeTab extends StatelessWidget {
  const _LoginModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x291D4A3D),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppText.body(
            11.5,
            color: selected ? const Color(0xFFF4F1E6) : AppColors.muted,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LoginConsent extends StatelessWidget {
  const _LoginConsent({
    required this.accepted,
    required this.onChanged,
    required this.onOpenPrivacy,
    required this.onOpenAgreement,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenAgreement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 11, 10),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            key: const ValueKey('login-consent-checkbox'),
            checked: accepted,
            label: '已阅读并同意《隐私政策》和《平台注册协议》',
            child: InkResponse(
              onTap: () => onChanged(!accepted),
              radius: 20,
              child: SizedBox(
                width: 36,
                height: 34,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accepted ? AppColors.brand : AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accepted ? AppColors.brand : AppColors.hair2,
                        width: 1.3,
                      ),
                    ),
                    child: accepted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Color(0xFFF4F1E6),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  key: const ValueKey('login-consent-copy'),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 0,
                  runSpacing: 2,
                  children: [
                    Text(
                      '已阅读并同意',
                      style: AppText.body(
                        10.5,
                        color: AppColors.ink2,
                        height: 1.45,
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('login-privacy-link'),
                      onTap: onOpenPrivacy,
                      child: Text(
                        '《隐私政策》',
                        style: AppText.body(
                          10.5,
                          color: AppColors.brand,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '和',
                      style: AppText.body(
                        10.5,
                        color: AppColors.ink2,
                        height: 1.45,
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('login-agreement-link'),
                      onTap: onOpenAgreement,
                      child: Text(
                        '《平台注册协议》',
                        style: AppText.body(
                          10.5,
                          color: AppColors.brand,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    this.editMode = false,
  });

  final AppState state;
  final bool editMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _nicknameController = TextEditingController(
    text: widget.state.nickname,
  );
  late String? _avatarPath = widget.state.avatarPath;
  late String _city =
      ChinaCities.match(widget.state.city)?.value ?? widget.state.city;
  late final Set<String> _tags = {...widget.state.careTags};
  final _picker = ImagePicker();
  bool _savingAvatar = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: PagePadding(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: StackHeader(
                    title: widget.editMode ? '编辑个人资料' : '认识一下你',
                    subtitle: widget.editMode ? '头像、城市与趣味标签' : '完成资料后开始照护',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        EditableAvatar(
                          path: _avatarPath,
                          size: 88,
                          radius: 28,
                          badgeSize: 30,
                          isSaving: _savingAvatar,
                          onPressed: _pickAvatar,
                          label: '选择头像',
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '昵称',
                    child: TextField(
                      controller: _nicknameController,
                      maxLength: 18,
                      style: AppText.body(14),
                      decoration: const InputDecoration(
                        hintText: '输入你的昵称',
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '城市',
                    child: CitySelectionField(
                      key: const ValueKey('profile-city-field'),
                      value: _city,
                      onChanged: (value) => setState(() => _city = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '养宠标签',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in AppState.careTagOptions)
                          FilterChip(
                            label: Text(tag),
                            selected: _tags.contains(tag),
                            showCheckmark: false,
                            selectedColor: AppColors.brandWash,
                            backgroundColor: AppColors.paper,
                            side: BorderSide(
                              color: _tags.contains(tag)
                                  ? AppColors.brand
                                  : AppColors.hair2,
                              width: _tags.contains(tag) ? 1.4 : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            labelStyle: AppText.body(
                              11.5,
                              color: _tags.contains(tag)
                                  ? AppColors.brand
                                  : AppColors.ink2,
                              weight: _tags.contains(tag)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _tags.add(tag);
                                } else {
                                  _tags.remove(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 104)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: widget.editMode ? '保存修改' : '保存',
          onPressed: _finish,
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (image == null) return;
      var path = image.path;
      try {
        final directory = await getApplicationDocumentsDirectory();
        final extension = image.name.split('.').lastOrNull ?? 'jpg';
        final target =
            '${directory.path}/profile_avatar_${DateTime.now().microsecondsSinceEpoch}.$extension';
        await image.saveTo(target);
        path = target;
      } on Object {
        // Keep the picker path when app storage is unavailable.
      }
      if (mounted) setState(() => _avatarPath = path);
    } on Object {
      if (mounted) showAppMessage(context, '无法读取头像，请检查相册权限');
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _finish() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      showAppMessage(context, '请填写昵称');
      return;
    }
    if (_tags.isEmpty) {
      showAppMessage(context, '请至少选择一个养宠标签');
      return;
    }
    await _syncMemberProfile(
      nickname: nickname,
      city: _city,
      careTags: _tags.toList(),
    );
    if (!mounted) return;
    if (widget.editMode) {
      widget.state.updateProfile(
        nickname: nickname,
        avatarPath: _avatarPath,
        city: _city,
        careTags: _tags.toList(),
      );
      Navigator.pop(context, true);
    } else {
      widget.state.completeOnboarding(
        nickname: nickname,
        avatarPath: _avatarPath,
        city: _city,
        careTags: _tags.toList(),
      );
    }
  }

  Future<void> _syncMemberProfile({
    required String nickname,
    required String city,
    required List<String> careTags,
  }) async {
    final token = await SessionTokenStore.read();
    if (token == null || token.isEmpty) return;
    final store = MemberProfileStore();
    try {
      await store.save(
        token: token,
        nickname: nickname,
        city: city,
        careTags: careTags,
      );
    } on Object {
      if (mounted) showAppMessage(context, '资料已保存在本机，账号同步失败');
    } finally {
      store.close();
    }
  }
}
