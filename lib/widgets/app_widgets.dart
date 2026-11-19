import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import 'animal_art.dart';
import 'layout_components.dart';

export 'layout_components.dart';
export 'media_components.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.canvas)),
        Positioned(
          top: -160,
          right: -130,
          child: Container(
            width: 390,
            height: 390,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xD9FFFFFF), Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -220,
          left: -170,
          child: Container(
            width: 460,
            height: 460,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0x9AD6DED6), Color(0x00D6DED6)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
  });

  final String eyebrow;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppText.body(
                    11.5,
                    color: AppColors.muted,
                    spacing: 0.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(title, style: AppText.display(29, height: 1.17)),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 14), action!],
        ],
      ),
    );
  }
}

class StackHeader extends StatelessWidget {
  const StackHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.action,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 36,
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.display(20))),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 42,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.33),
          side: const BorderSide(color: AppColors.hair),
        ),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(size * 0.33),
          onTap: onPressed,
          child: Icon(icon, size: size * 0.44, color: foreground),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.meta,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? meta;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: AppText.display(17.5)),
          if (meta != null) ...[
            const SizedBox(width: 9),
            Text(meta!, style: AppText.number(10.5, color: AppColors.faint)),
          ],
          const Spacer(),
          if (actionLabel != null)
            TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 16),
              label: Text(
                actionLabel!,
                style: AppText.body(11.5, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    this.icon,
    this.stats,
    this.padding = const EdgeInsets.all(20),
  });

  final String tag;
  final String title;
  final String description;
  final IconData? icon;
  final List<(String, String)>? stats;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF245646), Color(0xFF1A4237), Color(0xFF122D25)],
            stops: [0, 0.52, 1],
          ),
          border: Border.all(color: AppColors.brass2.withValues(alpha: 0.24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x54123027),
              blurRadius: 42,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -45,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brass2.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2678BEA5), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFFE4CB95),
                          size: 22,
                        ),
                      ),
                    ),
                  if (icon != null) const SizedBox(height: 4),
                  Text(
                    tag,
                    style: AppText.body(
                      9.5,
                      color: const Color(0xFFD9BE86),
                      weight: FontWeight.w700,
                      spacing: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(right: icon == null ? 0 : 42),
                    child: Text(
                      title,
                      style: AppText.display(
                        19,
                        color: const Color(0xFFF2EFE4),
                        height: 1.28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: AppText.body(
                      11.5,
                      color: const Color(0xFFF2EFE4).withValues(alpha: 0.68),
                      height: 1.75,
                    ),
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        for (var i = 0; i < stats!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stats![i].$1,
                                  style: AppText.body(
                                    9.2,
                                    color: const Color(0xFFD9BE86)
                                        .withValues(alpha: 0.72),
                                    weight: FontWeight.w600,
                                    spacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  stats![i].$2,
                                  style: AppText.display(
                                    16,
                                    color: const Color(0xFFF4F1E6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressOverviewCard extends StatelessWidget {
  const ProgressOverviewCard({
    super.key,
    required this.completed,
    required this.pending,
    required this.percent,
  });

  final int completed;
  final int pending;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending == 0 ? '今天的任务已完成' : '还有 $pending 项照护待完成',
                  style: AppText.display(17.5, height: 1.25),
                ),
                const SizedBox(height: 6),
                Text(
                  pending == 0
                      ? '$completed 项已完成，辛苦了'
                      : '$completed 项已完成，$pending 项待处理',
                  style: AppText.body(11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ProgressRing(percent: percent),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.percent, this.size = 74});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(progress: value),
              ),
              Text('$percent%', style: AppText.number(14.5)),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final track = Paint()
      ..color = AppColors.paper3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bar = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFFD8BC7F), Color(0xFFB69458), Color(0xFF8E7340)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, progress * 6.28318, false, bar);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 20,
    this.color = AppColors.paper,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.hair),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1415211C),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.pet,
    required this.onOpen,
  });

  final CareTask task;
  final PetProfile pet;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    final skipped = task.status == TaskStatus.skipped;
    final overdue = task.status == TaskStatus.pending && _taskIsOverdue(task);
    final tint = Color.lerp(AppColors.paper, pet.species.background, 0.24)!;
    final priorityLabel = task.priority == TaskPriority.must ? '必做' : '建议';
    final priorityColor = task.priority == TaskPriority.must
        ? AppColors.rose
        : AppColors.brass;
    final priorityWash = task.priority == TaskPriority.must
        ? AppColors.roseWash
        : AppColors.brassWash;
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: overdue
                  ? AppColors.rose.withValues(alpha: 0.62)
                  : pet.species.ink.withValues(alpha: 0.12),
              width: overdue ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: priorityWash,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  task.time,
                  style: AppText.number(
                    10.5,
                    color: overdue ? AppColors.rose : priorityColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: done || skipped ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label:
                            '$priorityLabel ${pet.name}：${task.type} ${task.title}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityWash,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    priorityLabel,
                                    style: AppText.body(
                                      8,
                                      color: priorityColor,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 92,
                                  ),
                                  child: Text(
                                    '${pet.name}：',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      11.5,
                                      color: pet.species.ink,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      13.5,
                                      weight: FontWeight.w700,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.faint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${task.type}：',
                                    style: AppText.body(
                                      10,
                                      color: AppColors.ink2,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: task.subtitle,
                                    style: AppText.body(
                                      10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }
}

bool _taskIsOverdue(CareTask task) {
  final pieces = task.time.split(':');
  final hour = pieces.isNotEmpty ? int.tryParse(pieces.first) ?? 23 : 23;
  final minute = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 59 : 59;
  final scheduled = DateTime(
    task.date.year,
    task.date.month,
    task.date.day,
    hour,
    minute,
  );
  return scheduled.isBefore(DateTime.now());
}

class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.pet, required this.onTap});

  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = pet.warning ? AppColors.amber : AppColors.brand;
    final statusWash = pet.warning ? AppColors.amberWash : AppColors.brandWash;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.hair),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1215211C),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: pet.species.gradient,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.06),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimalArt(species: pet.species, size: 34),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: AppText.display(19)),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.species.label} · ${pet.environment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusWash,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulseDot(
                          color: pet.warning
                              ? AppColors.amber
                              : const Color(0xFF3E8E6B),
                          size: 5,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          pet.status,
                          style: AppText.body(
                            10,
                            color: statusColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.hair),
              const SizedBox(height: 13),
              Row(
                children: [
                  LabeledMetric(label: '温度', value: pet.temperature),
                  _divider(),
                  LabeledMetric(label: '湿度', value: pet.humidity),
                  _divider(),
                  LabeledMetric(label: '体重', value: pet.weight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 11),
      color: AppColors.hair,
    );
  }
}

class PetMiniCard extends StatelessWidget {
  const PetMiniCard({super.key, required this.pet, required this.onTap});

  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 98,
          padding: const EdgeInsets.fromLTRB(10, 13, 10, 11),
          decoration: BoxDecoration(
            gradient: pet.species.gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimalArt(species: pet.species, size: 40),
              const SizedBox(height: 7),
              Text(pet.name, style: AppText.display(14.5)),
              const SizedBox(height: 3),
              Text(
                pet.species.label,
                style: AppText.body(10, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: EdgeInsets.zero,
      radius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title!.toUpperCase(),
                    style: AppText.body(
                      9.5,
                      color: AppColors.faint,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Container(height: 1, color: AppColors.hair),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.tone = MenuTone.neutral,
    this.leading,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final MenuTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      MenuTone.brand => (
        AppColors.brand,
        AppColors.brandWash,
        AppColors.brandLine,
      ),
      MenuTone.blue => (
        AppColors.blue,
        AppColors.blueWash,
        const Color(0xFFCFDEEA),
      ),
      MenuTone.amber => (
        AppColors.amber,
        AppColors.amberWash,
        const Color(0xFFEBD9BC),
      ),
      MenuTone.rose => (
        AppColors.rose,
        AppColors.roseWash,
        const Color(0xFFEBD0CB),
      ),
      MenuTone.neutral => (AppColors.ink2, AppColors.paper2, AppColors.hair),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.$2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: colors.$3),
              ),
              alignment: Alignment.center,
              child: leading ?? Icon(icon, size: 18, color: colors.$1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      13.5,
                      weight: FontWeight.w600,
                      spacing: -0.05,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: AppText.body(10.5, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: AppColors.faint,
            ),
          ],
        ),
      ),
    );
  }
}

enum MenuTone { neutral, brand, blue, amber, rose }

class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.message,
    this.type = CalloutType.info,
  });

  final String message;
  final CalloutType type;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (type) {
      CalloutType.info => (
        AppColors.brandWash,
        AppColors.brandLine,
        const Color(0xFF2C5748),
      ),
      CalloutType.warn => (
        AppColors.amberWash,
        const Color(0xFFEAD8BA),
        const Color(0xFF7A5520),
      ),
      CalloutType.danger => (
        AppColors.roseWash,
        const Color(0xFFEACFCA),
        const Color(0xFF8C4B45),
      ),
      CalloutType.neutral => (AppColors.paper2, AppColors.hair, AppColors.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(message, style: AppText.body(11.5, color: fg, height: 1.7)),
    );
  }
}

enum CalloutType { info, warn, danger, neutral }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.ghost = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool ghost;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ghost ? AppColors.paper : null,
          foregroundColor: ghost ? AppColors.ink2 : const Color(0xFFF4F1E6),
          disabledBackgroundColor: AppColors.faint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: ghost
                ? const BorderSide(color: AppColors.hair2)
                : BorderSide.none,
          ),
          textStyle: AppText.body(
            14,
            weight: FontWeight.w600,
            color: ghost ? AppColors.ink2 : const Color(0xFFF4F1E6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: icon == null ? null : Icon(icon, size: 17),
        label: Text(label),
      ),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(13, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppText.body(
                    10.5,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.brand,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.paper3,
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.brand
                  : AppColors.hair2,
            ),
          ),
        ],
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.body(
              9.5,
              color: AppColors.muted,
              weight: FontWeight.w700,
              spacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class BottomSelectOption<T> {
  const BottomSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
}

class BottomSelectField<T> extends StatelessWidget {
  const BottomSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.title = '请选择',
    this.icon,
  });

  final T value;
  final List<BottomSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final selected = options
        .where((option) => option.value == value)
        .firstOrNull;
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.hair),
      ),
      child: InkWell(
        onTap: () async {
          final result = await showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: const Color(0x70121C18),
            builder: (context) => _BottomPickerSheet<T>(
              title: title,
              selected: value,
              options: options,
            ),
          );
          if (result != null) onChanged(result);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.muted, size: 18),
                const SizedBox(width: 9),
              ],
              if (selected?.leading != null) ...[
                selected!.leading!,
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? '请选择',
                  style: AppText.body(13.5),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPickerSheet<T> extends StatelessWidget {
  const _BottomPickerSheet({
    required this.title,
    required this.selected,
    required this.options,
  });

  final String title;
  final T selected;
  final List<BottomSelectOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.68,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hair2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 16, 10),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AppText.display(20))),
                RoundIconButton(
                  icon: Icons.close_rounded,
                  size: 32,
                  onPressed: () => Navigator.pop(context),
                  foreground: AppColors.muted,
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom + 18,
              ),
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final option = options[index];
                final active = option.value == selected;
                return Material(
                  color: active ? AppColors.brandWash : AppColors.paper2,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option.value),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          if (option.leading != null) ...[
                            option.leading!,
                            const SizedBox(width: 11),
                          ] else if (option.icon != null) ...[
                            Icon(
                              option.icon,
                              size: 20,
                              color: active ? AppColors.brand : AppColors.muted,
                            ),
                            const SizedBox(width: 11),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: AppText.body(
                                    13.5,
                                    color: active
                                        ? AppColors.brand
                                        : AppColors.ink,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                if (option.subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    option.subtitle!,
                                    style: AppText.body(
                                      10.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (active)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.brand,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hair),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected == i ? AppColors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected == i
                        ? const [
                            BoxShadow(
                              color: Color(0x1715211C),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: selected == i
                        ? Border.all(color: AppColors.hair)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: AppText.body(
                      12.5,
                      color: selected == i ? AppColors.brand : AppColors.muted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final label = labels[index];
          final active = selected == label;
          return GestureDetector(
            onTap: () => onChanged(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: active ? AppColors.brand : AppColors.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.brand : AppColors.hair,
                ),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x4D1D4A3D),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppText.body(
                  11.5,
                  color: active ? const Color(0xFFF3F1E6) : AppColors.muted,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.pets_outlined, Icons.pets_rounded, '动物'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, '任务'),
    (Icons.person_outline_rounded, Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppColors.hair)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1415211C),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: currentIndex == i ? items[i].$2 : items[i].$1,
                        label: items[i].$3,
                        active: currentIndex == i,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: active ? AppColors.brandWash : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: active ? AppColors.brand : AppColors.faint,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: AppText.body(
                    10,
                    color: active ? AppColors.brand : AppColors.faint,
                    weight: FontWeight.w600,
                    spacing: 0.3,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: active ? 1 : 0,
                child: Container(
                  width: 25,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.brass,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.footer,
    this.maxHeightFactor = 0.92,
    this.shrinkToContent = true,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final double maxHeightFactor;
  final bool shrinkToContent;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - bottomInset;
    final sheet = Material(
      color: AppColors.paper,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: shrinkToContent ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hair2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 16, 14),
            child: Row(
              children: [
                Expanded(child: Text(title, style: AppText.display(21))),
                RoundIconButton(
                  icon: Icons.close_rounded,
                  size: 32,
                  onPressed: () => Navigator.pop(context),
                  foreground: AppColors.muted,
                ),
              ],
            ),
          ),
          if (shrinkToContent)
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  footer == null ? 28 : 16,
                ),
                child: child,
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  footer == null ? 28 : 16,
                ),
                child: child,
              ),
            ),
          if (footer != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.paddingOf(context).bottom + 18,
              ),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.hair)),
              ),
              child: footer,
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: shrinkToContent
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableHeight * maxHeightFactor,
              ),
              child: sheet,
            )
          : SizedBox(height: availableHeight * maxHeightFactor, child: sheet),
    );
  }
}

class HourMinutePicker extends StatefulWidget {
  const HourMinutePicker({
    super.key,
    required this.initialTime,
    required this.onChanged,
    this.height = 180,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;
  final double height;

  @override
  State<HourMinutePicker> createState() => _HourMinutePickerState();
}

class _HourMinutePickerState extends State<HourMinutePicker> {
  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(initialItem: widget.initialTime.hour);
  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: widget.initialTime.minute);
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const itemExtent = 44.0;
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: (widget.height - itemExtent) / 2,
            height: itemExtent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: const Border.symmetric(
                  horizontal: BorderSide(color: AppColors.hair),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _numberWheel(
                  controller: _hourController,
                  count: 24,
                  selected: _hour,
                  onSelected: (value) {
                    setState(() => _hour = value);
                    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
                  },
                ),
              ),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    '：',
                    style: AppText.number(
                      21,
                      color: AppColors.ink2,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _numberWheel(
                  controller: _minuteController,
                  count: 60,
                  selected: _minute,
                  onSelected: (value) {
                    setState(() => _minute = value);
                    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberWheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 44,
      useMagnifier: true,
      magnification: 1.08,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onSelected,
      children: [
        for (var value = 0; value < count; value++)
          Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: AppText.number(
                22,
                color: value == selected ? AppColors.ink : AppColors.muted,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hair2),
      ),
      child: Column(
        children: [
          Text(title, style: AppText.display(15.5)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class FirstPetPrompt extends StatelessWidget {
  const FirstPetPrompt({
    super.key,
    required this.onAddPet,
    this.guestMode = false,
  });

  final VoidCallback onAddPet;
  final bool guestMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.paper, AppColors.brandWash],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1415211C),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: PetSpecies.gecko.gradient,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            ),
            alignment: Alignment.center,
            child: const AnimalArt(species: PetSpecies.gecko, size: 56),
          ),
          const SizedBox(height: 15),
          Text('先认识你的第一位伙伴', style: AppText.display(19)),
          const SizedBox(height: 6),
          Text(
            guestMode
                ? '游客最多可添加 3 只动物，数据会在 3 天后清理。'
                : '添加动物档案后，首页和任务会自动生成适合它的照护计划。',
            textAlign: TextAlign.center,
            style: AppText.body(11, color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '添加第一只动物',
            icon: Icons.add_rounded,
            expand: false,
            onPressed: onAddPet,
          ),
        ],
      ),
    );
  }
}

void showAppMessage(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _showTopMessage(overlay, message);
}

void showUndoableTaskMessage(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _showTopMessage(
    overlay,
    message,
    actionLabel: '撤销',
    onAction: onUndo,
    duration: const Duration(seconds: 4),
  );
}

void showAppMessageAndPop(
  BuildContext context,
  String message, {
  VoidCallback? afterPop,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  Navigator.pop(context);
  afterPop?.call();
  if (overlay != null) _showTopMessage(overlay, message);
}

OverlayEntry? _activeTopMessage;
Timer? _topMessageTimer;

void _dismissTopMessage() {
  _topMessageTimer?.cancel();
  _topMessageTimer = null;
  final entry = _activeTopMessage;
  _activeTopMessage = null;
  if (entry != null && entry.mounted) entry.remove();
}

void _showTopMessage(
  OverlayState overlay,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 1900),
}) {
  _dismissTopMessage();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final top = MediaQuery.paddingOf(context).top + 10;
      return Positioned(
        top: top,
        left: 20,
        right: 20,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _TopMessageBanner(
              message: message,
              actionLabel: actionLabel,
              onAction: onAction == null
                  ? null
                  : () {
                      _dismissTopMessage();
                      onAction();
                    },
            ),
          ),
        ),
      );
    },
  );
  _activeTopMessage = entry;
  overlay.insert(entry);
  _topMessageTimer = Timer(duration, _dismissTopMessage);
}

class _TopMessageBanner extends StatelessWidget {
  const _TopMessageBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: AppColors.ink.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        elevation: 10,
        shadowColor: const Color(0x5515211C),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.brass2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body(
                    12,
                    color: const Color(0xFFF2EFE4),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brass2,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppText.body(
                      11.5,
                      color: AppColors.brass2,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAppSheet({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x70121C18),
    builder: (context) => child,
  );
}
