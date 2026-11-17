import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../services/agreement_page_launcher.dart';
import '../services/agreement_service.dart';
import '../storage/privacy_consent_store.dart';
import '../widgets/app_widgets.dart';
import 'agreement_screen.dart';

class PrivacyGate extends StatefulWidget {
  const PrivacyGate({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  bool _loading = true;
  bool _accepted = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var accepted = false;
    try {
      accepted = await PrivacyConsentStore.hasCurrentConsent();
    } on Object {
      accepted = false;
    }
    if (!mounted) return;
    setState(() {
      _accepted = accepted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_accepted) return widget.child;
    return Scaffold(
      key: const ValueKey('privacy-consent-dialog'),
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2E15211C),
                        blurRadius: 34,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.pets_rounded,
                          size: 34,
                          color: Color(0xFFF4F1E6),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        '服务协议和隐私政策',
                        style: AppText.display(22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '开始使用前，请阅读并同意以下内容',
                        style: AppText.body(11.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      MenuGroup(
                        children: [
                          MenuRow(
                            icon: Icons.shield_outlined,
                            title: '隐私政策',
                            subtitle: '了解个人信息如何被保护',
                            tone: MenuTone.brand,
                            onTap: () => _openAgreement(isPrivacy: true),
                          ),
                          MenuRow(
                            icon: Icons.description_outlined,
                            title: '平台注册协议',
                            subtitle: '查看平台服务与使用规范',
                            tone: MenuTone.amber,
                            onTap: () => _openAgreement(isPrivacy: false),
                          ),
                        ],
                      ),
                      if (_blocked) ...[
                        const SizedBox(height: 12),
                        const Callout(
                          type: CalloutType.warn,
                          message: '需要同意两份协议后才能继续使用。',
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: '暂不同意',
                              ghost: true,
                              onPressed: _refuse,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: PrimaryButton(
                              label: '同意',
                              onPressed: _accept,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _accept() async {
    try {
      await PrivacyConsentStore.accept();
      if (mounted) setState(() => _accepted = true);
    } on Object {
      if (mounted) setState(() => _blocked = true);
    }
  }

  Future<void> _refuse() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('确认暂不同意', style: AppText.display(20)),
        content: Text(
          '不同意协议将无法进入栖护。你可以继续阅读，或确认暂不使用。',
          style: AppText.body(12.5, color: AppColors.muted, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续阅读'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('暂不使用'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await SystemNavigator.pop();
      return;
    }
    setState(() => _blocked = true);
  }

  Future<void> _openAgreement({required bool isPrivacy}) async {
    final key = isPrivacy
        ? AgreementService.privacyKey
        : AgreementService.registerKey;
    if (await AgreementPageLauncher.open(key) || !mounted) return;
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
