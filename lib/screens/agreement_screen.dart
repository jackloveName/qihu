import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/api/api_settings.dart';
import '../services/agreement_service.dart';
import '../widgets/app_widgets.dart';

class AgreementsScreen extends StatelessWidget {
  const AgreementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: StackHeader(
                    title: '隐私政策与注册协议',
                    subtitle: '隐私政策 · 平台注册协议',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.hair),
                    ),
                    child: TabBar(
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.brandLine),
                      ),
                      labelColor: AppColors.brand,
                      unselectedLabelColor: AppColors.muted,
                      labelStyle: AppText.body(
                        12,
                        color: AppColors.brand,
                        weight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: AppText.body(
                        12,
                        color: AppColors.muted,
                        weight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: '隐私政策'),
                        Tab(text: '平台注册协议'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _AgreementTabContent(
                        protocolKey: ApiSettings.privacyProtocolKey,
                        title: '隐私政策',
                      ),
                      _AgreementTabContent(
                        protocolKey: ApiSettings.registerProtocolKey,
                        title: '平台注册协议',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgreementTabContent extends StatefulWidget {
  const _AgreementTabContent({required this.protocolKey, required this.title});

  final String protocolKey;
  final String title;

  @override
  State<_AgreementTabContent> createState() => _AgreementTabContentState();
}

class _AgreementTabContentState extends State<_AgreementTabContent> {
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          sliver: SliverToBoxAdapter(
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
                  return _AgreementError(
                    title: '${widget.title}加载失败',
                    onRetry: _retry,
                  );
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
        ),
      ],
    );
  }
}

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
  const _AgreementError({required this.onRetry, this.title = '协议内容加载失败'});

  final VoidCallback onRetry;
  final String title;

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
          Text(title, style: AppText.display(17)),
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
