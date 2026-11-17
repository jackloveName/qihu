import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_theme.dart';
import '../date_utils.dart';
import '../knowledge_content.dart';
import '../models.dart';
import '../services/api/api_settings.dart';
import '../services/auth_service.dart';
import '../storage/session_token_store.dart';
import '../weather_service.dart';
import 'agreement_screen.dart';
import 'auth_screens.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';

typedef PetOpenCallback = void Function(String petId);
typedef TaskOpenCallback = void Function(CareTask task);

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.state,
    required this.onOpenTask,
    required this.onOpenKnowledge,
  });

  final AppState state;
  final TaskOpenCallback onOpenTask;
  final VoidCallback onOpenKnowledge;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingTasks;
    final completed =
        state.todayTasks
            .where((task) => task.status == TaskStatus.done)
            .toList()
          ..sort((a, b) {
            final aTime = a.latestRun?.performedAt ?? _taskDateTime(a);
            final bTime = b.latestRun?.performedAt ?? _taskDateTime(b);
            return bTime.compareTo(aTime);
          });
    final allDone = pending.isEmpty && completed.isNotEmpty;
    final completedForHome = completed.take(10).toList();
    final tasks = pending.take(5).toList();
    final tomorrow = PetDates.dateOnly().add(const Duration(days: 1));
    final tomorrowTasks =
        state.tasks
            .where(
              (task) =>
                  task.status == TaskStatus.pending &&
                  task.date.year == tomorrow.year &&
                  task.date.month == tomorrow.month &&
                  task.date.day == tomorrow.day,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final tomorrowFirst = tomorrowTasks.firstOrNull;
    return PagePadding(
      child: CustomScrollView(
        key: const PageStorageKey('today-scroll'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 14),
              child: _WeatherCard(state: state, city: state.city),
            ),
          ),
          SliverToBoxAdapter(
            child: _DailyKnowledgeCard(onTap: onOpenKnowledge),
          ),
          if (allDone)
            SliverToBoxAdapter(
              child: _CompletedTodaySection(
                tasks: completedForHome,
                state: state,
                onOpenTask: onOpenTask,
                tomorrowFirst: tomorrowFirst,
              ),
            )
          else ...[
            const SliverToBoxAdapter(child: _NextTasksHeader(title: '接下来要做')),
            if (tasks.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  title: '今天的照护已完成',
                  message: '可以去任务页查看今天的执行记录。',
                ),
              )
            else
              SliverList.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskTile(
                      task: task,
                      pet: state.petById(task.petId),
                      onOpen: () => onOpenTask(task),
                      onToggle: () => _toggleTask(context, task),
                    ),
                  );
                },
              ),
            if (completed.isNotEmpty)
              SliverToBoxAdapter(
                child: _CompletedTodaySection(
                  tasks: completedForHome,
                  state: state,
                  onOpenTask: onOpenTask,
                  tomorrowFirst: null,
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 92)),
        ],
      ),
    );
  }

  void _toggleTask(BuildContext context, CareTask task) {
    final wasDone = task.status == TaskStatus.done;
    state.toggleTask(task.id);
    if (wasDone) {
      showAppMessage(context, '已恢复为待完成');
    } else {
      showUndoableTaskMessage(
        context,
        '任务已完成，已记录执行时间',
        onUndo: () => state.reopenTask(task.id),
      );
    }
  }
}

class _NextTasksHeader extends StatelessWidget {
  const _NextTasksHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(title, style: AppText.display(17.5)),
    );
  }
}

class _CompletedTodaySection extends StatefulWidget {
  const _CompletedTodaySection({
    required this.tasks,
    required this.state,
    required this.onOpenTask,
    required this.tomorrowFirst,
  });

  final List<CareTask> tasks;
  final AppState state;
  final TaskOpenCallback onOpenTask;
  final CareTask? tomorrowFirst;

  @override
  State<_CompletedTodaySection> createState() => _CompletedTodaySectionState();
}

class _CompletedTodaySectionState extends State<_CompletedTodaySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleCount = _expanded || widget.tasks.length <= 5
        ? widget.tasks.length
        : 5;
    final visibleTasks = widget.tasks.take(visibleCount).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _NextTasksHeader(title: '今天已完成'),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (final task in visibleTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompletedTodayTask(
                    task: task,
                    pet: widget.state.petById(task.petId),
                    onTap: () => widget.onOpenTask(task),
                  ),
                ),
            ],
          ),
        ),
        if (widget.tasks.length > 5)
          Center(
            child: TextButton.icon(
              key: const ValueKey('completed-list-toggle'),
              onPressed: () => setState(() => _expanded = !_expanded),
              iconAlignment: IconAlignment.end,
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 17,
              ),
              label: Text(_expanded ? '收起' : '展开'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        if (widget.tomorrowFirst != null)
          _TomorrowFirstTask(
            task: widget.tomorrowFirst!,
            pet: widget.state.petById(widget.tomorrowFirst!.petId),
            onTap: () => widget.onOpenTask(widget.tomorrowFirst!),
          ),
      ],
    );
  }
}

class _CompletedTodayTask extends StatelessWidget {
  const _CompletedTodayTask({
    required this.task,
    required this.pet,
    required this.onTap,
  });

  final CareTask task;
  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completedAt = task.latestRun?.performedAt ?? _taskDateTime(task);
    return Material(
      key: ValueKey('completed-home-task-${task.id}'),
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.hair),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  gradient: pet.species.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AnimalArt(species: pet.species, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: AppText.body(
                        9.5,
                        color: AppColors.faint,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        12.5,
                        color: AppColors.ink2,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                PetDates.clock(completedAt),
                style: AppText.number(
                  9.5,
                  color: AppColors.muted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.brand2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TomorrowFirstTask extends StatelessWidget {
  const _TomorrowFirstTask({
    required this.task,
    required this.pet,
    required this.onTap,
  });

  final CareTask task;
  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('tomorrow-first-task'),
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: AppColors.brass,
                ),
                const SizedBox(width: 7),
                Text(
                  '明天第一项',
                  style: AppText.body(
                    9.5,
                    color: AppColors.brass,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${pet.name} · ${task.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(10.5, color: AppColors.ink2),
                  ),
                ),
                Text(
                  task.time,
                  style: AppText.number(
                    9.5,
                    color: AppColors.muted,
                    weight: FontWeight.w600,
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

class _WeatherCard extends StatefulWidget {
  const _WeatherCard({required this.state, required this.city});

  final AppState state;
  final String city;

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  WeatherSnapshot? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final weather = await WeatherService.fetchForCity(widget.city);
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _loading = false;
    });
  }

  Future<void> _pickCity() async {
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text('选择天气城市', style: AppText.display(20))),
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
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MediaQuery.paddingOf(context).bottom + 18,
                ),
                children: [
                  for (final option in AppState.availableCities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: MenuRow(
                        icon: Icons.location_on_outlined,
                        title: option,
                        tone: option == widget.city
                            ? MenuTone.brand
                            : MenuTone.amber,
                        onTap: () => Navigator.pop(context, option),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (city != null) widget.state.updateCity(city);
  }

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final headline = _loading ? '正在获取天气' : weather?.headline ?? '暂时无法获取天气';
    final description = _loading
        ? '正在读取 ${widget.city} 的天气。'
        : weather?.description ?? '点击卡片重新获取，或更换天气城市。';
    return Material(
      key: const ValueKey('weather-card'),
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _load,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B614E), Color(0xFF173D32)],
            ),
            border: Border.all(color: AppColors.brass2.withValues(alpha: 0.22)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E173D32),
                blurRadius: 24,
                offset: Offset(0, 13),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(19, 17, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _loading ? Icons.cloud_outlined : _weatherIcon(weather),
                      size: 18,
                      color: const Color(0xFFD5BE8C),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'WEATHER · 天气',
                      style: AppText.body(
                        9.5,
                        color: const Color(0xFFD5BE8C),
                        weight: FontWeight.w700,
                        spacing: 1,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      key: const ValueKey('weather-city-button'),
                      onTap: _pickCity,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          widget.city.split('·').first.trim(),
                          style: AppText.body(
                            9,
                            color: const Color(0xFFE6E2D6),
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  headline,
                  style: AppText.display(
                    24,
                    color: const Color(0xFFF6F1E5),
                    height: 1.27,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppText.body(
                    11.5,
                    color: const Color(0xFFE6E2D6).withValues(alpha: 0.64),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _weatherIcon(WeatherSnapshot? weather) {
    if (weather == null) return Icons.cloud_off_outlined;
    if (weather.condition.contains('雨')) return Icons.water_drop_outlined;
    if (weather.condition.contains('雪')) return Icons.ac_unit_rounded;
    if (weather.condition.contains('阴')) return Icons.cloud_outlined;
    if (weather.condition.contains('云')) return Icons.wb_cloudy_outlined;
    return Icons.wb_sunny_outlined;
  }
}

class LegacyNextActionCard extends StatelessWidget {
  const LegacyNextActionCard({
    super.key,
    required this.task,
    required this.pet,
    required this.overdue,
    required this.onOpen,
    required this.onToggle,
  });

  final CareTask task;
  final PetProfile pet;
  final bool overdue;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('home-next-action-card'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B614E), Color(0xFF173D32)],
            ),
            border: Border.all(
              color: overdue
                  ? AppColors.rose.withValues(alpha: 0.54)
                  : AppColors.brass2.withValues(alpha: 0.22),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E173D32),
                blurRadius: 24,
                offset: Offset(0, 13),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 15,
                      color: Color(0xFFD5BE8C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      overdue ? 'OVERDUE CARE · 待补记' : 'NEXT CARE · 下一步照护',
                      style: AppText.body(
                        9.5,
                        color: const Color(0xFFD5BE8C),
                        weight: FontWeight.w700,
                        spacing: 0.9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: pet.species.gradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: AnimalArt(species: pet.species, size: 33),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pet.name}：${task.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display(
                              20,
                              color: const Color(0xFFF6F1E5),
                              height: 1.32,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              10.5,
                              color: const Color(0xFFE6E2D6)
                                  .withValues(alpha: 0.58),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(
                      task.time,
                      style: AppText.number(
                        15,
                        color: overdue
                            ? const Color(0xFFF0B7AE)
                            : const Color(0xFFD5BE8C),
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      task.priority == TaskPriority.must ? '必做' : '建议',
                      style: AppText.body(
                        9.5,
                        color: const Color(0xFFE6E2D6).withValues(alpha: 0.58),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: '完成任务',
                      child: InkWell(
                        key: const ValueKey('next-action-complete-button'),
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          width: 64,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F5EC),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color(0xFFD5BE8C)
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                          child: Text(
                            '完成',
                            style: AppText.body(
                              11,
                              color: AppColors.brand,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegacyAttentionPetCard extends StatelessWidget {
  const LegacyAttentionPetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final signal = pet.logs
        .where(
          (entry) => entry.riskLevel != 'normal' || entry.followUpAt != null,
        )
        .firstOrNull;
    final description = pet.status != '状态良好'
        ? pet.status
        : (signal?.title ?? '有健康记录需要复看');
    return Material(
      key: const ValueKey('home-attention-card'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A5B4B), Color(0xFF16382E)],
            ),
            border: Border.all(color: AppColors.rose.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E173D32),
                blurRadius: 24,
                offset: Offset(0, 13),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: pet.species.gradient,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            size: 15,
                            color: Color(0xFFE3B8AE),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ATTENTION · 需要关注',
                            style: AppText.body(
                              9,
                              color: const Color(0xFFE3B8AE),
                              weight: FontWeight.w700,
                              spacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.name,
                        style: AppText.display(
                          21,
                          color: const Color(0xFFF6F1E5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          10.5,
                          color: const Color(0xFFE6E2D6)
                              .withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD5BE8C),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegacyPetStatusStrip extends StatelessWidget {
  const LegacyPetStatusStrip({
    super.key,
    required this.pets,
    required this.onOpenPet,
  });

  final List<PetProfile> pets;
  final PetOpenCallback onOpenPet;

  @override
  Widget build(BuildContext context) {
    final shown = pets.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('宠物状态', style: AppText.display(16)),
        const SizedBox(height: 9),
        Row(
          children: [
            for (var index = 0; index < shown.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(
                child: _PetStatusItem(
                  pet: shown[index],
                  onTap: () => onOpenPet(shown[index].id),
                ),
              ),
            ],
            if (pets.length > shown.length) ...[
              const SizedBox(width: 7),
              Container(
                width: 42,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '+${pets.length - shown.length}',
                  style: AppText.number(10, color: AppColors.muted),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PetStatusItem extends StatelessWidget {
  const _PetStatusItem({required this.pet, required this.onTap});

  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attention = _needsAttention(pet);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: attention
                ? AppColors.amber.withValues(alpha: 0.4)
                : AppColors.hair,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: pet.species.gradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AnimalArt(species: pet.species, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(9, weight: FontWeight.w600),
            ),
            Text(
              attention ? '需关注' : '良好',
              maxLines: 1,
              style: AppText.body(
                7.5,
                color: attention ? AppColors.amber : AppColors.brand2,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegacyQuickRecordRow extends StatelessWidget {
  const LegacyQuickRecordRow({
    super.key,
    required this.onFeed,
    required this.onWater,
    required this.onHealth,
  });

  final VoidCallback onFeed;
  final VoidCallback onWater;
  final VoidCallback onHealth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快速记录', style: AppText.display(16)),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _QuickRecordButton(
                key: const ValueKey('quick-feed'),
                icon: Icons.restaurant_outlined,
                label: '喂食',
                onTap: onFeed,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickRecordButton(
                key: const ValueKey('quick-water'),
                icon: Icons.water_drop_outlined,
                label: '饮水 / 换水',
                onTap: onWater,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickRecordButton(
                key: const ValueKey('quick-health'),
                icon: Icons.health_and_safety_outlined,
                label: '健康观察',
                onTap: onHealth,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickRecordButton extends StatelessWidget {
  const _QuickRecordButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.hair),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.brand),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  9,
                  color: AppColors.ink2,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegacyAllDoneCard extends StatelessWidget {
  const LegacyAllDoneCard({
    super.key,
    required this.completedTasks,
    required this.state,
  });

  final List<CareTask> completedTasks;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pets = <PetProfile>[];
    final seen = <String>{};
    for (final task in completedTasks) {
      if (seen.add(task.petId)) pets.add(state.petById(task.petId));
    }
    return Container(
      key: const ValueKey('all-done-card'),
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF326A57), Color(0xFF173D32)],
        ),
        border: Border.all(color: AppColors.brass2.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E173D32),
            blurRadius: 24,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: Color(0xFFD5BE8C),
              ),
              const SizedBox(width: 7),
              Text(
                'ALL DONE · 今日收尾',
                style: AppText.body(
                  9.5,
                  color: const Color(0xFFD5BE8C),
                  weight: FontWeight.w700,
                  spacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '今天的照护已完成',
            style: AppText.display(
              23,
              color: const Color(0xFFF6F1E5),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '需要做的事情都处理好了，留一点时间陪陪它们。',
            style: AppText.body(
              11.5,
              color: const Color(0xFFE6E2D6).withValues(alpha: 0.66),
              height: 1.55,
            ),
          ),
          if (pets.isNotEmpty) ...[
            const SizedBox(height: 15),
            SizedBox(
              height: 34,
              child: Stack(
                children: [
                  for (var index = 0; index < pets.length; index++)
                    Positioned(
                      left: index * 23,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: pets[index].species.gradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF245044),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AnimalArt(
                          species: pets[index].species,
                          size: 21,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LegacyTodayFootprint extends StatelessWidget {
  const LegacyTodayFootprint({
    super.key,
    required this.tasks,
    required this.state,
  });

  final List<CareTask> tasks;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('today-footprint'),
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日足迹', style: AppText.display(16.5)),
          const SizedBox(height: 9),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var index = 0; index < tasks.length; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.hair),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: state
                                .petById(tasks[index].petId)
                                .species
                                .gradient,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: AnimalArt(
                            species: state.petById(tasks[index].petId).species,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.petById(tasks[index].petId).name,
                                style: AppText.body(
                                  9.5,
                                  color: AppColors.faint,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                tasks[index].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  12.5,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          PetDates.clock(
                            tasks[index].latestRun?.performedAt ??
                                _taskDateTime(tasks[index]),
                          ),
                          style: AppText.number(
                            10,
                            color: AppColors.muted,
                            weight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: AppColors.brand2,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyKnowledgeCard extends StatelessWidget {
  const _DailyKnowledgeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final article = knowledgeArticles[dayOfYear % knowledgeArticles.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text('每日知识', style: AppText.display(16)),
        ),
        Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            key: const ValueKey('daily-knowledge'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hair),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: article.species.gradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimalArt(species: article.species, size: 31),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: AppText.display(15.5, height: 1.35),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          article.subtitle,
                          style: AppText.body(9.5, color: AppColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.sections.first.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            10,
                            color: AppColors.faint,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.faint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({
    super.key,
    required this.state,
    required this.onOpenPet,
    required this.onAddPet,
  });

  final AppState state;
  final PetOpenCallback onOpenPet;
  final VoidCallback onAddPet;

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.state.pets.where((pet) {
      return query.isEmpty || pet.name.toLowerCase().contains(query);
    }).toList();
    filtered.sort((a, b) {
      final aAttention = _needsAttention(a);
      final bAttention = _needsAttention(b);
      if (aAttention != bAttention) return aAttention ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return Stack(
      children: [
        Positioned.fill(
          child: PagePadding(
            child: CustomScrollView(
              key: const PageStorageKey('animals-scroll'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hair),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F15211C),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 17,
                          color: AppColors.faint,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: AppText.body(13.5),
                            decoration: const InputDecoration(
                              hintText: '搜索动物名称',
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.faint,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                if (filtered.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      title: '没有找到匹配的动物',
                      message: '换个关键词，或者新建一个档案。',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 14),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 196,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final pet = filtered[index];
                        return _CollectionAnimalCard(
                          pet: pet,
                          room: widget.state.roomById(pet.roomId),
                          onTap: () => widget.onOpenPet(pet.id),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 92)),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: widget.onAddPet,
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFFF4F1E6),
              elevation: 7,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.add_rounded, size: 23),
            ),
          ),
        ),
      ],
    );
  }
}

bool _needsAttention(PetProfile pet) {
  return pet.warning ||
      pet.logs.any(
        (entry) => entry.riskLevel != 'normal' || entry.followUpAt != null,
      );
}

class _HabitatTexturePainter extends CustomPainter {
  const _HabitatTexturePainter(this.species);

  final PetSpecies species;

  @override
  void paint(Canvas canvas, Size size) {
    final color = species.ink.withValues(alpha: 0.095);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()..color = color;

    switch (species.artStyle) {
      case 'gecko' || 'reptile' || 'tortoise' || 'snake':
        for (var index = 0; index < 7; index++) {
          final x = size.width * (0.12 + index * 0.14);
          final y = size.height * (0.2 + (index % 3) * 0.25);
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(-0.55 + index * 0.15);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 34, height: 13),
            stroke,
          );
          canvas.restore();
        }
      case 'cockatiel' || 'bird' || 'waterfowl':
        for (var x = 30.0; x < size.width; x += 34) {
          canvas.drawLine(Offset(x, 0), Offset(x - 22, size.height), stroke);
        }
        for (var index = 0; index < 4; index++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(size.width * .75, 18 + index * 20),
              radius: 28 + index * 8,
            ),
            math.pi,
            math.pi,
            false,
            stroke,
          );
        }
      case 'betta' || 'fish' || 'amphibian':
        for (var row = 0; row < 4; row++) {
          final path = Path();
          final y = 34.0 + row * 34;
          path.moveTo(0, y);
          for (var x = 0.0; x <= size.width; x += 12) {
            path.lineTo(x, y + math.sin((x / 28) + row) * 5);
          }
          canvas.drawPath(path, stroke);
        }
      case 'rabbit' || 'rodent' || 'hedgehog' || 'glider':
        for (var index = 0; index < 5; index++) {
          canvas.drawCircle(
            Offset(
              size.width * (0.18 + index * 0.17),
              size.height * (0.25 + (index % 2) * 0.38),
            ),
            24 + index * 3,
            stroke,
          );
        }
      case 'beardedDragon' || 'cat' || 'dog' || 'mustelid' || 'marsupial':
        for (var index = 0; index < 7; index++) {
          final path = Path()
            ..moveTo(index * 34.0, size.height)
            ..lineTo(index * 34.0 + 53, 0);
          canvas.drawPath(path, stroke);
        }
      case 'tarantula' || 'crustacean' || 'snail' || 'insect':
        final center = Offset(size.width * 0.76, size.height * 0.26);
        for (var index = 0; index < 12; index++) {
          final angle = index * math.pi / 6;
          canvas.drawLine(
            center,
            center + Offset(math.cos(angle), math.sin(angle)) * 96,
            stroke,
          );
        }
        canvas.drawCircle(center, 62, stroke);
    }

    for (var index = 0; index < 12; index++) {
      canvas.drawCircle(
        Offset((index * 47.0) % size.width, (index * 31.0) % size.height),
        1.1,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HabitatTexturePainter oldDelegate) {
    return oldDelegate.species != species;
  }
}

class _CollectionAnimalCard extends StatelessWidget {
  const _CollectionAnimalCard({
    required this.pet,
    required this.room,
    required this.onTap,
  });

  final PetProfile pet;
  final PetRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attention = _needsAttention(pet);
    final statusColor = attention ? AppColors.amber : AppColors.brand2;
    final genderBorder = _animalGenderBorderColor(pet.gender);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: pet.gender.isEmpty
                  ? (attention
                        ? AppColors.brass2.withValues(alpha: 0.4)
                        : AppColors.hair)
                  : genderBorder.withValues(alpha: attention ? 0.78 : 0.62),
              width: pet.gender.isEmpty ? 1 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F15211C),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: pet.species.gradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (pet.photos.isNotEmpty)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _AnimalPhoto(
                                path: pet.photos.first,
                                fallback: AnimalArt(
                                  species: pet.species,
                                  size: 79,
                                  color: pet.species.ink.withValues(
                                    alpha: 0.76,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CustomPaint(
                                painter: _HabitatTexturePainter(pet.species),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: AnimalArt(
                                  species: pet.species,
                                  size: 79,
                                  color: pet.species.ink.withValues(
                                    alpha: 0.76,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _companionDaysLabel(pet),
                              textAlign: TextAlign.center,
                              style: AppText.body(
                                8.5,
                                color: const Color(0xFFF7F2E5),
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _AnimalStatusBadge(
                                  label: attention ? '需关注' : '良好',
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    pet.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.display(17.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              room.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(8.4, color: AppColors.muted),
                            ),
                          ],
                        ),
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

class _AnimalStatusBadge extends StatelessWidget {
  const _AnimalStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: AppText.body(8.5, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

Color _animalGenderBorderColor(String gender) => switch (gender) {
  '雄性' => AppColors.blue,
  '雌性' => AppColors.rose,
  _ => Colors.white,
};

class _AnimalPhoto extends StatelessWidget {
  const _AnimalPhoto({required this.path, required this.fallback});

  final String path;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: XFile(path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: fallback);
        if (!snapshot.hasData) {
          return ColoredBox(
            color: AppColors.paper2,
            child: Center(child: fallback),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}

String _companionDaysLabel(PetProfile pet) {
  final startedAt = pet.startedAt;
  if (startedAt == null) return '刚刚开始陪伴';
  final days = DateTime.now().difference(startedAt).inDays.clamp(0, 99999);
  return '陪伴 $days 天';
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.state, required this.onOpenTask});

  final AppState state;
  final TaskOpenCallback onOpenTask;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late DateTime _selectedDate = PetDates.dateOnly();

  @override
  Widget build(BuildContext context) {
    final week = PetDates.currentWeek(_selectedDate);
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dayTasks =
        widget.state.tasks
            .where(
              (task) =>
                  task.date.year == _selectedDate.year &&
                  task.date.month == _selectedDate.month &&
                  task.date.day == _selectedDate.day,
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final completed = dayTasks
        .where((task) => task.status == TaskStatus.done)
        .length;
    final nextTask = dayTasks
        .where((task) => task.status == TaskStatus.pending)
        .firstOrNull;
    final overdue = dayTasks
        .where((task) => _isTaskOverdue(task, now))
        .toList();
    final dateTitle = isToday
        ? '今日日程'
        : '${_selectedDate.month} 月 ${_selectedDate.day} 日';

    return PagePadding(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _changeDateBySwipe,
        child: CustomScrollView(
          key: const PageStorageKey('tasks-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  for (var index = 0; index < week.length; index++) ...[
                    if (index > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _DayCell(
                        weekday: PetDates.weekday(week[index])
                            .replaceFirst('周', ''),
                        date: week[index].day,
                        selected:
                            _selectedDate.year == week[index].year &&
                            _selectedDate.month == week[index].month &&
                            _selectedDate.day == week[index].day,
                        onTap: () {
                          setState(() => _selectedDate = week[index]);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _TaskOverviewCard(
                  title: dateTitle,
                  nextTask: nextTask,
                  nextPet: nextTask == null
                      ? null
                      : widget.state.petById(nextTask.petId),
                  progress: dayTasks.isEmpty
                      ? 0
                      : ((completed / dayTasks.length) * 100).round(),
                ),
              ),
            ),
            if (overdue.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Callout(
                    type: CalloutType.warn,
                    message: '有 ${overdue.length} 项任务已过计划时间，可补记、完成或重新安排。',
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (dayTasks.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  title: '这个时间没有任务',
                  message: '可以去动物档案中新增一项养护任务。',
                ),
              )
            else
              SliverToBoxAdapter(
                child: _TaskTimeline(
                  tasks: dayTasks,
                  state: widget.state,
                  onToggle: (task) => _toggleTask(context, task),
                  onOpen: widget.onOpenTask,
                ),
              ),
            if (dayTasks.any((task) => task.status == TaskStatus.pending))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: _OneTapCompleteBar(
                    onPressed: () => _completeAll(dayTasks),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  void _changeDateBySwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 180) return;
    setState(() {
      _selectedDate = PetDates.dateOnly(
        _selectedDate.add(Duration(days: velocity < 0 ? 1 : -1)),
      );
    });
  }

  Future<void> _completeAll(List<CareTask> dayTasks) async {
    final pending = dayTasks
        .where((task) => task.status == TaskStatus.pending)
        .toList();
    if (pending.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('完成 ${pending.length} 项照护？', style: AppText.display(20)),
        content: Text(
          '确认后会将当前日期的待办任务全部标记为已完成，并记录本次执行时间。',
          style: AppText.body(12.5, color: AppColors.muted, height: 1.65),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: AppText.body(12, color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFFF4F1E6),
            ),
            child: const Text('确认完成'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    for (final task in pending) {
      widget.state.completeTask(task.id, note: '一键完成');
    }
    showUndoableTaskMessage(
      context,
      '已完成 ${pending.length} 项照护',
      onUndo: () {
        for (final task in pending) {
          widget.state.reopenTask(task.id);
        }
      },
    );
  }

  void _toggleTask(BuildContext context, CareTask task) {
    final wasDone = task.status == TaskStatus.done;
    widget.state.toggleTask(task.id);
    if (wasDone) {
      showAppMessage(context, '已恢复为待完成');
    } else {
      showUndoableTaskMessage(
        context,
        '任务已完成，已记录执行时间',
        onUndo: () => widget.state.reopenTask(task.id),
      );
    }
  }
}

class _OneTapCompleteBar extends StatelessWidget {
  const _OneTapCompleteBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(label: '一键完成', onPressed: onPressed);
  }
}

bool _isTaskOverdue(CareTask task, DateTime now) {
  if (task.status != TaskStatus.pending) return false;
  return _taskDateTime(task).isBefore(now);
}

DateTime _taskDateTime(CareTask task) {
  final pieces = task.time.split(':');
  final hour = pieces.isNotEmpty ? int.tryParse(pieces.first) ?? 23 : 23;
  final minute = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 59 : 59;
  return DateTime(task.date.year, task.date.month, task.date.day, hour, minute);
}

class _TaskOverviewCard extends StatelessWidget {
  const _TaskOverviewCard({
    required this.title,
    required this.nextTask,
    required this.nextPet,
    required this.progress,
  });

  final String title;
  final CareTask? nextTask;
  final PetProfile? nextPet;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final accent = nextPet?.species.ink ?? AppColors.brand;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hair),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1715211C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -20,
              child: Icon(
                Icons.pets_rounded,
                size: 112,
                color: accent.withValues(alpha: 0.045),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 16, 14, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.pets_rounded,
                          size: 17,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(title, style: AppText.display(21))),
                      ProgressRing(percent: progress, size: 54),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        AppColors.paper2,
                        nextPet?.species.background,
                        0.24,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (nextPet != null)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: nextPet!.species.gradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: AnimalArt(
                              species: nextPet!.species,
                              size: 20,
                            ),
                          )
                        else
                          Icon(
                            Icons.nightlight_round,
                            size: 18,
                            color: AppColors.brass,
                          ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            nextTask == null
                                ? '今天没有待完成任务，可以多陪陪它们。'
                                : '${nextPet?.name ?? '它们'}在等你 · '
                                      '${nextTask!.time} ${nextTask!.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              11.5,
                              color: AppColors.ink2,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTimeline extends StatelessWidget {
  const _TaskTimeline({
    required this.tasks,
    required this.state,
    required this.onToggle,
    required this.onOpen,
  });

  final List<CareTask> tasks;
  final AppState state;
  final ValueChanged<CareTask> onToggle;
  final TaskOpenCallback onOpen;

  @override
  Widget build(BuildContext context) {
    List<CareTask> groupTasks(bool Function(CareTask task) matches) {
      final result = tasks.where(matches).toList();
      result.sort((a, b) {
        final aDone = a.status == TaskStatus.done;
        final bDone = b.status == TaskStatus.done;
        if (aDone != bDone) return aDone ? 1 : -1;
        return _taskDateTime(a).compareTo(_taskDateTime(b));
      });
      return result;
    }

    final groups = [
      ('上午', groupTasks((task) => _taskDateTime(task).hour < 12)),
      (
        '下午',
        groupTasks(
          (task) =>
              _taskDateTime(task).hour >= 12 && _taskDateTime(task).hour < 18,
        ),
      ),
      ('晚上', groupTasks((task) => _taskDateTime(task).hour >= 18)),
    ];
    return Column(
      children: [
        for (var groupIndex = 0; groupIndex < groups.length; groupIndex++)
          if (groups[groupIndex].$2.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: groupIndex == 0 ? 0 : 16),
              child: _TimelineGroup(
                label: groups[groupIndex].$1,
                tasks: groups[groupIndex].$2,
                state: state,
                onToggle: onToggle,
                onOpen: onOpen,
              ),
            ),
      ],
    );
  }
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({
    required this.label,
    required this.tasks,
    required this.state,
    required this.onToggle,
    required this.onOpen,
  });

  final String label;
  final List<CareTask> tasks;
  final AppState state;
  final ValueChanged<CareTask> onToggle;
  final TaskOpenCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < tasks.length; index++) {
      final task = tasks[index];
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TaskTile(
            task: task,
            pet: state.petById(task.petId),
            onToggle: () => onToggle(task),
            onOpen: () => onOpen(task),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
          child: Row(
            children: [
              const Icon(Icons.pets_rounded, size: 13, color: AppColors.brass),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.body(
                  10,
                  color: AppColors.muted,
                  weight: FontWeight.w700,
                  spacing: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                '${tasks.length} 项',
                style: AppText.number(9.5, color: AppColors.faint),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.weekday,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final int date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandWash : AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandLine : AppColors.hair,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x141D4A3D),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.pets_rounded,
                    size: 8,
                    color: AppColors.brass,
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  '周$weekday',
                  style: AppText.body(
                    9.5,
                    color: selected ? AppColors.brand2 : AppColors.faint,
                    spacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$date',
              style: AppText.number(
                15,
                color: selected ? AppColors.brand : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.state, required this.onEdit});

  final AppState state;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF285B49), Color(0xFF1B4438), Color(0xFF112E25)],
          ),
          border: Border.all(color: AppColors.brass2.withValues(alpha: 0.24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x45123027),
              blurRadius: 34,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -90,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brass2.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: -20,
                child: Icon(
                  Icons.pets_rounded,
                  size: 108,
                  color: Colors.white.withValues(alpha: 0.035),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(19, 19, 17, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        StoredProfileAvatar(
                          path: state.avatarPath,
                          size: 66,
                          radius: 22,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.display(
                                  24,
                                  color: const Color(0xFFF4F1E6),
                                ),
                              ),
                              if (state.careTags.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  state.careTags.join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    9.5,
                                    color: const Color(0xFFD9BE86)
                                        .withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(11),
                          child: InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(11),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(
                                Icons.edit_outlined,
                                color: Color(0xFFD9BE86),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.11),
                    ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        _ProfileStat(
                          icon: Icons.pets_outlined,
                          value: '${state.pets.length}',
                          label: '只宠物',
                        ),
                        Container(
                          width: 1,
                          height: 27,
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        _ProfileStat(
                          icon: Icons.meeting_room_outlined,
                          value: '${state.rooms.length}',
                          label: '个饲养空间',
                        ),
                        const Spacer(),
                        _PetAvatarStack(pets: state.pets),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetAvatarStack extends StatelessWidget {
  const _PetAvatarStack({required this.pets});

  final List<PetProfile> pets;

  @override
  Widget build(BuildContext context) {
    final shown = pets.take(4).toList();
    return SizedBox(
      width: shown.isEmpty ? 0 : 24 + (shown.length - 1) * 18,
      height: 30,
      child: Stack(
        children: [
          for (var index = 0; index < shown.length; index++)
            Positioned(
              left: index * 18,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: shown[index].species.gradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF224C40), width: 2),
                ),
                alignment: Alignment.center,
                child: AnimalArt(species: shown[index].species, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD9BE86)),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppText.number(
            16,
            color: const Color(0xFFF4F1E6),
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.body(
            9,
            color: const Color(0xFFF2EFE4).withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class MineScreen extends StatelessWidget {
  const MineScreen({
    super.key,
    required this.state,
    required this.onOpenDailyNeeds,
    required this.onOpenRooms,
    required this.onOpenFoodInventory,
    required this.onOpenKnowledge,
    required this.onOpenTools,
    required this.onOpenSettings,
  });

  final AppState state;
  final VoidCallback onOpenDailyNeeds;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenFoodInventory;
  final VoidCallback onOpenKnowledge;
  final VoidCallback onOpenTools;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return PagePadding(
      child: CustomScrollView(
        key: const PageStorageKey('my-scroll'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: _ProfileHeroCard(
              state: state,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OnboardingScreen(state: state, editMode: true),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: MenuGroup(
              title: '照护管理',
              children: [
                MenuRow(
                  icon: Icons.repeat_rounded,
                  title: '每日照护需求',
                  tone: MenuTone.brand,
                  onTap: onOpenDailyNeeds,
                ),
                MenuRow(
                  icon: Icons.meeting_room_outlined,
                  title: '饲养空间',
                  tone: MenuTone.brand,
                  onTap: onOpenRooms,
                ),
                MenuRow(
                  icon: Icons.inventory_2_outlined,
                  title: '食物与用品',
                  tone: state.lowStockFoods.isEmpty
                      ? MenuTone.amber
                      : MenuTone.rose,
                  onTap: onOpenFoodInventory,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: MenuGroup(
              title: '知识与工具',
              children: [
                MenuRow(
                  icon: Icons.menu_book_outlined,
                  title: '常见异常与养护知识',
                  tone: MenuTone.brand,
                  onTap: onOpenKnowledge,
                ),
                MenuRow(
                  icon: Icons.science_outlined,
                  title: '科学计算工具',
                  tone: MenuTone.amber,
                  onTap: onOpenTools,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: MenuGroup(
              title: '设置与说明',
              children: [
                MenuRow(
                  icon: Icons.notifications_none_rounded,
                  title: '提醒与设置',
                  tone: MenuTone.brand,
                  onTap: onOpenSettings,
                ),
                MenuRow(
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私政策',
                  tone: MenuTone.brand,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AgreementScreen(
                        protocolKey: ApiSettings.privacyProtocolKey,
                        title: '隐私政策',
                      ),
                    ),
                  ),
                ),
                MenuRow(
                  icon: Icons.gavel_outlined,
                  title: '平台注册协议',
                  tone: MenuTone.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AgreementScreen(
                        protocolKey: ApiSettings.registerProtocolKey,
                        title: '平台注册协议',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: MenuGroup(
              title: '账号',
              children: [
                MenuRow(
                  icon: Icons.logout_rounded,
                  title: '退出登录',
                  tone: MenuTone.neutral,
                  onTap: () => _confirmLogout(context),
                ),
                MenuRow(
                  icon: Icons.person_remove_outlined,
                  title: '注销账号',
                  tone: MenuTone.rose,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('退出登录？', style: AppText.display(20)),
        content: Text(
          '退出后，本机数据会继续保留，下次进入可以接着使用。',
          style: AppText.body(12.5, color: AppColors.muted, height: 1.65),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: const Color(0xFFF4F1E6),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final token = await SessionTokenStore.read();
    final auth = AuthService();
    try {
      if (token != null && token.isNotEmpty) {
        await auth.logout(token);
      }
    } on Object {
      // Local logout remains available when the network is unavailable.
    } finally {
      auth.close();
      await SessionTokenStore.clear();
    }
    if (context.mounted) state.signOut();
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('注销本地账号？', style: AppText.display(20)),
        content: Text(
          '动物档案、任务、健康记录和个人资料都会从本机删除，且无法恢复。',
          style: AppText.body(12.5, color: AppColors.muted, height: 1.65),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final token = await SessionTokenStore.read();
    final auth = AuthService();
    try {
      if (token != null && token.isNotEmpty) {
        await auth.destroyAccount(token);
      }
    } on Object catch (error) {
      if (context.mounted) {
        showAppMessage(
          context,
          '云端注销失败：${error.toString().replaceFirst('Bad state: ', '')}',
        );
      }
      return;
    } finally {
      auth.close();
    }
    await SessionTokenStore.clear();
    if (context.mounted) state.deleteLocalAccount();
  }
}

class PetStripAvatar extends StatelessWidget {
  const PetStripAvatar({super.key, required this.pet});

  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: pet.species.gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: AnimalArt(species: pet.species, size: 23),
    );
  }
}
