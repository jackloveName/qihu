import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/agreement_service.dart';
import '../widgets/app_widgets.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({
    super.key,
    required this.protocolKey,
    required this.title,
  });

  final String protocolKey;
  final String title;

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  final _service = AgreementService();
  late Future<String> _content = _service.fetch(widget.protocolKey);

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _content = _service.fetch(widget.protocolKey, forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: PagePadding(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: StackHeader(title: widget.title, subtitle: '服务端最新版本'),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<String>(
                    future: _content,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const PaperCard(
                          padding: EdgeInsets.symmetric(vertical: 56),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snapshot.hasError ||
                          snapshot.data?.trim().isEmpty != false) {
                        return _AgreementError(onRetry: _retry);
                      }
                      return PaperCard(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                        child: SelectableText(
                          snapshot.data!,
                          style: AppText.body(
                            12,
                            color: AppColors.ink2,
                            height: 1.85,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementError extends StatelessWidget {
  const _AgreementError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 30,
            color: AppColors.brand,
          ),
          const SizedBox(height: 12),
          Text('协议内容加载失败', style: AppText.display(17)),
          const SizedBox(height: 6),
          Text('请检查网络后重新加载', style: AppText.body(11.5, color: AppColors.muted)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '重新加载',
            icon: Icons.refresh_rounded,
            expand: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
