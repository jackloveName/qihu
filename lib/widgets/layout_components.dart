import 'package:flutter/material.dart';

import '../app_theme.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.hair)),
        ),
        child: child,
      ),
    );
  }
}

class GuestModeCard extends StatelessWidget {
  const GuestModeCard({
    super.key,
    required this.message,
    required this.onLogin,
  });

  final String message;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C654F), Color(0xFF173D32)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30123027),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -28,
            child: Icon(
              Icons.pets_rounded,
              size: 108,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.brass2.withValues(alpha: 0.34),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 21,
                    color: Color(0xFFE0C48D),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '游客模式 · 登录后继续使用',
                        style: AppText.body(
                          12,
                          color: const Color(0xFFF4F1E6),
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: AppText.body(
                          9.5,
                          color: const Color(0xFFF2EFE4)
                              .withValues(alpha: 0.68),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF173D32),
                    backgroundColor: const Color(0xFFE0C48D),
                    minimumSize: const Size(70, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('去登录'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledMetric extends StatelessWidget {
  const LabeledMetric({
    super.key,
    required this.label,
    required this.value,
    this.expand = true,
    this.uppercaseLabel = false,
    this.labelSize = 9.5,
    this.valueSize = 14,
    this.labelColor = AppColors.faint,
    this.valueColor = AppColors.ink,
    this.labelWeight = FontWeight.w600,
    this.valueWeight = FontWeight.w600,
    this.spacing = 0.5,
  });

  final String label;
  final String value;
  final bool expand;
  final bool uppercaseLabel;
  final double labelSize;
  final double valueSize;
  final Color labelColor;
  final Color valueColor;
  final FontWeight labelWeight;
  final FontWeight valueWeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final metric = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uppercaseLabel ? label.toUpperCase() : label,
          style: AppText.body(
            labelSize,
            color: labelColor,
            weight: labelWeight,
            spacing: spacing,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppText.number(
            valueSize,
            color: valueColor,
            weight: valueWeight,
          ),
        ),
      ],
    );
    return expand ? Expanded(child: metric) : metric;
  }
}
