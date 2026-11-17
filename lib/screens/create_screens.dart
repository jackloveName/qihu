import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
    return FormSection(
      label: '1 · 宠物照片（最多 9 张）',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < _photos.length; index++)
                _EditablePetPhoto(
                  path: _photos[index],
                  onRemove: () => setState(() => _photos.removeAt(index)),
                ),
              if (_photos.length < 9)
                _AddPhotoTile(
                  saving: _savingPhotos,
                  count: _photos.length,
                  onTap: _pickPhotos,
                ),
            ],
          ),
        ],
      ),
    );
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
                    onChanged: (value) =>
                        setState(() => _templateCategory = value),
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
                        : SizedBox(
                            height: 266,
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: templates.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.06,
                                  ),
                              itemBuilder: (context, index) {
                                final species = templates[index];
                                final selected = species == _species;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _species = species),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
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
                                      borderRadius: BorderRadius.circular(15),
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
                      onChanged: (value) => setState(() => _roomId = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '4 · 动物昵称',
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
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
                      onChanged: (value) => setState(() => _gender = value),
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
    final selected = await _showDatePickerSheet(
      initialDate: _startedAt,
      title: '选择开始饲养时间',
    );
    if (selected != null && mounted) {
      setState(() => _startedAt = PetDates.dateOnly(selected));
    }
  }

  Future<void> _pickBirthday() async {
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
    if (_photos.length >= 9) return;
    setState(() => _savingPhotos = true);
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 86,
        maxWidth: 1600,
      );
      if (images.isEmpty) return;
      final directory = await getApplicationDocumentsDirectory();
      for (final image in images.take(9 - _photos.length)) {
        var path = image.path;
        try {
          final extension = image.name.split('.').lastOrNull ?? 'jpg';
          final target =
              '${directory.path}/pet_photo_${DateTime.now().microsecondsSinceEpoch}.$extension';
          await image.saveTo(target);
          path = target;
        } on Object {
          // Fall back to the picker path when document storage is unavailable.
        }
        _photos.add(path);
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
      children: [
        AppLocalImage(
          path: path,
          width: 82,
          height: 82,
          borderRadius: BorderRadius.circular(12),
        ),
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
          width: 82,
          height: 82,
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

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.state,
    this.initialPetId,
    this.initialRecurring = true,
  });

  final AppState state;
  final String? initialPetId;
  final bool initialRecurring;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late String _petId = widget.initialPetId ?? widget.state.pets.first.id;
  String _type = '环境';
  late String _repeat = widget.initialRecurring ? '每天重复' : '仅今天';
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '18:00');

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
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
                    title: '新增养护任务',
                    subtitle: '计划 · 提醒 · 执行记录',
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '关联动物',
                    child: BottomSelectField<String>(
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
                      onChanged: (value) => setState(() => _petId = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '任务名称',
                    child: TextField(
                      controller: _titleController,
                      style: AppText.body(13.5),
                      decoration: const InputDecoration(hintText: '例如：检查加热垫'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '执行时间',
                    child: TextField(
                      controller: _timeController,
                      keyboardType: TextInputType.datetime,
                      style: AppText.number(13.5),
                      decoration: const InputDecoration(hintText: '18:00'),
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
                      options: const ['环境', '喂食', '清洁', '健康', '设备']
                          .map(
                            (value) =>
                                BottomSelectOption(value: value, label: value),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _type = value),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FormSection(
                    label: '重复方式',
                    child: BottomSelectField<String>(
                      title: '选择重复方式',
                      value: _repeat,
                      icon: Icons.repeat_rounded,
                      options: const [
                        BottomSelectOption(
                          value: '每天重复',
                          label: '每天重复',
                          subtitle: '创建一次，每天自动生成养护任务',
                        ),
                        BottomSelectOption(
                          value: '仅今天',
                          label: '仅今天',
                          subtitle: '只生成当天的一次性任务',
                        ),
                      ],
                      onChanged: (value) => setState(() => _repeat = value),
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

  void _create() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppMessage(context, '请填写任务名称');
      return;
    }
    widget.state.addTask(
      petId: _petId,
      title: title,
      time: _timeController.text.trim().isEmpty
          ? '18:00'
          : _timeController.text.trim(),
      type: _type,
      recurring: _repeat == '每天重复',
    );
    Navigator.pop(context, true);
  }
}
