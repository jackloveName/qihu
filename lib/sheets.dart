import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_theme.dart';
import 'date_utils.dart';
import 'knowledge_content.dart';
import 'models.dart';
import 'report_service.dart';
import 'widgets/animal_art.dart';
import 'widgets/app_widgets.dart';

enum QuickAddKind { pet, task, health }

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.state});

  final AppState state;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nicknameController = TextEditingController(
    text: widget.state.nickname,
  );
  late String? _avatarPath = widget.state.avatarPath;
  final _imagePicker = ImagePicker();
  bool _savingAvatar = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '编辑个人资料',
      maxHeightFactor: 0.78,
      footer: PrimaryButton(
        label: '保存资料',
        onPressed: () {
          if (_nicknameController.text.trim().isEmpty) {
            showAppMessage(context, '昵称不能为空');
            return;
          }
          widget.state.updateProfile(
            nickname: _nicknameController.text,
            avatarPath: _avatarPath,
          );
          showAppMessageAndPop(context, '个人资料已更新');
        },
      ),
      child: Column(
        children: [
          EditableAvatar(
            path: _avatarPath,
            size: 78,
            radius: 25,
            isSaving: _savingAvatar,
            onPressed: _pickAvatar,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _savingAvatar ? null : _pickAvatar,
                child: const Text('更换头像'),
              ),
              if (_avatarPath != null)
                TextButton(
                  onPressed: () => setState(() => _avatarPath = null),
                  child: const Text('移除头像'),
                ),
            ],
          ),
          const SizedBox(height: 7),
          FormSection(
            label: '昵称',
            child: TextField(
              controller: _nicknameController,
              autofocus: true,
              maxLength: 18,
              style: AppText.body(14),
              decoration: const InputDecoration(
                hintText: '输入你的昵称',
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    setState(() => _savingAvatar = true);
    try {
      final image = await _imagePicker.pickImage(
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
      if (!mounted) return;
      setState(() => _avatarPath = path);
    } on Object {
      if (mounted) showAppMessage(context, '无法读取头像，请检查相册权限');
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }
}

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key, required this.onSelected});

  final ValueChanged<QuickAddKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '快速添加',
      maxHeightFactor: 0.58,
      child: Column(
        children: [
          _QuickOption(
            icon: Icons.pets_outlined,
            title: '新增动物',
            subtitle: '从物种模板快速建档',
            tone: MenuTone.brand,
            onTap: () => _select(context, QuickAddKind.pet),
          ),
          _QuickOption(
            icon: Icons.edit_calendar_outlined,
            title: '新增养护任务',
            subtitle: '设置重复提醒与执行时间',
            tone: MenuTone.neutral,
            onTap: () => _select(context, QuickAddKind.task),
          ),
          _QuickOption(
            icon: Icons.photo_camera_outlined,
            title: '记录健康观察',
            subtitle: '添加照片、标签和复看时间',
            tone: MenuTone.blue,
            onTap: () => _select(context, QuickAddKind.health),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, QuickAddKind kind) {
    Navigator.pop(context);
    Future<void>.delayed(
      const Duration(milliseconds: 280),
      () => onSelected(kind),
    );
  }
}

class _QuickOption extends StatelessWidget {
  const _QuickOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final MenuTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = switch (tone) {
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
        const Color(0xFFEAD8BA),
      ),
      MenuTone.rose => (
        AppColors.rose,
        AppColors.roseWash,
        const Color(0xFFEACFCA),
      ),
      MenuTone.neutral => (AppColors.ink2, AppColors.paper2, AppColors.hair),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Icon(icon, color: fg, size: 19),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body(13.5, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppText.body(10.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.faint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({super.key, required this.state, required this.task});

  final AppState state;
  final CareTask task;

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final pet = widget.state.petById(task.petId);
    final done = task.status == TaskStatus.done;
    return AppSheetFrame(
      title: task.title,
      maxHeightFactor: 0.66,
      footer: done
          ? PrimaryButton(
              label: '恢复为待完成',
              onPressed: () {
                widget.state.reopenTask(task.id);
                showAppMessageAndPop(context, '任务已恢复为待完成');
              },
            )
          : Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: '跳过并说明',
                    ghost: true,
                    onPressed: () {
                      widget.state.skipTask(
                        task.id,
                        note: _noteController.text,
                      );
                      showAppMessageAndPop(context, '已跳过，原因可在任务历史中补充');
                    },
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: PrimaryButton(
                    label: '完成',
                    onPressed: () {
                      widget.state.completeTask(
                        task.id,
                        note: _noteController.text,
                      );
                      showAppMessageAndPop(context, '完成记录已保存到本地');
                    },
                  ),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Callout(message: '${pet.name} · ${task.time} · ${task.type}'),
          if (task.latestRun != null) ...[
            const SizedBox(height: 8),
            Callout(
              type: CalloutType.neutral,
              message:
                  '最近执行：${switch (task.latestRun!.action) {
                    TaskRunAction.completed => '已完成',
                    TaskRunAction.skipped => '已跳过',
                    TaskRunAction.reopened => '已撤销完成',
                  }} · ${PetDates.relativeDateTime(task.latestRun!.performedAt)}'
                  '${task.latestRun!.note.isEmpty ? '' : ' · ${task.latestRun!.note}'}',
            ),
          ],
          const SizedBox(height: 12),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '执行说明',
                  style: AppText.body(12.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  done
                      ? '${task.subtitle}。该任务已完成，执行时间和备注会保留在任务历史中。'
                      : '${task.subtitle}。完成后将保留时间、执行人和备注，不会覆盖上一周期记录。',
                  style: AppText.body(
                    11.5,
                    color: AppColors.muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FormSection(
            label: '备注（可选）',
            child: TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 4,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：温度 29°C，状态活跃'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPetSheet extends StatefulWidget {
  const AddPetSheet({super.key, required this.state, this.onCreated});

  final AppState state;
  final VoidCallback? onCreated;

  @override
  State<AddPetSheet> createState() => _AddPetSheetState();
}

class _AddPetSheetState extends State<AddPetSheet> {
  PetSpecies _species = PetSpecies.gecko;
  final _nameController = TextEditingController();
  final _environmentController = TextEditingController(text: '新的饲养环境');

  @override
  void dispose() {
    _nameController.dispose();
    _environmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '添加动物',
      maxHeightFactor: 0.9,
      footer: PrimaryButton(label: '提交保存', onPressed: _createPet),
      child: Column(
        children: [
          FormSection(
            label: '1 · 选择物种模板',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.state.speciesTemplates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                final species = widget.state.speciesTemplates[index];
                final selected = species == _species;
                return GestureDetector(
                  onTap: () => setState(() => _species = species),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.fromLTRB(8, 13, 8, 10),
                    decoration: BoxDecoration(
                      gradient: selected ? null : species.gradient,
                      color: selected ? AppColors.brandWash : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.brand : AppColors.hair,
                      ),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x332C6A57),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimalArt(
                          species: species,
                          size: 31,
                          color: selected ? AppColors.brand : species.ink,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          species.label,
                          maxLines: 1,
                          style: AppText.body(
                            10.5,
                            color: selected ? AppColors.brand : AppColors.ink2,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          FormSection(
            label: '2 · 动物昵称',
            child: TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：糯米'),
            ),
          ),
          FormSection(
            label: '3 · 环境名称',
            child: TextField(
              controller: _environmentController,
              style: AppText.body(13.5),
            ),
          ),
        ],
      ),
    );
  }

  void _createPet() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppMessage(context, '请填写动物昵称');
      return;
    }
    final created = widget.state.addPet(
      species: _species,
      name: name,
      environment: _environmentController.text.trim().isEmpty
          ? '新的饲养环境'
          : _environmentController.text.trim(),
    );
    if (created == null) {
      showAppMessage(context, '游客模式最多添加 3 只宠物，登录后可继续添加');
      return;
    }
    showAppMessageAndPop(
      context,
      '档案已创建，并生成了首个养护任务',
      afterPop: widget.onCreated,
    );
  }
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, required this.state, this.onCreated});

  final AppState state;
  final VoidCallback? onCreated;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late String _petId = widget.state.pets.first.id;
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '18:00');
  String _type = '环境';

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '新增养护任务',
      maxHeightFactor: 0.82,
      footer: PrimaryButton(label: '创建任务', onPressed: _createTask),
      child: Column(
        children: [
          FormSection(
            label: '关联动物',
            child: BottomSelectField<String>(
              title: '选择动物',
              value: _petId,
              icon: Icons.pets_outlined,
              options: [
                for (final pet in widget.state.pets)
                  BottomSelectOption(value: pet.id, label: pet.name),
              ],
              onChanged: (value) => setState(() => _petId = value),
            ),
          ),
          FormSection(
            label: '任务名称',
            child: TextField(
              controller: _titleController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：检查加热垫'),
            ),
          ),
          FormSection(
            label: '执行时间',
            child: TextField(
              controller: _timeController,
              keyboardType: TextInputType.datetime,
              style: AppText.number(13.5),
              decoration: const InputDecoration(hintText: '18:00'),
            ),
          ),
          FormSection(
            label: '任务类型',
            child: BottomSelectField<String>(
              title: '选择任务类型',
              value: _type,
              icon: Icons.tune_rounded,
              options: const ['环境', '喂食', '清洁', '健康', '设备']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
          ),
        ],
      ),
    );
  }

  void _createTask() {
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
    );
    showAppMessageAndPop(context, '任务已创建', afterPop: widget.onCreated);
  }
}

class HealthLogSheet extends StatefulWidget {
  const HealthLogSheet({
    super.key,
    required this.state,
    this.initialPetId,
    this.lockPet = false,
    this.fullPage = false,
  });

  final AppState state;
  final String? initialPetId;
  final bool lockPet;
  final bool fullPage;

  @override
  State<HealthLogSheet> createState() => _HealthLogSheetState();
}

class _HealthLogSheetState extends State<HealthLogSheet> {
  late String _petId = widget.initialPetId ?? widget.state.pets.first.id;
  String _tag = '日常观察';
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  String? _photoPath;
  DateTime? _followUpAt;
  bool _contactedVet = false;
  bool _savingPhoto = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!widget.fullPage) {
      return AppSheetFrame(
        title: '记录健康观察',
        maxHeightFactor: 0.82,
        footer: PrimaryButton(label: '保存到本地', onPressed: _save),
        child: content,
      );
    }
    final pet = widget.state.petById(_petId);
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
                    title: '记录健康观察',
                    subtitle: '${pet.name} · ${pet.species.label}',
                  ),
                ),
                SliverToBoxAdapter(child: content),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: '保存到本地', onPressed: _save),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        FormSection(
          label: '观察动物',
          child: widget.lockPet
              ? PaperCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: widget.state
                              .petById(_petId)
                              .species
                              .gradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AnimalArt(
                          species: widget.state.petById(_petId).species,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.state.petById(_petId).name,
                          style: AppText.body(13, weight: FontWeight.w600),
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
                      BottomSelectOption(value: pet.id, label: pet.name),
                  ],
                  onChanged: (value) => setState(() => _petId = value),
                ),
        ),
        FormSection(
          label: '观察标签',
          child: BottomSelectField<String>(
            title: '选择观察标签',
            value: _tag,
            icon: Icons.label_outline_rounded,
            options: const ['日常观察', '进食', '饮水', '排便', '蜕皮', '需要复看']
                .map((value) => BottomSelectOption(value: value, label: value))
                .toList(),
            onChanged: (value) => setState(() => _tag = value),
          ),
        ),
        FormSection(
          label: '备注',
          child: TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 6,
            style: AppText.body(13.5),
            decoration: const InputDecoration(hintText: '描述你观察到的变化与持续时间'),
          ),
        ),
        FormSection(
          label: '照片（可选）',
          child: _photoPath == null
              ? GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.hair),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_savingPhoto)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.brand,
                            size: 21,
                          ),
                        const SizedBox(width: 9),
                        Text(
                          _savingPhoto ? '正在保存照片' : '从相册添加照片',
                          style: AppText.body(
                            12.5,
                            color: AppColors.ink2,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    AppLocalImage(
                      path: _photoPath,
                      width: double.infinity,
                      height: 150,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: AppColors.ink.withValues(alpha: 0.72),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => setState(() {
                            _photoPath = null;
                          }),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        FormSection(
          label: _tag == '需要复看' ? '复看时间' : '复看时间（可选）',
          child: GestureDetector(
            onTap: _pickFollowUp,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hair),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _followUpAt == null
                          ? '选择日期和时间'
                          : '${PetDates.relativeDateTime(_followUpAt!)} · '
                                '${PetDates.clock(_followUpAt!)}',
                      style: AppText.body(
                        13,
                        color: _followUpAt == null
                            ? AppColors.faint
                            : AppColors.ink,
                      ),
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
        InkWell(
          onTap: () => setState(() => _contactedVet = !_contactedVet),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _contactedVet,
                  onChanged: (value) =>
                      setState(() => _contactedVet = value ?? false),
                  activeColor: AppColors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('已联系异宠兽医或专业机构', style: AppText.body(12.5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Callout(
          type: CalloutType.warn,
          message: '出现呼吸异常、持续出血或严重受伤时，请尽快联系异宠兽医或专业机构。',
        ),
      ],
    );
  }

  void _save() {
    widget.state.addHealthLog(
      petId: _petId,
      tag: _tag,
      description: _descriptionController.text,
      attachmentPath: _photoPath,
      followUpAt: _followUpAt,
      contactedVet: _contactedVet,
      riskLevel: _tag == '需要复看' ? 'watch' : 'normal',
    );
    showAppMessageAndPop(
      context,
      _followUpAt == null
          ? '已保存到本地'
          : '已保存，并安排在 ${PetDates.relativeDateTime(_followUpAt!)} 复看',
    );
  }

  Future<void> _pickPhoto() async {
    setState(() => _savingPhoto = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 1800,
      );
      if (image == null) return;
      var path = image.path;
      try {
        final documents = await getApplicationDocumentsDirectory();
        final extension = image.name.split('.').lastOrNull ?? 'jpg';
        final target =
            '${documents.path}/health_${DateTime.now().microsecondsSinceEpoch}.$extension';
        await image.saveTo(target);
        path = target;
      } on Object {
        // Keep the picker path when the platform does not expose an app folder.
      }
      if (!mounted) return;
      setState(() {
        _photoPath = path;
      });
    } on Object {
      if (mounted) showAppMessage(context, '无法读取照片，请检查相册权限');
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _pickFollowUp() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: '选择复看日期',
      cancelText: '取消',
      confirmText: '下一步',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _followUpAt ?? now.add(const Duration(hours: 1)),
      ),
      helpText: '选择复看时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (time == null || !mounted) return;
    setState(() {
      _followUpAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class HealthRecordScreen extends StatelessWidget {
  const HealthRecordScreen({
    super.key,
    required this.state,
    required this.petId,
  });

  final AppState state;
  final String petId;

  @override
  Widget build(BuildContext context) {
    return HealthLogSheet(
      state: state,
      initialPetId: petId,
      lockPet: true,
      fullPage: true,
    );
  }
}

class RecordWeightSheet extends StatefulWidget {
  const RecordWeightSheet({super.key, required this.state, required this.pet});

  final AppState state;
  final PetProfile pet;

  @override
  State<RecordWeightSheet> createState() => _RecordWeightSheetState();
}

class _RecordWeightSheetState extends State<RecordWeightSheet> {
  late String _unit = widget.pet.weight.endsWith('kg') ? 'kg' : 'g';
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '记录 ${widget.pet.name} 的体重',
      maxHeightFactor: 0.52,
      footer: PrimaryButton(label: '保存体重', onPressed: _save),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FormSection(
                  label: '体重数值',
                  child: TextField(
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(16),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FormSection(
                  label: '单位',
                  child: BottomSelectField<String>(
                    title: '选择单位',
                    value: _unit,
                    options: const ['g', 'kg']
                        .map(
                          (value) =>
                              BottomSelectOption(value: value, label: value),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _unit = value),
                  ),
                ),
              ),
            ],
          ),
          const Callout(message: '体重数据会追加到生长趋势，并同步写入健康日记。'),
        ],
      ),
    );
  }

  void _save() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      showAppMessage(context, '请输入有效体重');
      return;
    }
    final value = '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1)} $_unit';
    widget.state.updatePetMetrics(widget.pet.id, weight: value);
    widget.state.addHealthLog(
      petId: widget.pet.id,
      tag: '体重记录',
      description: '记录体重 $value。',
    );
    showAppMessageAndPop(context, '体重记录已保存');
  }
}

class ArticleSheet extends StatelessWidget {
  const ArticleSheet({super.key, required this.article});

  final KnowledgeArticle article;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: article.title,
      maxHeightFactor: 0.8,
      footer: PrimaryButton(
        label: '加入复看提醒',
        onPressed: () {
          showAppMessageAndPop(context, '已加入复看提醒');
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Callout(message: '${article.category} · 资料来源：${article.sourceName}'),
          const SizedBox(height: 12),
          for (final section in article.sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PaperCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: AppText.display(16)),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: AppText.body(
                        11.5,
                        color: AppColors.muted,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Callout(
            type: CalloutType.warn,
            message: '内容用于日常观察与照护记录，不能替代兽医检查、诊断或治疗。',
          ),
        ],
      ),
    );
  }
}

class VolumeCalculatorSheet extends StatefulWidget {
  const VolumeCalculatorSheet({super.key});

  @override
  State<VolumeCalculatorSheet> createState() => _VolumeCalculatorSheetState();
}

class _VolumeCalculatorSheetState extends State<VolumeCalculatorSheet> {
  final _lengthController = TextEditingController(text: '60');
  final _widthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _lengthController,
      _widthController,
      _heightController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _lengthController,
      _widthController,
      _heightController,
    ]) {
      controller
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  double? get _volume {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    if (length == null ||
        width == null ||
        height == null ||
        length <= 0 ||
        width <= 0 ||
        height <= 0) {
      return null;
    }
    return length * width * height / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '水体容积换算',
      maxHeightFactor: 0.88,
      footer: PrimaryButton(label: '重新计算', onPressed: () => setState(() {})),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DimensionField(
                  label: '长度（cm）',
                  controller: _lengthController,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DimensionField(
                  label: '宽度（cm）',
                  controller: _widthController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _DimensionField(label: '水位高度（cm）', controller: _heightController),
          const SizedBox(height: 15),
          HeroPanel(
            tag: 'VOLUME · 估算容积',
            title: _volume == null
                ? '请输入有效尺寸'
                : '${_volume!.toStringAsFixed(1)} L',
            description: '不含底砂、造景和设备占用体积',
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          ),
        ],
      ),
    );
  }
}

class _DimensionField extends StatelessWidget {
  const _DimensionField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppText.number(14),
      ),
    );
  }
}

class SalinityCalculatorSheet extends StatefulWidget {
  const SalinityCalculatorSheet({super.key});

  @override
  State<SalinityCalculatorSheet> createState() =>
      _SalinityCalculatorSheetState();
}

class _SalinityCalculatorSheetState extends State<SalinityCalculatorSheet> {
  final _volumeController = TextEditingController(text: '100');
  final _changeController = TextEditingController(text: '10');
  final _salinityController = TextEditingController(text: '35');

  @override
  void dispose() {
    _volumeController.dispose();
    _changeController.dispose();
    _salinityController.dispose();
    super.dispose();
  }

  double? get _volume => double.tryParse(_volumeController.text);
  double? get _changePercent => double.tryParse(_changeController.text);
  double? get _salinity => double.tryParse(_salinityController.text);

  double? get _changeVolume {
    final volume = _volume;
    final percent = _changePercent;
    if (volume == null || percent == null || volume <= 0 || percent <= 0) {
      return null;
    }
    return volume * percent / 100;
  }

  double? get _saltGrams {
    final volume = _volume;
    final percent = _changePercent;
    final salinity = _salinity;
    if (volume == null ||
        percent == null ||
        salinity == null ||
        volume <= 0 ||
        percent <= 0 ||
        salinity <= 0) {
      return null;
    }
    return volume * percent / 100 * salinity;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '盐度与换水配比',
      maxHeightFactor: 0.86,
      footer: PrimaryButton(label: '重新计算', onPressed: () => setState(() {})),
      child: Column(
        children: [
          const Callout(message: '按计划换水比例和目标盐度估算需要准备的盐量，不替代盐度计读数。'),
          const SizedBox(height: 14),
          _DimensionField(label: '鱼缸水量（L）', controller: _volumeController),
          const SizedBox(height: 12),
          _DimensionField(label: '本次换水比例（%）', controller: _changeController),
          const SizedBox(height: 12),
          _DimensionField(label: '目标盐度（g/L）', controller: _salinityController),
          const SizedBox(height: 15),
          PaperCard(
            child: Row(
              children: [
                Expanded(
                  child: _ToolResult(
                    label: '换水量',
                    value: _changeVolume == null
                        ? '--'
                        : '${_changeVolume!.toStringAsFixed(1)} L',
                  ),
                ),
                const SizedBox(
                  height: 34,
                  child: VerticalDivider(width: 20, color: AppColors.hair),
                ),
                Expanded(
                  child: _ToolResult(
                    label: '建议配盐',
                    value: _saltGrams == null
                        ? '--'
                        : '${_saltGrams!.toStringAsFixed(0)} g',
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

class EquipmentLifeSheet extends StatefulWidget {
  const EquipmentLifeSheet({super.key});

  @override
  State<EquipmentLifeSheet> createState() => _EquipmentLifeSheetState();
}

class _EquipmentLifeSheetState extends State<EquipmentLifeSheet> {
  String _type = 'UVB 灯';
  int _ratedMonths = 12;
  final _usedController = TextEditingController(text: '0');

  @override
  void dispose() {
    _usedController.dispose();
    super.dispose();
  }

  int? get _remainingDays {
    final used = double.tryParse(_usedController.text);
    if (used == null || used < 0) return null;
    return ((_ratedMonths - used) * 30.44).round();
  }

  @override
  Widget build(BuildContext context) {
    final remainingDays = _remainingDays;
    final replacementDate = remainingDays == null
        ? null
        : DateTime.now().add(Duration(days: remainingDays));
    return AppSheetFrame(
      title: '设备寿命倒计时',
      maxHeightFactor: 0.86,
      footer: PrimaryButton(label: '重新计算', onPressed: () => setState(() {})),
      child: Column(
        children: [
          FormSection(
            label: '设备类型',
            child: BottomSelectField<String>(
              title: '选择设备',
              value: _type,
              icon: Icons.settings_input_component_outlined,
              options: const ['UVB 灯', '滤材', '滤网']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
          ),
          FormSection(
            label: '标称寿命',
            child: BottomSelectField<int>(
              title: '选择寿命',
              value: _ratedMonths,
              icon: Icons.timelapse_rounded,
              options: const [6, 12, 24]
                  .map(
                    (value) =>
                        BottomSelectOption(value: value, label: '$value 个月'),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _ratedMonths = value),
            ),
          ),
          _DimensionField(label: '已经使用（月）', controller: _usedController),
          const SizedBox(height: 15),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_type, style: AppText.body(11, color: AppColors.muted)),
                const SizedBox(height: 7),
                Text(
                  remainingDays == null
                      ? '请输入有效月数'
                      : remainingDays <= 0
                      ? '已达到建议更换时间'
                      : '预计还可使用 $remainingDays 天',
                  style: AppText.display(20),
                ),
                if (replacementDate != null &&
                    remainingDays != null &&
                    remainingDays > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    '建议在 ${PetDates.reportDate(replacementDate)} 前检查或更换',
                    style: AppText.body(10.5, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Callout(message: '更换周期应以设备说明、实际运行时长和检测结果为准。UVB 灯即使仍亮也可能衰减。'),
        ],
      ),
    );
  }
}

class _ToolResult extends StatelessWidget {
  const _ToolResult({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(10, color: AppColors.muted)),
        const SizedBox(height: 5),
        Text(value, style: AppText.number(18, weight: FontWeight.w700)),
      ],
    );
  }
}

class DeleteDemoSheet extends StatelessWidget {
  const DeleteDemoSheet({
    super.key,
    required this.state,
    required this.onReset,
  });

  final AppState state;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '删除演示数据？',
      maxHeightFactor: 0.52,
      footer: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: '取消',
              ghost: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: PrimaryButton(
              label: '删除演示数据',
              onPressed: () {
                state.resetDemo();
                showAppMessageAndPop(context, '演示数据已重置', afterPop: onReset);
              },
            ),
          ),
        ],
      ),
      child: const Callout(
        type: CalloutType.danger,
        message: '此操作只影响当前演示中的本地体验数据。正式产品会提供导出、7 天撤销窗口和身份验证。',
      ),
    );
  }
}

class ReportPreviewSheet extends StatelessWidget {
  const ReportPreviewSheet({
    super.key,
    required this.state,
    required this.reportType,
  });

  final AppState state;
  final String reportType;

  @override
  Widget build(BuildContext context) {
    final pet = state.pets.first;
    return AppSheetFrame(
      title: '报告预览',
      maxHeightFactor: 0.82,
      footer: PrimaryButton(
        label: '生成并保存报告',
        icon: Icons.file_download_outlined,
        onPressed: () async {
          try {
            await ReportPdfService.share(state: state, reportType: reportType);
          } on Object {
            if (context.mounted) {
              showAppMessage(context, '报告生成失败，请稍后重试');
            }
          }
        },
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              reportType,
              style: AppText.body(
                9.5,
                color: AppColors.brass,
                weight: FontWeight.w700,
                spacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          PaperCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('栖护', style: AppText.display(16)),
                    const Spacer(),
                    Text(
                      PetDates.reportDate(DateTime.now()),
                      style: AppText.number(10, color: AppColors.faint),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: pet.species.gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: AnimalArt(species: pet.species, size: 34),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet.name, style: AppText.display(17)),
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
        ],
      ),
    );
  }
}
