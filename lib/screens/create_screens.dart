import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_theme.dart';
import '../date_utils.dart';
import '../models.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, required this.state, this.initialPet});

  final AppState state;
  final PetProfile? initialPet;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  late PetSpecies _species;
  late final List<String> _categories = [
    '全部',
    ...widget.state.speciesCategories,
  ];
  final _templateSearchController = TextEditingController();
  String _templateCategory = '全部';
  late String _roomId = widget.state.rooms.firstOrNull?.id ?? '';
  final _nameController = TextEditingController();
  final _environmentController = TextEditingController();
  late DateTime _startedAt = PetDates.dateOnly();
  DateTime? _birthday;
  String _gender = '';
  final List<String> _photos = [];
  final _picker = ImagePicker();
  bool _savingPhotos = false;

  @override
  void initState() {
    super.initState();
    final pet = widget.initialPet;
    _species = pet == null
        ? widget.state.speciesTemplates.first
        : widget.state.speciesTemplates.firstWhere(
            (item) => item.id == pet.species.id,
            orElse: () => pet.species,
          );
    if (pet != null) {
      _roomId =
          widget.state.rooms
              .where((room) => room.id == pet.roomId)
              .firstOrNull
              ?.id ??
          widget.state.rooms.firstOrNull?.id ??
          '';
      _nameController.text = pet.name;
      _environmentController.text = pet.environment;
      _startedAt = pet.startedAt ?? PetDates.dateOnly();
      _birthday = pet.birthday;
      _gender = pet.gender;
      _photos.addAll(pet.photos);
    }
  }

  @override
  void dispose() {
    _templateSearchController.dispose();
    _nameController.dispose();
    _environmentController.dispose();
    super.dispose();
  }

  Widget _buildPhotosSection() {
    final itemCount = _photos.length + (_photos.length < 9 ? 1 : 0);
    return FormSection(
      label: '1 · 宠物照片（最多 9 张）',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          if (index < _photos.length) {
            return _EditablePetPhoto(
              path: _photos[index],
              onRemove: () => setState(() => _photos.removeAt(index)),
            );
          }
          return _AddPhotoTile(
            saving: _savingPhotos,
            count: _photos.length,
            onTap: _pickPhotos,
          );
        },
      ),
    );
  }

  void _dismissInputFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = _templateSearchController.text.trim().toLowerCase();
    final templates = widget.state.speciesTemplates.where((template) {
      final categoryMatch =
          _templateCategory == '全部' || template.category == _templateCategory;
      final queryMatch =
          query.isEmpty ||
          '${template.label} ${template.category} ${template.note}'
              .toLowerCase()
              .contains(query);
      return categoryMatch && queryMatch;
    }).toList();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: PagePadding(
            child: CustomScrollView(
              key: const ValueKey('add-pet-scroll'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: StackHeader(
                    title: widget.initialPet == null ? '添加动物' : '编辑动物',
                    subtitle: widget.initialPet == null
                        ? '物种模板 · 本地建档'
                        : '更新档案 · 空间与照片',
                  ),
                ),
                SliverToBoxAdapter(child: _buildPhotosSection()),
                SliverToBoxAdapter(
                  child: TextField(
                    controller: _templateSearchController,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (_) => _dismissInputFocus(),
                    style: AppText.body(13),
                    decoration: const InputDecoration(
                      hintText: '搜索物种模板',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.faint,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ChipRow(
                    labels: _categories,
                    selected: _templateCategory,
                    onChanged: (value) {
                      _dismissInputFocus();
                      setState(() => _templateCategory = value);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '2 · 选择物种模板',
                    child: templates.isEmpty
                        ? const EmptyState(
                            title: '没有匹配的模板',
                            message: '可以换个关键词，或在设置中新增自定义模板。',
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final visibleRows = templates.length <= 3 ? 1 : 2;
                              const spacing = 8.0;
                              final tileWidth =
                                  (constraints.maxWidth - spacing * 2) / 3;
                              final tileHeight = tileWidth / 1.06;
                              final height =
                                  tileHeight * visibleRows +
                                  spacing * (visibleRows - 1);
                              return SizedBox(
                                height: height,
                                child: GridView.builder(
                                  physics: templates.length > 6
                                      ? const BouncingScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                                  itemCount: templates.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: spacing,
                                        mainAxisSpacing: spacing,
                                        childAspectRatio: 1.06,
                                      ),
                                  itemBuilder: (context, index) {
                                    final species = templates[index];
                                    final selected = species == _species;
                                    return GestureDetector(
                                      onTap: () {
                                        _dismissInputFocus();
                                        setState(() => _species = species);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          7,
                                          11,
                                          7,
                                          8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? null
                                              : species.gradient,
                                          color: selected
                                              ? AppColors.brandWash
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.brand
                                                : AppColors.hair,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimalArt(
                                              species: species,
                                              size: 29,
                                              color: selected
                                                  ? AppColors.brand
                                                  : species.ink,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              species.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.body(
                                                9.5,
                                                color: selected
                                                    ? AppColors.brand
                                                    : AppColors.ink2,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              species.category,
                                              style: AppText.body(
                                                7.8,
                                                color: AppColors.faint,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '3 · 饲养空间',
                    child: BottomSelectField<String>(
                      title: '选择房间',
                      value: _roomId,
                      icon: Icons.meeting_room_outlined,
                      options: [
                        for (final room in widget.state.rooms)
                          BottomSelectOption(
                            value: room.id,
                            label: room.name,
                            subtitle: room.type,
                            icon: Icons.meeting_room_outlined,
                          ),
                      ],
                      onChanged: (value) {
                        _dismissInputFocus();
                        setState(() => _roomId = value);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '4 · 动物昵称',
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => _dismissInputFocus(),
                      style: AppText.body(13.5),
                      decoration: const InputDecoration(hintText: '例如：糯米'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '5 · 环境名称',
                    child: TextField(
                      controller: _environmentController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _dismissInputFocus(),
                      onTapOutside: (_) => _dismissInputFocus(),
                      style: AppText.body(13.5),
                      decoration: const InputDecoration(hintText: '环境名称'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '6 · 开始饲养时间',
                    child: InkWell(
                      onTap: _pickStartedAt,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hair),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                PetDates.reportDate(_startedAt),
                                style: AppText.number(13),
                              ),
                            ),
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
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '7 · 宠物生日',
                    child: InkWell(
                      key: const ValueKey('pet-birthday-field'),
                      onTap: _pickBirthday,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _birthday == null
                                ? AppColors.rose.withValues(alpha: 0.45)
                                : AppColors.hair,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cake_outlined,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _birthday == null
                                    ? '请选择宠物生日（必填）'
                                    : PetDates.reportDate(_birthday!),
                                style: _birthday == null
                                    ? AppText.body(13, color: AppColors.faint)
                                    : AppText.number(13),
                              ),
                            ),
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
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '8 · 宠物性别',
                    child: BottomSelectField<String>(
                      key: const ValueKey('pet-gender-field'),
                      title: '选择性别',
                      value: _gender,
                      icon: Icons.transgender_rounded,
                      options: const [
                        BottomSelectOption(value: '雄性', label: '雄性'),
                        BottomSelectOption(value: '雌性', label: '雌性'),
                        BottomSelectOption(value: '未知', label: '未知'),
                      ],
                      onChanged: (value) {
                        _dismissInputFocus();
                        setState(() => _gender = value);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Callout(
                    message: '系统会基于模板预填环境范围与常用任务。请先确认物种来源与当地饲养法规。',
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: widget.initialPet == null ? '提交保存' : '保存修改',
          onPressed: _create,
        ),
      ),
    );
  }

  void _create() {
    _dismissInputFocus();
    if (widget.initialPet == null && !widget.state.canAddPet) {
      showAppMessage(context, '游客模式最多添加 3 只宠物，登录后可继续添加');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppMessage(context, '请填写动物昵称');
      return;
    }
    if (_gender.trim().isEmpty) {
      showAppMessage(context, '请选择宠物性别');
      return;
    }
    if (_birthday == null) {
      showAppMessage(context, '请选择宠物生日');
      return;
    }
    final environment = _environmentController.text.trim();
    final existing = widget.initialPet;
    if (existing != null) {
      widget.state.updatePetProfile(
        existing.id,
        name: name,
        environment: environment,
        roomId: _roomId,
        birthday: _birthday,
        gender: _gender,
        startedAt: _startedAt,
        photos: _photos,
      );
      Navigator.pop(context, true);
      return;
    }
    final created = widget.state.addPet(
      species: _species,
      name: name,
      environment: environment,
      roomId: _roomId,
      startedAt: _startedAt,
      birthday: _birthday,
      gender: _gender,
      photos: _photos,
    );
    if (created == null) {
      showAppMessage(context, '游客模式最多添加 3 只宠物，登录后可继续添加');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _pickStartedAt() async {
    _dismissInputFocus();
    final selected = await _showDatePickerSheet(
      initialDate: _startedAt,
      title: '选择开始饲养时间',
    );
    if (selected != null && mounted) {
      setState(() => _startedAt = PetDates.dateOnly(selected));
    }
  }

  Future<void> _pickBirthday() async {
    _dismissInputFocus();
    final selected = await _showDatePickerSheet(
      initialDate: _birthday ?? PetDates.dateOnly(),
      title: '选择宠物生日',
    );
    if (selected != null && mounted) {
      setState(() => _birthday = PetDates.dateOnly(selected));
    }
  }

  Future<DateTime?> _showDatePickerSheet({
    required DateTime initialDate,
    required String title,
  }) async {
    var draft = PetDates.dateOnly(initialDate);
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetFrame(
          title: title,
          maxHeightFactor: 0.74,
          shrinkToContent: true,
          footer: PrimaryButton(
            label: '确认日期',
            onPressed: () => Navigator.pop(context, draft),
          ),
          child: CalendarDatePicker(
            initialDate: draft,
            firstDate: DateTime(1990),
            lastDate: PetDates.dateOnly(),
            onDateChanged: (value) => setModalState(() => draft = value),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    _dismissInputFocus();
    if (_photos.length >= 9) return;
    setState(() => _savingPhotos = true);
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 68,
        maxWidth: 1200,
      );
      if (images.isEmpty) return;
      for (final image in images.take(9 - _photos.length)) {
        final bytes = await image.readAsBytes();
        final extension = image.name.split('.').lastOrNull?.toLowerCase();
        final mimeType =
            image.mimeType ??
            switch (extension) {
              'png' => 'image/png',
              'webp' => 'image/webp',
              _ => 'image/jpeg',
            };
        _photos.add('data:$mimeType;base64,${base64Encode(bytes)}');
      }
      if (mounted) setState(() {});
    } on Object {
      if (mounted) {
        showAppMessage(context, '无法读取宠物照片，请检查相册权限');
      }
    } finally {
      if (mounted) setState(() => _savingPhotos = false);
    }
  }
}

class _EditablePetPhoto extends StatelessWidget {
  const _EditablePetPhoto({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppLocalImage(path: path, borderRadius: BorderRadius.circular(12)),
        Positioned(
          right: 3,
          top: 3,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.saving,
    required this.count,
    required this.onTap,
  });

  final bool saving;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const ValueKey('pet-add-photo'),
        onTap: saving ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandLine, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (saving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.brand,
                  size: 24,
                ),
              const SizedBox(height: 6),
              Text(
                saving ? '处理中' : '照片 $count/9',
                style: AppText.body(
                  9,
                  color: saving ? AppColors.faint : AppColors.muted,
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

class _TaskPriorityChoice extends StatelessWidget {
  const _TaskPriorityChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.wash,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final Color wash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? wash : AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.hair,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              12.5,
              color: selected ? color : AppColors.ink2,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.state,
    this.initialPetId,
    this.initialRecurring = true,
    this.lockPet = false,
  });

  final AppState state;
  final String? initialPetId;
  final bool initialRecurring;
  final bool lockPet;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late String _petId = widget.initialPetId ?? widget.state.pets.first.id;
  String _type = '环境';
  TaskPriority _priority = TaskPriority.suggested;
  late String _repeatMode = widget.initialRecurring ? '每天' : '仅今天';
  final Set<int> _customWeekdays = {DateTime.now().weekday};
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  DateTime _fixedDate = PetDates.dateOnly();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _repeatModes = [
    '仅今天',
    '每天',
    '工作日',
    '周末',
    '每周一次',
    '指定星期',
    '固定日期',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPet = widget.state.petByIdOrNull(_petId);
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
                    title: '新增养护任务',
                    subtitle: '计划 · 提醒 · 执行记录',
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '关联动物',
                    child: widget.lockPet && selectedPet != null
                        ? PaperCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: selectedPet.species.gradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimalArt(
                                    species: selectedPet.species,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedPet.name,
                                        style: AppText.body(
                                          13,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${selectedPet.species.label} · ${selectedPet.environment}',
                                        style: AppText.body(
                                          9.5,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppColors.faint,
                                ),
                              ],
                            ),
                          )
                        : BottomSelectField<String>(
                            title: '选择动物',
                            value: _petId,
                            icon: Icons.pets_outlined,
                            options: [
                              for (final pet in widget.state.pets)
                                BottomSelectOption(
                                  value: pet.id,
                                  label: pet.name,
                                  subtitle:
                                      '${pet.species.label} · ${pet.environment}',
                                  icon: Icons.pets_outlined,
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _petId = value),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '任务类型',
                    child: BottomSelectField<String>(
                      title: '选择任务类型',
                      value: _type,
                      icon: Icons.tune_rounded,
                      options: const ['环境', '喂食', '清洁', '健康', '设备', '称重']
                          .map(
                            (value) =>
                                BottomSelectOption(value: value, label: value),
                          )
                          .toList(),
                      onChanged: (value) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() => _type = value);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '任务名称',
                    child: TextField(
                      controller: _titleController,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      style: AppText.body(13.5),
                      decoration: InputDecoration(hintText: _titleHint),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '任务说明',
                    child: TextField(
                      controller: _descriptionController,
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      minLines: 2,
                      maxLines: 4,
                      style: AppText.body(13),
                      decoration: InputDecoration(hintText: _descriptionHint),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '优先级',
                    child: Row(
                      children: [
                        Expanded(
                          child: _TaskPriorityChoice(
                            key: const ValueKey('task-priority-must'),
                            label: '必做',
                            selected: _priority == TaskPriority.must,
                            color: AppColors.rose,
                            wash: AppColors.roseWash,
                            onTap: () =>
                                setState(() => _priority = TaskPriority.must),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TaskPriorityChoice(
                            key: const ValueKey('task-priority-suggested'),
                            label: '建议',
                            selected: _priority == TaskPriority.suggested,
                            color: AppColors.brass,
                            wash: AppColors.brassWash,
                            onTap: () => setState(
                              () => _priority = TaskPriority.suggested,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildRepeatSection()),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '执行时间',
                    child: InkWell(
                      key: const ValueKey('task-time-field'),
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hair),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _formatTime(_time),
                                style: AppText.number(13.5),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: AppColors.faint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: '创建任务', onPressed: _create),
      ),
    );
  }

  String get _titleHint {
    return switch (_type) {
      '环境' => '例如：检查温湿度',
      '喂食' => '例如：准备晚餐',
      '清洁' => '例如：清理生活区',
      '健康' => '例如：观察精神状态',
      '设备' => '例如：检查过滤设备',
      '称重' => '例如：每周称重',
      _ => '填写任务名称',
    };
  }

  String get _descriptionHint {
    return switch (_type) {
      '环境' => '例如：记录冷热区温度与湿度',
      '喂食' => '例如：准备晚餐并观察进食情况',
      '清洁' => '例如：更换垫材并清洁生活区',
      '健康' => '例如：观察精神状态与体重变化',
      '设备' => '例如：检查温控设备运行状态',
      '称重' => '例如：同一时间记录本次体重',
      _ => '说明检查内容或执行标准',
    };
  }

  Widget _buildRepeatSection() {
    return FormSection(
      label: '重复方式',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BottomSelectField<String>(
            title: '选择重复方式',
            value: _repeatMode,
            icon: Icons.repeat_rounded,
            options: [
              for (final mode in _repeatModes)
                BottomSelectOption(value: mode, label: mode),
            ],
            onChanged: (value) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _repeatMode = value;
                if (value == '指定星期' && _customWeekdays.isEmpty) {
                  _customWeekdays.add(DateTime.now().weekday);
                }
              });
            },
          ),
          if (_repeatMode == '指定星期') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var weekday = 1; weekday <= 7; weekday++)
                  FilterChip(
                    label: Text('周${CareTaskDefinition.weekdayLabel(weekday)}'),
                    selected: _customWeekdays.contains(weekday),
                    showCheckmark: false,
                    selectedColor: AppColors.brandWash,
                    side: BorderSide(
                      color: _customWeekdays.contains(weekday)
                          ? AppColors.brandLine
                          : AppColors.hair,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _customWeekdays.add(weekday);
                        } else if (_customWeekdays.length > 1) {
                          _customWeekdays.remove(weekday);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
          if (_repeatMode == '固定日期') ...[
            const SizedBox(height: 10),
            InkWell(
              key: const ValueKey('task-fixed-date-field'),
              onTap: _pickFixedDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hair),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        PetDates.reportDate(_fixedDate),
                        style: AppText.number(13),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.faint,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _repeatDescription,
            style: AppText.body(10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _create() {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppMessage(context, '请填写任务名称');
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      showAppMessage(context, '请填写任务说明');
      return;
    }
    if (_repeatMode == '指定星期' && _customWeekdays.isEmpty) {
      showAppMessage(context, '请至少选择一个星期');
      return;
    }
    final recurring = !const {'仅今天', '固定日期'}.contains(_repeatMode);
    final weekdays = switch (_repeatMode) {
      '工作日' => const {1, 2, 3, 4, 5},
      '周末' => const {6, 7},
      '每周一次' => {DateTime.now().weekday},
      '指定星期' => Set<int>.from(_customWeekdays),
      _ => const <int>{},
    };
    widget.state.addTask(
      petId: _petId,
      title: title,
      subtitle: description,
      time: _formatTime(_time),
      type: _type,
      priority: _priority,
      recurring: recurring,
      date: _repeatMode == '固定日期' ? _fixedDate : PetDates.dateOnly(),
      weekdays: weekdays,
    );
    Navigator.pop(context, true);
  }

  String get _repeatDescription {
    return switch (_repeatMode) {
      '仅今天' => '任务只出现在今天。',
      '固定日期' => '任务只在 ${PetDates.reportDate(_fixedDate)} 出现。',
      '每天' => '每天自动生成任务。',
      '工作日' => '周一至周五自动生成任务。',
      '周末' => '周六、周日自动生成任务。',
      '每周一次' =>
        '每周${CareTaskDefinition.weekdayLabel(DateTime.now().weekday)}自动生成任务。',
      '指定星期' =>
        '每周${(_customWeekdays.toList()..sort()).map(CareTaskDefinition.weekdayLabel).join('、')}自动生成任务。',
      _ => '',
    };
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var draft = _time;
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetFrame(
          title: '选择执行时间',
          maxHeightFactor: 0.58,
          shrinkToContent: true,
          footer: PrimaryButton(
            label: '确认时间',
            onPressed: () => Navigator.pop(context, draft),
          ),
          child: SizedBox(
            height: 180,
            child: HourMinutePicker(
              initialTime: draft,
              onChanged: (value) => setModalState(() => draft = value),
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _pickFixedDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var draft = _fixedDate;
    final today = PetDates.dateOnly();
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AppSheetFrame(
          title: '选择任务日期',
          maxHeightFactor: 0.74,
          shrinkToContent: true,
          footer: PrimaryButton(
            label: '确认日期',
            onPressed: () => Navigator.pop(context, draft),
          ),
          child: CalendarDatePicker(
            initialDate: draft,
            firstDate: today,
            lastDate: today.add(const Duration(days: 365)),
            onDateChanged: (value) => setModalState(() => draft = value),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _fixedDate = PetDates.dateOnly(selected));
    }
  }
}
