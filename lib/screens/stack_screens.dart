import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../date_utils.dart';
import '../knowledge_content.dart';
import '../models.dart';
import '../sheets.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';
import 'care_management_screens.dart';
import 'create_screens.dart';

class _StackPage extends StatelessWidget {
  const _StackPage({
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomBar,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomBar;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          bottom: bottomBar == null,
          child: PagePadding(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: StackHeader(
                    title: title,
                    subtitle: subtitle,
                    action: action,
                  ),
                ),
                SliverToBoxAdapter(child: child),
                const SliverToBoxAdapter(child: SizedBox(height: 26)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key, required this.state, required this.petId});

  final AppState state;
  final String petId;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  int _tab = 0;

  PetProfile get _pet => widget.state.petById(widget.petId);

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _StackPage(
      title: '动物档案',
      subtitle: _pet.species.label,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundIconButton(
            key: const ValueKey('delete-pet-button'),
            icon: Icons.delete_outline_rounded,
            foreground: AppColors.rose,
            onPressed: _deletePet,
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            key: const ValueKey('edit-pet-button'),
            icon: Icons.edit_outlined,
            onPressed: _editPet,
          ),
        ],
      ),
      bottomBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.canvas.withValues(alpha: 0), AppColors.canvas],
              stops: const [0, 0.32],
            ),
          ),
          child: switch (_tab) {
            0 => PrimaryButton(
              label: '健康记录',
              icon: Icons.photo_camera_outlined,
              onPressed: _openHealthRecord,
            ),
            1 => PrimaryButton(
              label: '记录体重',
              icon: Icons.monitor_weight_outlined,
              onPressed: () => showAppSheet(
                context: context,
                child: RecordWeightSheet(state: widget.state, pet: _pet),
              ),
            ),
            2 => PrimaryButton(
              label: '新增养护任务',
              icon: Icons.add_task_rounded,
              onPressed: _addTask,
            ),
            _ => PrimaryButton(
              label: '添加食物计划',
              icon: Icons.add_rounded,
              onPressed: () => showAppSheet(
                context: context,
                child: AddFoodSheet(
                  state: widget.state,
                  initialPetId: _pet.id,
                  lockPet: true,
                ),
              ),
            ),
          },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PetProfileHero(
            pet: _pet,
            roomName: widget.state.roomById(_pet.roomId).name,
          ),
          const SizedBox(height: 18),
          _PetSubTabs(
            selected: _tab,
            onChanged: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.025),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: switch (_tab) {
              0 => _JournalList(key: const ValueKey('journal'), pet: _pet),
              1 => _GrowthChart(key: const ValueKey('growth'), pet: _pet),
              2 => _PetTasks(
                key: const ValueKey('tasks'),
                state: widget.state,
                pet: _pet,
              ),
              _ => _FoodPlan(
                key: const ValueKey('food'),
                state: widget.state,
                pet: _pet,
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          state: widget.state,
          initialPetId: _pet.id,
          lockPet: true,
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() {});
      showAppMessage(context, '已为 ${_pet.name} 新增养护任务');
    }
  }

  Future<void> _openHealthRecord() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthRecordScreen(state: widget.state, petId: _pet.id),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editPet() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetScreen(state: widget.state, initialPet: _pet),
      ),
    );
    if (updated == true && mounted) {
      setState(() {});
      showAppMessage(context, '动物资料已更新');
    }
  }

  Future<void> _deletePet() async {
    final petId = widget.petId;
    final petName = _pet.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('删除动物档案？', style: AppText.display(20)),
        content: Text(
          '“$petName”的档案、照片、健康记录、任务和库存都会被删除，且无法恢复。',
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
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    widget.state.removeListener(_onStateChanged);
    final deleted = widget.state.deletePet(petId);
    if (!deleted) {
      widget.state.addListener(_onStateChanged);
      if (mounted) showAppMessage(context, '动物档案已不存在');
      return;
    }
    if (mounted) showAppMessageAndPop(context, '动物档案已删除');
  }
}

class _PetProfileHero extends StatelessWidget {
  const _PetProfileHero({required this.pet, required this.roomName});

  final PetProfile pet;
  final String roomName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: pet.species.gradient,
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1715211C),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -34,
              child: AnimalArt(
                species: pet.species,
                size: 164,
                color: pet.species.ink.withValues(alpha: 0.05),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.64),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2415211C),
                            blurRadius: 20,
                            offset: Offset(0, 9),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: pet.photos.isEmpty
                          ? AnimalArt(species: pet.species, size: 44)
                          : _PetPhotoView(
                              path: pet.photos.first,
                              fallback: AnimalArt(
                                species: pet.species,
                                size: 46,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _PetGenderIcon(gender: pet.gender),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  pet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.display(24),
                                ),
                              ),
                              const SizedBox(width: 7),
                              _ProfileStatus(label: pet.status),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${pet.species.label} · ${pet.age}',
                            style: AppText.body(
                              11.5,
                              color: AppColors.ink2,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [
                                    roomName,
                                    if (pet.environment.isNotEmpty)
                                      pet.environment,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    10.5,
                                    color: AppColors.muted,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: '温度',
                        value: pet.temperature,
                        icon: Icons.thermostat_rounded,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeroMetric(
                        label: '湿度',
                        value: pet.humidity,
                        icon: Icons.water_drop_outlined,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeroMetric(
                        label: '体重',
                        value: pet.weight,
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
                if (pet.birthday != null || pet.startedAt != null) ...[
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (pet.birthday != null)
                        _ProfileMeta(
                          icon: Icons.cake_outlined,
                          label: '生日 ${PetDates.reportDate(pet.birthday!)}',
                        ),
                      if (pet.startedAt != null)
                        _ProfileMeta(
                          icon: Icons.home_outlined,
                          label: '饲养于 ${PetDates.reportDate(pet.startedAt!)}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PetGenderIcon extends StatelessWidget {
  const _PetGenderIcon({required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context) {
    final normalized = gender.trim().toLowerCase();
    final isMale =
        gender.contains('雄') || gender.contains('公') || normalized == 'male';
    final isFemale =
        gender.contains('雌') || gender.contains('母') || normalized == 'female';
    final color = isMale
        ? AppColors.blue
        : isFemale
        ? AppColors.rose
        : AppColors.faint;
    final background = isMale
        ? AppColors.blueWash
        : isFemale
        ? AppColors.roseWash
        : AppColors.paper.withValues(alpha: 0.58);
    final icon = isMale
        ? Icons.male_rounded
        : isFemale
        ? Icons.female_rounded
        : Icons.transgender_rounded;
    final label = isMale
        ? '雄性'
        : isFemale
        ? '雌性'
        : gender.trim().isEmpty
        ? '性别未设置'
        : gender.trim();

    return Semantics(
      label: label,
      child: Container(
        key: const ValueKey('pet-profile-gender-icon'),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}

class _ProfileStatus extends StatelessWidget {
  const _ProfileStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brand2.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(color: AppColors.brand2, size: 5),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.body(
              8.5,
              color: AppColors.brand,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(label, style: AppText.body(8.5, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.number(
              13.5,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMeta extends StatelessWidget {
  const _ProfileMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(label, style: AppText.body(9.5, color: AppColors.muted)),
      ],
    );
  }
}

class _PetPhotoView extends StatelessWidget {
  const _PetPhotoView({required this.path, required this.fallback});

  final String path;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return AppLocalImage(
      path: path,
      width: double.infinity,
      height: double.infinity,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _PetSubTabs extends StatelessWidget {
  const _PetSubTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['健康日记', '生长趋势', '养护任务', '食物计划'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hair)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Text(
                        labels[i],
                        style: AppText.body(
                          12.5,
                          color: selected == i
                              ? AppColors.brand
                              : AppColors.muted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected == i)
                      const Positioned(
                        left: 6,
                        right: 6,
                        bottom: 0,
                        child: SizedBox(
                          height: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.brass),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({super.key, required this.pet});

  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    if (pet.logs.isEmpty) {
      return const EmptyState(
        title: '还没有健康记录',
        message: '记录第一次观察，建立这只动物的健康时间线。',
      );
    }
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var index = 0; index < pet.logs.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.hair),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hair),
                    ),
                    child: Icon(
                      pet.logs[index].icon,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.logs[index].title,
                          style: AppText.body(13.5, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet.logs[index].description,
                          style: AppText.body(
                            11.5,
                            color: AppColors.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _journalTime(pet.logs[index]),
                          style: AppText.number(
                            10,
                            color: AppColors.faint,
                            weight: FontWeight.w400,
                          ),
                        ),
                        if (pet.logs[index].followUpAt != null) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                size: 14,
                                color: AppColors.amber,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '复看：${PetDates.relativeDateTime(pet.logs[index].followUpAt!)} · '
                                  '${PetDates.clock(pet.logs[index].followUpAt!)}',
                                  style: AppText.body(
                                    10.5,
                                    color: AppColors.amber,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (pet.logs[index].contactedVet) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 14,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '已联系专业机构',
                                style: AppText.body(
                                  10.5,
                                  color: AppColors.brand,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (pet.logs[index].attachmentPath != null) ...[
                          const SizedBox(height: 10),
                          _JournalAttachment(
                            path: pet.logs[index].attachmentPath!,
                          ),
                        ],
                      ],
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

  String _journalTime(JournalEntry entry) {
    final occurredAt = entry.occurredAt;
    if (occurredAt == null) return entry.time;
    return '${PetDates.reportDate(occurredAt)} '
        '${PetDates.clock(occurredAt)}';
  }
}

class _JournalAttachment extends StatelessWidget {
  const _JournalAttachment({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return AppLocalImage(
      path: path,
      width: double.infinity,
      height: 140,
      borderRadius: BorderRadius.circular(12),
      placeholder: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: Row(
        children: [
          const Icon(
            Icons.broken_image_outlined,
            size: 16,
            color: AppColors.faint,
          ),
          const SizedBox(width: 6),
          Text('照片不可用', style: AppText.body(10.5, color: AppColors.faint)),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({super.key, required this.pet});

  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    final allRecords =
        pet.weightHistory.where((record) => record.value > 0).toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final recentRecords = allRecords.length > 6
        ? allRecords.sublist(allRecords.length - 6)
        : allRecords;
    final unit = pet.weight.trim().endsWith('kg') ? 'kg' : 'g';
    return Column(
      children: [
        PaperCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('体重变化', style: AppText.display(15.5)),
                  const Spacer(),
                  Text(
                    '近 6 次 · $unit',
                    style: AppText.body(
                      10,
                      color: AppColors.faint,
                      weight: FontWeight.w600,
                      spacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentRecords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    '还没有体重记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Semantics(
                  label:
                      '最近六次体重记录：${recentRecords.map((record) => '${record.recordedAt.month}月${record.recordedAt.day}日 ${record.value} $unit').join('，')}',
                  child: SizedBox(
                    height: 220,
                    child: CustomPaint(
                      key: const ValueKey('weight-line-chart'),
                      painter: _WeightLineChartPainter(
                        records: recentRecords,
                        unit: unit,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PaperCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('全部体重记录', style: AppText.display(15.5)),
                  const Spacer(),
                  Text(
                    '${allRecords.length} 条',
                    style: AppText.body(10, color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allRecords.isEmpty)
                Text(
                  '暂无历史体重数据',
                  style: AppText.body(11.5, color: AppColors.faint),
                )
              else
                for (
                  var index = allRecords.length - 1;
                  index >= 0;
                  index--
                ) ...[
                  _WeightHistoryRow(record: allRecords[index], unit: unit),
                  if (index > 0)
                    const Divider(height: 19, color: AppColors.hair),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightHistoryRow extends StatelessWidget {
  const _WeightHistoryRow({required this.record, required this.unit});

  final WeightRecord record;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final date = record.recordedAt;
    final dateLabel =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}'
        ' ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final value = record.value.toStringAsFixed(record.value % 1 == 0 ? 0 : 1);
    return Row(
      children: [
        const Icon(
          Icons.monitor_weight_outlined,
          size: 17,
          color: AppColors.brand,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            dateLabel,
            style: AppText.number(11, color: AppColors.muted),
          ),
        ),
        Text(
          '$value $unit',
          style: AppText.number(12.5, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _WeightLineChartPainter extends CustomPainter {
  _WeightLineChartPainter({required this.records, required this.unit});

  final List<WeightRecord> records;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;
    const left = 42.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 30.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    var minValue = records
        .map((record) => record.value)
        .reduce((a, b) => a < b ? a : b);
    var maxValue = records
        .map((record) => record.value)
        .reduce((a, b) => a > b ? a : b);
    final spread = maxValue - minValue;
    final padding = spread.abs() < 0.001
        ? (maxValue.abs() * 0.1).clamp(0.5, double.infinity)
        : spread * 0.14;
    minValue = (minValue - padding).clamp(0.0, double.infinity).toDouble();
    maxValue += padding;
    if (maxValue <= minValue) maxValue = minValue + 1;

    final gridPaint = Paint()
      ..color = AppColors.hair
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: AppColors.faint,
      fontSize: 8.5,
      fontWeight: FontWeight.w500,
    );
    for (var index = 0; index <= 4; index++) {
      final ratio = index / 4;
      final y = plot.bottom - plot.height * ratio;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final value = minValue + (maxValue - minValue) * ratio;
      _paintText(
        canvas,
        _formatValue(value),
        Offset(plot.left - 7, y),
        labelStyle,
        alignRight: true,
        centerVertically: true,
      );
    }

    final points = <Offset>[];
    for (var index = 0; index < records.length; index++) {
      final x = records.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (records.length - 1);
      final y =
          plot.bottom -
          plot.height *
              (records[index].value - minValue) /
              (maxValue - minValue);
      points.add(Offset(x, y));
      final date = records[index].recordedAt;
      _paintText(
        canvas,
        '${date.month}/${date.day}',
        Offset(x, plot.bottom + 8),
        labelStyle,
        centerHorizontally: true,
      );
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3D2C6A57), Color(0x052C6A57)],
        ).createShader(plot),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final color = index == points.length - 1
          ? AppColors.brass
          : AppColors.brand;
      canvas.drawCircle(point, 5.2, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  String _formatValue(double value) {
    return value < 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool alignRight = false,
    bool centerHorizontally = false,
    bool centerVertically = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? anchor.dx - painter.width
        : centerHorizontally
        ? anchor.dx - painter.width / 2
        : anchor.dx;
    final dy = centerVertically ? anchor.dy - painter.height / 2 : anchor.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) {
    return oldDelegate.records != records || oldDelegate.unit != unit;
  }
}

class _PetTasks extends StatelessWidget {
  const _PetTasks({super.key, required this.state, required this.pet});

  final AppState state;
  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    final today = PetDates.dateOnly();
    final recurringByDefinition = <String, List<CareTask>>{};
    final tasks = <CareTask>[];
    for (final task in state.tasks.where((task) => task.petId == pet.id)) {
      if (task.definitionId.isEmpty) {
        tasks.add(task);
      } else {
        recurringByDefinition
            .putIfAbsent(task.definitionId, () => [])
            .add(task);
      }
    }
    for (final occurrences in recurringByDefinition.values) {
      final todayOccurrences =
          occurrences.where((task) => task.date == today).toList()
            ..sort((a, b) => a.time.compareTo(b.time));
      if (todayOccurrences.isNotEmpty) {
        tasks.add(todayOccurrences.first);
        continue;
      }
      final upcoming =
          occurrences.where((task) => task.date.isAfter(today)).toList()
            ..sort((a, b) {
              final dateOrder = a.date.compareTo(b.date);
              return dateOrder != 0 ? dateOrder : a.time.compareTo(b.time);
            });
      if (upcoming.isNotEmpty) {
        tasks.add(upcoming.first);
        continue;
      }
      occurrences.sort((a, b) => b.date.compareTo(a.date));
      tasks.add(occurrences.first);
    }
    tasks.sort((a, b) {
      final aPending = a.status == TaskStatus.pending;
      final bPending = b.status == TaskStatus.pending;
      if (aPending != bPending) return aPending ? -1 : 1;
      final dateOrder = a.date.compareTo(b.date);
      return dateOrder != 0 ? dateOrder : a.time.compareTo(b.time);
    });
    if (tasks.isEmpty) {
      return const EmptyState(
        title: '暂时没有养护任务',
        message: '可以使用底部的“新增养护任务”创建一项照护计划。',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < tasks.length; index++) ...[
          if (index > 0) const SizedBox(height: 9),
          TaskTile(
            task: tasks[index],
            pet: pet,
            onOpen: () => showAppSheet(
              context: context,
              child: _PetTaskActionsSheet(
                state: state,
                task: tasks[index],
                pet: pet,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PetTaskActionsSheet extends StatelessWidget {
  const _PetTaskActionsSheet({
    required this.state,
    required this.task,
    required this.pet,
  });

  final AppState state;
  final CareTask task;
  final PetProfile pet;

  CareTaskDefinition? get _definition => state.taskDefinitions
      .where((item) => item.id == task.definitionId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final definition = _definition;
    return AppSheetFrame(
      title: '任务管理',
      maxHeightFactor: 0.62,
      footer: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: '编辑',
              ghost: true,
              onPressed: definition == null ? null : () => _edit(context),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: PrimaryButton(
              label: '删除',
              onPressed: () => _delete(context),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: pet.species.gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pet.species.ink.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: AnimalArt(species: pet.species, size: 25),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: AppText.display(16)),
                      const SizedBox(height: 2),
                      Text(
                        pet.species.label,
                        style: AppText.body(9.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  task.time,
                  style: AppText.number(13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task.type}：${task.title}',
                  style: AppText.body(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                Text(
                  task.subtitle.trim().isEmpty ? '暂无任务说明' : task.subtitle,
                  style: AppText.body(
                    11.5,
                    color: AppColors.muted,
                    height: 1.65,
                  ),
                ),
                if (definition != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    '重复方式：${definition.repeatDescription}',
                    style: AppText.body(10.5, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final definition = _definition;
    if (definition == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          state: state,
          initialDefinition: definition,
          lockPet: true,
        ),
      ),
    );
    if (updated == true && context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('删除养护任务？', style: AppText.display(19)),
        content: Text(
          '“${task.title}”及已经生成的当天和后续任务都会被删除，且无法恢复。',
          style: AppText.body(12, color: AppColors.muted, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (_definition == null) {
      state.deleteTask(task.id);
    } else {
      state.deleteTaskDefinition(task.definitionId);
    }
    showAppMessageAndPop(context, '养护任务已删除');
  }
}

class _FoodPlan extends StatelessWidget {
  const _FoodPlan({super.key, required this.state, required this.pet});

  final AppState state;
  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    final foods = state.foodSupplies
        .where((food) => food.petId == pet.id)
        .toList();
    return Column(
      children: [
        if (foods.isEmpty)
          const EmptyState(
            title: '还没有食物计划',
            message: '登记食物名称、每天餐数、每餐用量和剩余库存后，系统会自动计算可吃天数。',
          )
        else
          for (final food in foods)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FoodSupplyCard(
                supply: food,
                pet: pet,
                onTap: () => showAppSheet(
                  context: context,
                  child: AddFoodSheet(
                    state: state,
                    existing: food,
                    lockPet: true,
                  ),
                ),
                onRestock: () => showAppSheet(
                  context: context,
                  child: RestockFoodSheet(state: state, supply: food),
                ),
              ),
            ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: foods.isEmpty ? '添加食物计划' : '继续添加食物',
          icon: Icons.add_rounded,
          ghost: true,
          onPressed: () => showAppSheet(
            context: context,
            child: AddFoodSheet(
              state: state,
              initialPetId: pet.id,
              lockPet: true,
            ),
          ),
        ),
      ],
    );
  }
}

class HandoffScreen extends StatefulWidget {
  const HandoffScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HandoffScreen> createState() => _HandoffScreenState();
}

class _HandoffScreenState extends State<HandoffScreen> {
  late String _petId = widget.state.pets.first.id;
  String _duration = '7 天';
  final _permissions = <String, bool>{
    '查看喂食与护理说明': true,
    '完成交接任务并添加备注': true,
    '查看近期健康日记': false,
    '查看医疗与用药资料': false,
  };

  @override
  Widget build(BuildContext context) {
    return _StackPage(
      title: '寄养交接',
      subtitle: '最小权限 · 可撤销',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Callout(message: '临时照护者默认只能查看护理说明、完成任务和补充备注，不会看到芯片号和完整医疗档案。'),
          const SizedBox(height: 14),
          FormSection(
            label: '交接动物',
            child: BottomSelectField<String>(
              title: '选择交接动物',
              value: _petId,
              icon: Icons.pets_outlined,
              options: [
                for (final pet in widget.state.pets)
                  BottomSelectOption(
                    value: pet.id,
                    label: '${pet.name} · ${pet.species.label}',
                    subtitle: pet.environment,
                  ),
              ],
              onChanged: (value) => setState(() => _petId = value),
            ),
          ),
          FormSection(
            label: '有效期',
            child: BottomSelectField<String>(
              title: '选择有效期',
              value: _duration,
              icon: Icons.event_available_outlined,
              options: const ['3 天', '7 天', '14 天']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _duration = value),
            ),
          ),
          PaperCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  for (var index = 0; index < _permissions.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.hair),
                    InkWell(
                      onTap: () {
                        final key = _permissions.keys.elementAt(index);
                        setState(() => _permissions[key] = !_permissions[key]!);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _permissions.keys.elementAt(index),
                                style: AppText.body(12.5),
                              ),
                            ),
                            Checkbox(
                              value: _permissions.values.elementAt(index),
                              onChanged: (value) => setState(
                                () =>
                                    _permissions[_permissions.keys.elementAt(
                                          index,
                                        )] =
                                        value!,
                              ),
                              activeColor: AppColors.brand,
                              side: const BorderSide(color: AppColors.hair2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '生成交接链接',
            icon: Icons.link_rounded,
            onPressed: _generateLink,
          ),
          if (widget.state.activeHandoffs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('当前授权', style: AppText.display(17.5)),
            const SizedBox(height: 10),
            PaperCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < widget.state.activeHandoffs.length;
                      index++
                    ) ...[
                      if (index > 0)
                        const Divider(height: 1, color: AppColors.hair),
                      _HandoffGrantRow(
                        state: widget.state,
                        grant: widget.state.activeHandoffs[index],
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateLink() async {
    final pet = widget.state.petById(_petId);
    final days = int.tryParse(_duration.split(' ').first) ?? 7;
    final grant = widget.state.createHandoff(
      petId: _petId,
      durationDays: days,
      permissions: _permissions,
    );
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('交接链接已生成', style: AppText.display(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pet.name} · $_duration有效',
              style: AppText.body(12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hair),
              ),
              child: Text(
                grant.link,
                style: AppText.number(12, color: AppColors.brand),
              ),
            ),
            const SizedBox(height: 12),
            Callout(message: '链接将在 $_duration后自动失效，也可以随时在隐私与账号中撤销。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: grant.link));
              if (context.mounted) {
                Navigator.pop(context);
                if (mounted) {
                  showAppMessage(this.context, '交接链接已复制');
                }
              }
            },
            child: Text(
              '复制链接',
              style: AppText.body(
                13,
                color: AppColors.brand,
                weight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            child: const Text('完成'),
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }
}

class _HandoffGrantRow extends StatelessWidget {
  const _HandoffGrantRow({
    required this.state,
    required this.grant,
    required this.onChanged,
  });

  final AppState state;
  final HandoffGrant grant;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final pet = state.petById(grant.petId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: pet.species.gradient,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: AnimalArt(species: pet.species, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.name} · 临时照护',
                  style: AppText.body(12.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '有效至 ${PetDates.reportDate(grant.expiresAt)}',
                  style: AppText.body(10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              state.revokeHandoff(grant.id);
              onChanged();
              showAppMessage(context, '交接授权已撤销');
            },
            child: Text('撤销', style: AppText.body(11.5, color: AppColors.rose)),
          ),
        ],
      ),
    );
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _type = '就医报告';

  @override
  Widget build(BuildContext context) {
    final pet = widget.state.pets.first;
    return _StackPage(
      title: '生成养护报告',
      subtitle: '离线也可生成',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSection(
            label: '报告类型',
            child: BottomSelectField<String>(
              title: '选择报告类型',
              value: _type,
              icon: Icons.description_outlined,
              options: const ['就医报告', '寄养交接单', '完整养护档案']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
          ),
          PaperCard(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('栖护', style: AppText.display(15.5)),
                    const Spacer(),
                    Text(
                      PetDates.reportDate(DateTime.now()),
                      style: AppText.number(10, color: AppColors.faint),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: pet.species.gradient,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.hair),
                      ),
                      alignment: Alignment.center,
                      child: AnimalArt(species: pet.species, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: AppText.display(16)),
                        const SizedBox(height: 3),
                        Text(
                          '${pet.species.label} · ${pet.age}',
                          style: AppText.body(10.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(height: 1, color: AppColors.hair),
                ),
                _ReportGrid(state: widget.state, pet: pet),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(height: 1, color: AppColors.hair),
                ),
                Text(
                  '包含近期护理、环境记录、健康观察和照片。报告仅供照护与沟通参考，不构成诊疗结论。',
                  style: AppText.body(
                    10.5,
                    color: AppColors.muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Callout(
            type: CalloutType.warn,
            message: '完整档案可能包含敏感信息。导出前请确认接收对象。',
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: '预览并生成报告',
            icon: Icons.visibility_outlined,
            onPressed: () => showAppSheet(
              context: context,
              child: ReportPreviewSheet(state: widget.state, reportType: _type),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({required this.state, required this.pet});

  final AppState state;
  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            LabeledMetric(label: '最近体重', value: pet.weight),
            LabeledMetric(label: '环境温度', value: pet.temperature),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            LabeledMetric(
              label: '近 7 日任务',
              value: '${state.taskCountForPetSince(pet.id)} 项',
            ),
            LabeledMetric(label: '健康记录', value: '${pet.logs.length} 条'),
          ],
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _unit = '公制 · °C / g / cm';

  @override
  Widget build(BuildContext context) {
    return _StackPage(
      title: '设置',
      subtitle: '通知、显示与本地数据',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaperCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  ToggleRow(
                    title: '养护提醒',
                    subtitle: '任务、库存与健康复看',
                    value: widget.state.notifications,
                    onChanged: (value) => setState(() {
                      widget.state.updateSettings(notifications: value);
                    }),
                  ),
                  const Divider(height: 1, color: AppColors.hair),
                  ToggleRow(
                    title: '震动反馈',
                    subtitle: '完成任务时提供轻柔提示',
                    value: widget.state.hapticFeedback,
                    onChanged: (value) => setState(() {
                      widget.state.updateSettings(hapticFeedback: value);
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FormSection(
            label: '单位',
            child: BottomSelectField<String>(
              title: '选择单位',
              value: _unit,
              icon: Icons.straighten_outlined,
              options: const ['公制 · °C / g / cm', '英制 · °F / oz / in']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _unit = value),
            ),
          ),
          PrimaryButton(
            label: '保存设置',
            onPressed: () => showAppMessage(context, '设置已保存'),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _StackPage(
      title: '隐私与账号',
      subtitle: '你的数据由你控制',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Callout(message: '分享默认隐藏芯片号、购买凭证、家庭地址和完整医疗档案。任何授权都可以随时撤销。'),
          const SizedBox(height: 12),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.file_download_outlined,
                title: '导出我的数据',
                subtitle: '生成离线完整档案',
                tone: MenuTone.brand,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReportScreen(state: state),
                  ),
                ),
              ),
              MenuRow(
                icon: Icons.link_outlined,
                title: '管理交接授权',
                subtitle: '查看、撤销和重新生成',
                tone: MenuTone.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HandoffScreen(state: state),
                  ),
                ),
              ),
              MenuRow(
                icon: Icons.delete_outline_rounded,
                title: '删除账号与数据',
                subtitle: '7 天撤销窗口',
                tone: MenuTone.rose,
                onTap: () => showAppSheet(
                  context: context,
                  child: DeleteDemoSheet(
                    state: state,
                    onReset: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Callout(
            type: CalloutType.warn,
            message: '删除账号前请先导出需要保留的数据。正式产品不会在上传或同步时自动清空本地副本。',
          ),
        ],
      ),
    );
  }
}

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final _searchController = TextEditingController();
  String _category = '全部';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final categories = [
      '全部',
      ...knowledgeArticles.map((article) => article.category).toSet(),
    ];
    final articles = knowledgeArticles.where((article) {
      final categoryMatch = _category == '全部' || article.category == _category;
      final textMatch =
          query.isEmpty ||
          '${article.title} ${article.subtitle} ${article.keywords} '
                  '${article.category}'
              .toLowerCase()
              .contains(query);
      return categoryMatch && textMatch;
    }).toList();
    return _StackPage(
      title: '养护知识库',
      subtitle: '专业审核内容',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: AppText.body(13.5),
            decoration: const InputDecoration(
              hintText: '搜索物种或异常关键词',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.faint,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ChipRow(
            labels: categories,
            selected: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 6),
          if (articles.isEmpty)
            const EmptyState(title: '没有找到相关内容', message: '换个关键词，或切换养护分类浏览。')
          else
            MenuGroup(
              children: [
                for (final article in articles)
                  MenuRow(
                    leading: AnimalArt(species: article.species, size: 22),
                    title: article.title,
                    subtitle: article.subtitle,
                    tone: _knowledgeTone(article.category),
                    onTap: () => showAppSheet(
                      context: context,
                      child: ArticleSheet(article: article),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          const Callout(
            type: CalloutType.danger,
            message: '出现呼吸异常、持续出血或严重受伤时，请尽快联系异宠兽医或专业机构。应用不提供自动诊断。',
          ),
        ],
      ),
    );
  }
}

MenuTone _knowledgeTone(String category) {
  return switch (category) {
    '水族' => MenuTone.blue,
    '鸟类' || '狗' || '兔' || '豚鼠' || '仓鼠' => MenuTone.amber,
    '猫' || '急症' => MenuTone.rose,
    _ => MenuTone.brand,
  };
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StackPage(
      title: '科学计算工具',
      subtitle: '带单位和计算依据',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.water_drop_outlined,
                title: '水体容积换算',
                subtitle: '长 × 宽 × 高与预留空间',
                tone: MenuTone.blue,
                onTap: () => showAppSheet(
                  context: context,
                  child: const VolumeCalculatorSheet(),
                ),
              ),
              MenuRow(
                icon: Icons.science_outlined,
                title: '盐度与换水配比',
                subtitle: '海水缸常用计算',
                tone: MenuTone.brand,
                onTap: () => showAppSheet(
                  context: context,
                  child: const SalinityCalculatorSheet(),
                ),
              ),
              MenuRow(
                icon: Icons.lightbulb_outline_rounded,
                title: '设备寿命倒计时',
                subtitle: 'UVB 灯、滤材与滤网',
                tone: MenuTone.amber,
                onTap: () => showAppSheet(
                  context: context,
                  child: const EquipmentLifeSheet(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Callout(message: '计算结果会明确显示输入单位、公式和适用限制。涉及药物的剂量不在通用工具中自动给出。'),
        ],
      ),
    );
  }
}
