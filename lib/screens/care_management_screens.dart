import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';
import 'create_screens.dart';

class SpeciesTemplateLibraryScreen extends StatefulWidget {
  const SpeciesTemplateLibraryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SpeciesTemplateLibraryScreen> createState() =>
      _SpeciesTemplateLibraryScreenState();
}

class _SpeciesTemplateLibraryScreenState
    extends State<SpeciesTemplateLibraryScreen> {
  final _searchController = TextEditingController();
  String _category = '全部';
  String? _revealedTemplateId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final categories = ['全部', ...widget.state.speciesCategories];
    final templates = widget.state.speciesTemplates.where((template) {
      final inCategory = _category == '全部' || template.category == _category;
      final inQuery =
          query.isEmpty ||
          '${template.label} ${template.category} ${template.code}'
              .toLowerCase()
              .contains(query);
      return inCategory && inQuery;
    }).toList();

    return _ManagementPage(
      title: '宠物模板库',
      subtitle: '内置目录 · 自定义模板',
      action: RoundIconButton(
        icon: Icons.add_rounded,
        onPressed: () => _openAddTemplate(context),
      ),
      children: [
        const Callout(
          message:
              '模板会预填分类与展示信息。饲养前仍需确认物种来源和当地法规；'
              '不同地区的可饲养范围可能不同。',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: AppText.body(13),
          decoration: const InputDecoration(
            hintText: '搜索猫、狗、袋鼠或鱼类模板',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.faint,
              size: 18,
            ),
          ),
        ),
        ChipRow(
          labels: categories,
          selected: _category,
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 8),
        if (templates.isEmpty)
          const EmptyState(title: '没有匹配的模板', message: '可以更换分类或搜索关键词。')
        else
          for (final template in templates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TemplateSwipeTile(
                key: ValueKey(template.id),
                template: template,
                revealed: _revealedTemplateId == template.id,
                onReveal: () =>
                    setState(() => _revealedTemplateId = template.id),
                onClose: () {
                  if (_revealedTemplateId == template.id) {
                    setState(() => _revealedTemplateId = null);
                  }
                },
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SpeciesTemplateDetailScreen(
                      state: widget.state,
                      templateId: template.id,
                    ),
                  ),
                ),
                onDelete: () => _confirmDeleteTemplate(template),
              ),
            ),
      ],
    );
  }

  Future<void> _confirmDeleteTemplate(PetSpecies template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板？'),
        content: Text('删除“${template.label}”后将无法从模板库选择，但已创建的动物档案不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = widget.state.deleteSpeciesTemplate(template.id);
    if (!mounted) return;
    setState(() {});
    if (!deleted) {
      showAppMessage(context, '至少需要保留一个动物模板');
    }
  }

  Future<void> _openAddTemplate(BuildContext context) async {
    await showAppSheet(
      context: context,
      child: AddSpeciesTemplateSheet(state: widget.state),
    );
    if (mounted) setState(() {});
  }
}

class _TemplateSwipeTile extends StatefulWidget {
  const _TemplateSwipeTile({
    super.key,
    required this.template,
    required this.revealed,
    required this.onReveal,
    required this.onClose,
    required this.onOpen,
    required this.onDelete,
  });

  final PetSpecies template;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_TemplateSwipeTile> createState() => _TemplateSwipeTileState();
}

class _TemplateSwipeTileState extends State<_TemplateSwipeTile> {
  static const _deleteWidth = 82.0;
  double _offset = 0;

  @override
  void didUpdateWidget(covariant _TemplateSwipeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealed && !widget.revealed) {
      _offset = 0;
    }
  }

  void _handleDragStart(DragStartDetails details) {
    widget.onReveal();
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx)
          .clamp(-_deleteWidth, 0.0)
          .toDouble();
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _offset = _offset < -_deleteWidth * 0.38 ? -_deleteWidth : 0;
    });
    if (_offset == 0) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth + _offset)
            .clamp(0.0, constraints.maxWidth)
            .toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _deleteWidth,
                    child: Material(
                      color: AppColors.rose,
                      child: InkWell(
                        onTap: widget.onDelete,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(height: 3),
                            Text(
                              '删除',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: contentWidth,
                  child: GestureDetector(
                    onHorizontalDragStart: _handleDragStart,
                    onHorizontalDragUpdate: _handleDrag,
                    onHorizontalDragEnd: _handleDragEnd,
                    child: Material(
                      color: AppColors.paper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: const BorderSide(color: AppColors.hair),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_offset < 0) {
                            setState(() => _offset = 0);
                            widget.onClose();
                          }
                          widget.onOpen();
                        },
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: template.gradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: AnimalArt(species: template, size: 28),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.display(15.5),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${template.category} · ${template.code}',
                                      style: AppText.body(
                                        9.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!template.builtIn)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brassWash,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '自定义',
                                    style: AppText.body(
                                      7.5,
                                      color: AppColors.brass,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SpeciesTemplateDetailScreen extends StatefulWidget {
  const SpeciesTemplateDetailScreen({
    super.key,
    required this.state,
    required this.templateId,
  });

  final AppState state;
  final String templateId;

  @override
  State<SpeciesTemplateDetailScreen> createState() =>
      _SpeciesTemplateDetailScreenState();
}

class _SpeciesTemplateDetailScreenState
    extends State<SpeciesTemplateDetailScreen> {
  PetSpecies? get template => widget.state.speciesTemplates
      .where((item) => item.id == widget.templateId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = template;
    if (current == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: const SafeArea(
          child: EmptyState(title: '模板不存在', message: '该模板可能已经被删除。'),
        ),
      );
    }
    return _ManagementPage(
      title: '模板详情',
      subtitle: current.category,
      action: const SizedBox.shrink(),
      children: [
        _TemplateDetailBody(
          template: current,
          onEdit: _editTemplate,
          onDelete: _deleteTemplate,
          onAddTask: () => _editFixedTask(),
          onEditTask: (index) => _editFixedTask(index: index),
          onDeleteTask: _deleteFixedTask,
        ),
      ],
    );
  }

  Future<void> _editTemplate() async {
    final current = template;
    if (current == null) return;
    await showAppSheet(
      context: context,
      child: AddSpeciesTemplateSheet(state: widget.state, existing: current),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteTemplate() async {
    final current = template;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板？'),
        content: Text('删除“${current.label}”后将无法从模板库选择，但已创建的动物档案不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = widget.state.deleteSpeciesTemplate(current.id);
    if (!mounted) return;
    if (deleted) {
      Navigator.pop(context);
    } else {
      showAppMessage(context, '至少需要保留一个动物模板');
    }
  }

  Future<void> _editFixedTask({int? index}) async {
    final current = template;
    if (current == null) return;
    final tasks = starterCareTasksFor(current);
    final result = await showModalBottomSheet<StarterCareTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StarterTaskEditorSheet(initial: index == null ? null : tasks[index]),
    );
    if (result == null || !mounted) return;
    final nextTasks = List<StarterCareTask>.from(tasks);
    if (index == null) {
      nextTasks.add(result);
    } else {
      nextTasks[index] = result;
    }
    _saveFixedTasks(nextTasks);
  }

  Future<void> _deleteFixedTask(int index) async {
    final current = template;
    if (current == null) return;
    final tasks = starterCareTasksFor(current);
    if (index < 0 || index >= tasks.length) return;
    final task = tasks[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除固定任务？'),
        content: Text('删除“${task.title}”后，新动物不会再自动生成这项任务。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final nextTasks = List<StarterCareTask>.from(tasks)..removeAt(index);
    _saveFixedTasks(nextTasks);
  }

  void _saveFixedTasks(List<StarterCareTask> tasks) {
    final current = template;
    if (current == null) return;
    widget.state.updateSpeciesTemplate(
      existing: current,
      label: current.label,
      category: current.category,
      artStyle: current.artStyle,
      background: current.background,
      backgroundEnd: current.backgroundEnd,
      ink: current.ink,
      note: current.note,
      starterTasks: tasks,
    );
    setState(() {});
  }
}

class _TemplateDetailBody extends StatelessWidget {
  const _TemplateDetailBody({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final PetSpecies template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddTask;
  final ValueChanged<int> onEditTask;
  final ValueChanged<int> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final tasks = starterCareTasksFor(template);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaperCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: template.gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: AnimalArt(species: template, size: 42),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.label, style: AppText.display(21)),
                    const SizedBox(height: 4),
                    Text(
                      '${template.category} · ${template.code}',
                      style: AppText.body(10.5, color: AppColors.muted),
                    ),
                    if (template.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        template.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(10, color: AppColors.faint),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Callout(message: '使用此模板新增动物后，系统会自动创建以下固定任务。'),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('固定任务', style: AppText.display(16)),
            const Spacer(),
            Text(
              '${tasks.length} 项',
              style: AppText.body(10, color: AppColors.muted),
            ),
            const SizedBox(width: 7),
            RoundIconButton(
              icon: Icons.add_rounded,
              size: 30,
              onPressed: onAddTask,
              foreground: AppColors.brand,
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (var index = 0; index < tasks.length; index++) ...[
          _StarterTaskCard(
            task: tasks[index],
            petName: template.label,
            onTap: () => onEditTask(index),
            onDelete: () => onDeleteTask(index),
          ),
          if (index < tasks.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onEdit, child: const Text('编辑')),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rose,
                  side: BorderSide(
                    color: AppColors.rose.withValues(alpha: 0.45),
                  ),
                ),
                onPressed: onDelete,
                child: const Text('删除'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StarterTaskCard extends StatelessWidget {
  const _StarterTaskCard({
    required this.task,
    required this.petName,
    required this.onTap,
    required this.onDelete,
  });

  final StarterCareTask task;
  final String petName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isMust = task.priority == TaskPriority.must;
    return GestureDetector(
      onTap: onTap,
      child: PaperCard(
        padding: const EdgeInsets.fromLTRB(13, 11, 6, 11),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isMust ? AppColors.roseWash : AppColors.brassWash,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(
                task.time,
                style: AppText.number(
                  10.5,
                  color: isMust ? AppColors.rose : AppColors.brass,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
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
                          color: isMust
                              ? AppColors.roseWash
                              : AppColors.brassWash,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isMust ? '必做' : '建议',
                          style: AppText.body(
                            7.5,
                            color: isMust ? AppColors.rose : AppColors.brass,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(11.5, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.type,
                          style: AppText.body(
                            8.5,
                            color: AppColors.muted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(12.5, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    task.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(9.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '删除固定任务',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePalette {
  const _TemplatePalette(
    this.name,
    this.background,
    this.backgroundEnd,
    this.ink,
  );

  final String name;
  final Color background;
  final Color backgroundEnd;
  final Color ink;
}

class AddSpeciesTemplateSheet extends StatefulWidget {
  const AddSpeciesTemplateSheet({
    super.key,
    required this.state,
    this.existing,
  });

  final AppState state;
  final PetSpecies? existing;

  @override
  State<AddSpeciesTemplateSheet> createState() =>
      _AddSpeciesTemplateSheetState();
}

class _AddSpeciesTemplateSheetState extends State<AddSpeciesTemplateSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final _categoryController = TextEditingController(
    text: widget.existing?.category ?? '异宠',
  );
  late final _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late String _artStyle = widget.existing?.artStyle ?? 'paw';
  late int _paletteIndex = _initialPaletteIndex();
  late final List<StarterCareTask> _starterTasks = widget.existing == null
      ? starterCareTasksFor(
          const PetSpecies(
            id: 'template-preview',
            label: '模板预览',
            category: '异宠',
            background: Color(0xFFEAE6E1),
            backgroundEnd: Color(0xFFD9D2CB),
            ink: Color(0xFF5E564C),
            artStyle: 'paw',
            code: 'PREVIEW',
          ),
        )
      : starterCareTasksFor(widget.existing!);

  static const _palettes = [
    _TemplatePalette(
      '墨绿',
      Color(0xFFE3ECE7),
      Color(0xFFC6D8CF),
      Color(0xFF2C5546),
    ),
    _TemplatePalette(
      '暖砂',
      Color(0xFFF1E7D2),
      Color(0xFFE4D4B2),
      Color(0xFF7A5B2A),
    ),
    _TemplatePalette(
      '水蓝',
      Color(0xFFE2EAF3),
      Color(0xFFCCDCEA),
      Color(0xFF3A5B7D),
    ),
    _TemplatePalette(
      '灰岩',
      Color(0xFFEAE6E1),
      Color(0xFFD9D2CB),
      Color(0xFF5E564C),
    ),
    _TemplatePalette(
      '紫藤',
      Color(0xFFEDE7F3),
      Color(0xFFDACDE7),
      Color(0xFF624C78),
    ),
    _TemplatePalette(
      '蔷薇',
      Color(0xFFF4E5E8),
      Color(0xFFE8CCD2),
      Color(0xFF7E4B57),
    ),
    _TemplatePalette(
      '深海',
      Color(0xFFE0E9EE),
      Color(0xFFC5D9E3),
      Color(0xFF31546A),
    ),
    _TemplatePalette(
      '苔绿',
      Color(0xFFE7EEE1),
      Color(0xFFD0DEC5),
      Color(0xFF4D6440),
    ),
    _TemplatePalette(
      '杏桃',
      Color(0xFFF6E8DF),
      Color(0xFFEED2BF),
      Color(0xFF7C5A46),
    ),
    _TemplatePalette(
      '雾蓝',
      Color(0xFFE8EDF1),
      Color(0xFFD1DAE2),
      Color(0xFF4E6172),
    ),
    _TemplatePalette(
      '茶金',
      Color(0xFFF2EBDC),
      Color(0xFFE0D1B4),
      Color(0xFF725F3C),
    ),
    _TemplatePalette(
      '松墨',
      Color(0xFFE2E9E6),
      Color(0xFFC9D8D2),
      Color(0xFF315147),
    ),
  ];

  static const _artStyles = [
    ('paw', '通用爪印'),
    ('cat', '猫'),
    ('dog', '狗'),
    ('rabbit', '兔'),
    ('rodent', '啮齿'),
    ('mustelid', '雪貂'),
    ('hedgehog', '刺猬'),
    ('glider', '蜜袋鼯'),
    ('marsupial', '有袋类'),
    ('gecko', '守宫'),
    ('beardedDragon', '鬃狮蜥'),
    ('reptile', '爬宠'),
    ('snake', '蛇类'),
    ('tortoise', '陆龟'),
    ('bird', '鸟类'),
    ('cockatiel', '玄凤鹦鹉'),
    ('waterfowl', '水禽'),
    ('fish', '鱼类'),
    ('betta', '斗鱼'),
    ('amphibian', '两栖'),
    ('crustacean', '甲壳'),
    ('snail', '螺类'),
    ('insect', '昆虫'),
    ('tarantula', '捕鸟蛛'),
  ];

  int _initialPaletteIndex() {
    final existing = widget.existing;
    if (existing == null) return 0;
    final index = _palettes.indexWhere(
      (palette) =>
          palette.background.toARGB32() == existing.background.toARGB32() &&
          palette.backgroundEnd.toARGB32() ==
              existing.backgroundEnd.toARGB32() &&
          palette.ink.toARGB32() == existing.ink.toARGB32(),
    );
    return index < 0 ? 0 : index;
  }

  PetSpecies _previewSpecies(String artStyle) {
    final palette = _palettes[_paletteIndex];
    return PetSpecies(
      id: 'preview-$artStyle',
      label: '图形预览',
      category: _categoryController.text.trim(),
      background: palette.background,
      backgroundEnd: palette.backgroundEnd,
      ink: palette.ink,
      artStyle: artStyle,
      code: 'PREVIEW',
      builtIn: false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: widget.existing == null ? '新增宠物模板' : '编辑宠物模板',
      maxHeightFactor: 0.9,
      shrinkToContent: true,
      footer: PrimaryButton(label: '保存模板', onPressed: _save),
      child: Column(
        children: [
          FormSection(
            label: '模板名称',
            child: TextField(
              controller: _nameController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：布偶猫、金毛'),
            ),
          ),
          FormSection(
            label: '分类',
            child: TextField(
              controller: _categoryController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：哺乳、水族、异宠'),
            ),
          ),
          FormSection(
            label: '图形类型',
            child: InkWell(
              onTap: _pickArtStyle,
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
                    AnimalArt(species: _previewSpecies(_artStyle), size: 24),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _artStyleLabel(_artStyle),
                        style: AppText.body(13.5),
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
          FormSection(
            label: '配色',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _palettes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                mainAxisExtent: 48,
              ),
              itemBuilder: (context, index) {
                final palette = _palettes[index];
                return GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _paletteIndex = index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.background, palette.backgroundEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _paletteIndex == index
                            ? AppColors.brand
                            : AppColors.hair,
                        width: _paletteIndex == index ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      palette.name,
                      style: AppText.body(
                        9,
                        color: palette.ink,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          FormSection(
            label: '备注',
            child: TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              style: AppText.body(13),
              decoration: const InputDecoration(hintText: '记录物种别名、饲养类型或法规提醒'),
            ),
          ),
        ],
      ),
    );
  }

  String _artStyleLabel(String value) {
    return _artStyles
        .firstWhere((item) => item.$1 == value, orElse: () => ('paw', '通用爪印'))
        .$2;
  }

  Future<void> _pickArtStyle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheetFrame(
        title: '选择图形类型',
        maxHeightFactor: 0.76,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _artStyles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 78,
          ),
          itemBuilder: (context, index) {
            final item = _artStyles[index];
            final active = item.$1 == _artStyle;
            return InkWell(
              onTap: () => Navigator.pop(context, item.$1),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                decoration: BoxDecoration(
                  color: active ? AppColors.brandWash : AppColors.paper2,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: active ? AppColors.brand : AppColors.hair,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimalArt(species: _previewSpecies(item.$1), size: 27),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        8.5,
                        color: active ? AppColors.brand : AppColors.muted,
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
    );
    if (selected != null && mounted) setState(() => _artStyle = selected);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppMessage(context, '请填写模板名称');
      return;
    }
    final palette = _palettes[_paletteIndex];
    final existing = widget.existing;
    if (existing == null) {
      widget.state.addSpeciesTemplate(
        label: name,
        category: _categoryController.text,
        artStyle: _artStyle,
        background: palette.background,
        backgroundEnd: palette.backgroundEnd,
        ink: palette.ink,
        note: _noteController.text,
        starterTasks: List<StarterCareTask>.from(_starterTasks),
      );
    } else {
      widget.state.updateSpeciesTemplate(
        existing: existing,
        label: name,
        category: _categoryController.text,
        artStyle: _artStyle,
        background: palette.background,
        backgroundEnd: palette.backgroundEnd,
        ink: palette.ink,
        note: _noteController.text,
        starterTasks: List<StarterCareTask>.from(_starterTasks),
      );
    }
    showAppMessageAndPop(context, '模板已保存');
  }
}

class _StarterTaskEditorSheet extends StatefulWidget {
  const _StarterTaskEditorSheet({this.initial});

  final StarterCareTask? initial;

  @override
  State<_StarterTaskEditorSheet> createState() =>
      _StarterTaskEditorSheetState();
}

class _StarterTaskEditorSheetState extends State<_StarterTaskEditorSheet> {
  late final _titleController = TextEditingController(
    text: widget.initial?.title ?? '',
  );
  late final _subtitleController = TextEditingController(
    text: widget.initial?.subtitle ?? '',
  );
  late TimeOfDay _time = _parseTime(widget.initial?.time ?? '18:00');
  late String _type = widget.initial?.type ?? '环境';
  late bool _must = widget.initial?.priority == TaskPriority.must;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: widget.initial == null ? '添加固定任务' : '编辑固定任务',
      maxHeightFactor: 0.78,
      shrinkToContent: true,
      footer: PrimaryButton(label: '保存任务', onPressed: _save),
      child: Column(
        children: [
          FormSection(
            label: '任务名称',
            child: TextField(
              controller: _titleController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：检查温湿度'),
            ),
          ),
          FormSection(
            label: '执行时间',
            child: InkWell(
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
          FormSection(
            label: '任务类型',
            child: BottomSelectField<String>(
              title: '选择任务类型',
              value: _type,
              options: const ['环境', '喂食', '清洁', '健康', '设备', '称重']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
            ),
          ),
          FormSection(
            label: '任务说明',
            child: TextField(
              controller: _subtitleController,
              minLines: 2,
              maxLines: 3,
              style: AppText.body(13),
              decoration: const InputDecoration(hintText: '说明检查内容或执行标准'),
            ),
          ),
          FormSection(
            label: '优先级',
            child: BottomSelectField<String>(
              title: '选择优先级',
              value: _must ? '必做' : '建议',
              options: const [
                BottomSelectOption(value: '必做', label: '必做'),
                BottomSelectOption(value: '建议', label: '建议'),
              ],
              onChanged: (value) => setState(() => _must = value == '必做'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppMessage(context, '请填写任务名称');
      return;
    }
    Navigator.pop(
      context,
      StarterCareTask(
        title: title,
        subtitle: _subtitleController.text.trim(),
        type: _type,
        time: _formatTime(_time),
        priority: _must ? TaskPriority.must : TaskPriority.suggested,
      ),
    );
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 18, minute: 0);
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return const TimeOfDay(hour: 18, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
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
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _ManagementPage(
      title: '饲养空间',
      subtitle: '房间 · 环境 · 温控',
      action: RoundIconButton(
        icon: Icons.add_rounded,
        onPressed: () => showAppSheet(
          context: context,
          child: AddRoomSheet(state: widget.state),
        ),
      ),
      children: [
        for (final room in widget.state.rooms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => showAppSheet(
                context: context,
                child: AddRoomSheet(state: widget.state, existing: room),
              ),
              borderRadius: BorderRadius.circular(20),
              child: PaperCard(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandWash,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.brandLine),
                      ),
                      child: Icon(room.icon, color: AppColors.brand, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _RoomTypeBadge(type: room.type),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  room.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.display(17),
                                ),
                              ),
                            ],
                          ),
                          if (room.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              room.notes,
                              style: AppText.body(
                                10,
                                color: AppColors.faint,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _RoomTypeBadge extends StatelessWidget {
  const _RoomTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (type) {
      '温控房间' => (AppColors.amberWash, AppColors.amber),
      '水族空间' => (AppColors.blueWash, AppColors.blue),
      '阳台' || '室外围栏' => (AppColors.brassWash, AppColors.brass),
      '隔离空间' || '医疗观察区' => (AppColors.roseWash, AppColors.rose),
      '公共空间' => (AppColors.brandWash, AppColors.brand),
      _ => (AppColors.paper2, AppColors.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Text(
        type,
        style: AppText.body(8.5, color: foreground, weight: FontWeight.w700),
      ),
    );
  }
}

class DailyNeedsScreen extends StatefulWidget {
  const DailyNeedsScreen({super.key, required this.state, this.petId});

  final AppState state;
  final String? petId;

  @override
  State<DailyNeedsScreen> createState() => _DailyNeedsScreenState();
}

class _DailyNeedsScreenState extends State<DailyNeedsScreen> {
  AppState get state => widget.state;
  String? get petId => widget.petId;

  @override
  void initState() {
    super.initState();
    state.addListener(_refresh);
  }

  @override
  void dispose() {
    state.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visiblePets = state.pets
        .where((pet) => petId == null || pet.id == petId)
        .toList();
    final selectedPet = petId == null ? null : state.petByIdOrNull(petId!);
    return _ManagementPage(
      title: petId == null ? '养护任务' : '${selectedPet?.name ?? '当前宠物'}的养护任务',
      subtitle: '创建一次 · 按重复规则自动生成',
      action: visiblePets.isEmpty
          ? const SizedBox.shrink()
          : RoundIconButton(
              icon: Icons.add_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AddTaskScreen(
                    state: state,
                    initialPetId: petId,
                    initialRecurring: true,
                    lockPet: petId != null,
                  ),
                ),
              ),
            ),
      children: visiblePets.isEmpty
          ? const [
              EmptyState(
                title: '暂无养护任务',
                message: '养护任务需要关联宠物档案，请先在“动物”页面添加宠物。',
              ),
            ]
          : [
              for (final pet in visiblePets) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: pet.species.gradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AnimalArt(species: pet.species, size: 22),
                      ),
                      const SizedBox(width: 9),
                      Text(pet.name, style: AppText.display(16)),
                      const SizedBox(width: 7),
                      Text(
                        pet.species.label,
                        style: AppText.body(9.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (state.taskDefinitions
                    .where((item) => item.petId == pet.id)
                    .isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: EmptyState(
                      title: '还没有养护任务',
                      message: '可以为这只宠物设置喂食、清洁、环境检查等每日固定需求。',
                    ),
                  )
                else
                  for (final definition in state.taskDefinitions.where(
                    (item) => item.petId == pet.id,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showNeedDetail(context, definition, pet),
                          borderRadius: BorderRadius.circular(20),
                          child: PaperCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color:
                                        definition.priority == TaskPriority.must
                                        ? AppColors.roseWash
                                        : AppColors.brassWash,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    definition.defaultTime,
                                    style: AppText.number(
                                      10.5,
                                      color:
                                          definition.priority ==
                                              TaskPriority.must
                                          ? AppColors.rose
                                          : AppColors.brass,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 160),
                                    opacity: definition.enabled ? 1 : 0.5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            _DefinitionPriorityBadge(
                                              priority: definition.priority,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${definition.type}：',
                                                      style: AppText.body(
                                                        10.5,
                                                        color: AppColors.muted,
                                                        weight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: definition.title,
                                                      style: AppText.body(
                                                        13.5,
                                                        weight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '重复方式：${definition.repeatDescription}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.body(
                                            10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: definition.enabled,
                                  onChanged: (value) =>
                                      state.setTaskDefinitionEnabled(
                                        definition.id,
                                        value,
                                      ),
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: AppColors.brand,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: AppColors.paper3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ],
    );
  }

  void _showNeedDetail(
    BuildContext context,
    CareTaskDefinition definition,
    PetProfile pet,
  ) {
    showAppSheet(
      context: context,
      child: _DailyNeedDetailSheet(
        state: state,
        definition: definition,
        pet: pet,
      ),
    );
  }
}

class _DefinitionPriorityBadge extends StatelessWidget {
  const _DefinitionPriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final isMust = priority == TaskPriority.must;
    final color = isMust ? AppColors.rose : AppColors.brass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMust ? AppColors.roseWash : AppColors.brassWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isMust ? '必做' : '建议',
        style: AppText.body(8, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

class _DailyNeedDetailSheet extends StatelessWidget {
  const _DailyNeedDetailSheet({
    required this.state,
    required this.definition,
    required this.pet,
  });

  final AppState state;
  final CareTaskDefinition definition;
  final PetProfile pet;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '养护任务',
      maxHeightFactor: 0.7,
      footer: Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: '编辑',
              ghost: true,
              onPressed: () => _edit(context),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      definition.defaultTime,
                      style: AppText.number(13, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.enabled ? '已启用' : '已暂停',
                      style: AppText.body(
                        9,
                        color: definition.enabled
                            ? AppColors.brand
                            : AppColors.faint,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DefinitionPriorityBadge(priority: definition.priority),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${definition.type}：${definition.title}',
                        style: AppText.body(14, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailValueRow(
                  label: '重复方式',
                  value: definition.repeatDescription,
                ),
                const SizedBox(height: 9),
                _DetailValueRow(
                  label: '任务说明',
                  value: definition.subtitle.isEmpty
                      ? '暂无任务说明'
                      : definition.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('删除养护任务？', style: AppText.display(19)),
        content: Text(
          '删除后，该任务及已经生成的当天和后续任务都会从档案中移除，且不再继续生成。',
          style: AppText.body(12, color: AppColors.muted, height: 1.6),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    state.deleteTaskDefinition(definition.id);
    showAppMessageAndPop(context, '养护任务已删除');
  }
}

class _DetailValueRow extends StatelessWidget {
  const _DetailValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(label, style: AppText.body(10, color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppText.body(
              11,
              color: AppColors.ink2,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AddRoomSheet extends StatefulWidget {
  const AddRoomSheet({super.key, required this.state, this.existing});

  final AppState state;
  final PetRoom? existing;

  @override
  State<AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<AddRoomSheet> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes ?? '',
  );
  late final _customTypeController = TextEditingController(
    text: widget.existing != null && !_types.contains(widget.existing!.type)
        ? widget.existing!.type
        : '',
  );
  late String _type = widget.existing?.type ?? '室内';
  late bool _customType =
      widget.existing != null && !_types.contains(widget.existing!.type);
  late IconData _icon =
      widget.existing?.icon ??
      defaultRoomIconForType(widget.existing?.type ?? '室内');

  static const _types = [
    '室内',
    '温控房间',
    '水族空间',
    '阳台',
    '室外围栏',
    '饲养柜',
    '隔离空间',
    '繁殖空间',
    '活动区',
    '医疗观察区',
    '公共空间',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: widget.existing == null ? '新增饲养空间' : '编辑饲养空间',
      maxHeightFactor: 0.86,
      footer: Row(
        children: [
          if (widget.existing != null) ...[
            Expanded(
              child: PrimaryButton(
                label: '删除',
                ghost: true,
                onPressed: _delete,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: PrimaryButton(
              label: widget.existing == null ? '保存房间' : '保存修改',
              onPressed: _save,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormSection(
            label: '房间名称',
            child: TextField(
              controller: _nameController,
              style: AppText.body(13.5),
              decoration: const InputDecoration(hintText: '例如：爬宠房'),
            ),
          ),
          FormSection(
            label: '空间类型',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in _types)
                      _RoomTypeChoice(
                        label: type,
                        selected: !_customType && _type == type,
                        onTap: () => setState(() {
                          _type = type;
                          _customType = false;
                        }),
                      ),
                    _RoomTypeChoice(
                      label: '自定义',
                      selected: _customType,
                      onTap: () => setState(() => _customType = true),
                    ),
                  ],
                ),
                if (_customType) ...[
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('room-custom-type-field'),
                    controller: _customTypeController,
                    style: AppText.body(13),
                    decoration: const InputDecoration(hintText: '输入自定义空间类型'),
                  ),
                ],
              ],
            ),
          ),
          FormSection(
            label: '空间图标',
            child: Wrap(
              key: const ValueKey('room-icon-options'),
              alignment: WrapAlignment.start,
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final option in roomIconOptions)
                  _RoomIconChoice(
                    key: ValueKey('room-icon-${option.$1}'),
                    icon: option.$2,
                    selected: _icon.codePoint == option.$2.codePoint,
                    onTap: () => setState(() => _icon = option.$2),
                  ),
              ],
            ),
          ),
          FormSection(
            label: '说明',
            child: TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              style: AppText.body(13),
              decoration: const InputDecoration(hintText: '记录温控、通风、电源或门锁等注意事项'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      showAppMessage(context, '请填写房间名称');
      return;
    }
    final resolvedType = _customType
        ? _customTypeController.text.trim()
        : _type;
    if (resolvedType.isEmpty) {
      showAppMessage(context, '请填写自定义空间类型');
      return;
    }
    final existing = widget.existing;
    if (existing == null) {
      widget.state.addRoom(
        name: _nameController.text,
        type: resolvedType,
        notes: _notesController.text,
        icon: _icon,
      );
    } else {
      widget.state.updateRoom(
        id: existing.id,
        name: _nameController.text,
        type: resolvedType,
        notes: _notesController.text,
        icon: _icon,
      );
    }
    showAppMessageAndPop(context, existing == null ? '饲养空间已创建' : '饲养空间已更新');
  }

  Future<void> _delete() async {
    final room = widget.existing;
    if (room == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('删除“${room.name}”？', style: AppText.display(19)),
        content: Text(
          '空间内的动物会移动到其他饲养空间，此操作无法撤销。',
          style: AppText.body(12, color: AppColors.muted, height: 1.6),
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
    if (!widget.state.deleteRoom(room.id)) {
      showAppMessage(context, '至少需要保留一个饲养空间');
      return;
    }
    showAppMessageAndPop(context, '饲养空间已删除');
  }
}

class _RoomTypeChoice extends StatelessWidget {
  const _RoomTypeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandWash : AppColors.paper,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? AppColors.brand2 : AppColors.hair,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppText.body(
              11.5,
              color: selected ? AppColors.brand : AppColors.ink2,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomIconChoice extends StatelessWidget {
  const _RoomIconChoice({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '空间图标',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandWash : AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brand2 : AppColors.hair,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: selected ? AppColors.brand : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class AssignPetRoomSheet extends StatefulWidget {
  const AssignPetRoomSheet({super.key, required this.state, required this.pet});

  final AppState state;
  final PetProfile pet;

  @override
  State<AssignPetRoomSheet> createState() => _AssignPetRoomSheetState();
}

class _AssignPetRoomSheetState extends State<AssignPetRoomSheet> {
  late String _roomId = widget.pet.roomId.isEmpty
      ? widget.state.rooms.firstOrNull?.id ?? ''
      : widget.pet.roomId;

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '调整饲养空间',
      maxHeightFactor: 0.56,
      footer: PrimaryButton(
        label: '保存房间归属',
        onPressed: () {
          widget.state.movePetToRoom(widget.pet.id, _roomId);
          showAppMessageAndPop(context, '饲养空间已更新');
        },
      ),
      child: Column(
        children: [
          FormSection(
            label: '${widget.pet.name} 所属房间',
            child: BottomSelectField<String>(
              title: '选择房间',
              value: _roomId,
              icon: Icons.meeting_room_outlined,
              options: [
                for (final room in widget.state.rooms)
                  BottomSelectOption(
                    value: room.id,
                    label: room.name,
                    subtitle:
                        '${room.type} · '
                        '${widget.state.pets.where((pet) => pet.roomId == room.id).length} 只宠物',
                  ),
              ],
              onChanged: (value) => setState(() => _roomId = value),
            ),
          ),
        ],
      ),
    );
  }
}

class FoodInventoryScreen extends StatelessWidget {
  const FoodInventoryScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final foods = [...state.foodSupplies]
          ..sort((a, b) {
            if (a.needsRestock != b.needsRestock) {
              return a.needsRestock ? -1 : 1;
            }
            return (a.daysRemaining ?? 999).compareTo(b.daysRemaining ?? 999);
          });
        return _ManagementPage(
          title: '食物与用品',
          subtitle: '消耗量 · 可用天数 · 补货提醒',
          action: RoundIconButton(
            key: const ValueKey('food-add-button'),
            icon: Icons.add_rounded,
            onPressed: () => showAppSheet(
              context: context,
              child: AddFoodSheet(state: state),
            ),
          ),
          children: [
            if (state.lowStockFoods.isNotEmpty)
              Callout(
                type: CalloutType.warn,
                message: '${state.lowStockFoods.length} 种资源接近补货阈值，系统会发送本地通知提醒。',
              ),
            if (state.lowStockFoods.isNotEmpty) const SizedBox(height: 12),
            if (foods.isEmpty)
              const EmptyState(
                title: '还没有库存记录',
                message: '添加食物或用品、每日消耗量和剩余量后，系统会自动计算可用天数。',
              )
            else
              for (final food in foods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FoodSupplyCard(
                    supply: food,
                    pet: state.petById(food.petId),
                    onTap: () => showAppSheet(
                      context: context,
                      child: AddFoodSheet(state: state, existing: food),
                    ),
                    onRestock: () => showAppSheet(
                      context: context,
                      child: RestockFoodSheet(state: state, supply: food),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class FoodSupplyCard extends StatelessWidget {
  const FoodSupplyCard({
    super.key,
    required this.supply,
    required this.pet,
    required this.onTap,
    required this.onRestock,
  });

  final FoodSupply supply;
  final PetProfile pet;
  final VoidCallback onTap;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final days = supply.daysRemaining;
    final stockColor = supply.needsRestock ? AppColors.amber : AppColors.brand2;
    final ratio = days == null
        ? 0.0
        : (days / (supply.lowStockDays + 7).clamp(1, 30)).clamp(0.0, 1.0);
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: supply.needsRestock
              ? AppColors.amber.withValues(alpha: 0.32)
              : AppColors.hair,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: pet.species.gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: AnimalArt(species: pet.species, size: 25),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supply.name, style: AppText.display(16)),
                        const SizedBox(height: 3),
                        Text(
                          supply.kind == '食物'
                              ? '${pet.name} · ${supply.mealsPerDay.toStringAsFixed(supply.mealsPerDay % 1 == 0 ? 0 : 1)} 餐/天 · '
                                    '${supply.amountPerMeal.toStringAsFixed(supply.amountPerMeal % 1 == 0 ? 0 : 1)} ${supply.unit}/餐'
                              : '${pet.name} · 每天消耗 '
                                    '${(supply.dailyUsage ?? supply.amountPerMeal).toStringAsFixed(1)} ${supply.unit}',
                          style: AppText.body(
                            10,
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        days == null
                            ? '—'
                            : '${days.toStringAsFixed(days < 1 ? 1 : 0)} 天',
                        style: AppText.number(
                          14,
                          color: stockColor,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        supply.needsRestock ? '需要补货' : '库存正常',
                        style: AppText.body(
                          8.5,
                          color: stockColor,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: ratio,
                  backgroundColor: AppColors.paper3,
                  color: stockColor,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    '剩余 ${_amount(supply.remainingAmount)} ${supply.unit}',
                    style: AppText.body(9.5, color: AppColors.faint),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onRestock,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: Text(
                      '补充库存',
                      style: AppText.body(
                        9.5,
                        color: AppColors.brand,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _amount(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }
}

class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({
    super.key,
    required this.state,
    this.existing,
    this.initialPetId,
    this.lockPet = false,
  });

  final AppState state;
  final FoodSupply? existing;
  final String? initialPetId;
  final bool lockPet;

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  late String _petId =
      widget.existing?.petId ??
      widget.initialPetId ??
      widget.state.pets.firstOrNull?.id ??
      '';
  late String _unit = widget.existing?.unit ?? 'g';
  late String _kind = widget.existing?.kind ?? '食物';
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _remainingController = TextEditingController(
    text: widget.existing?.remainingAmount.toString() ?? '',
  );
  late final _mealsController = TextEditingController(
    text: widget.existing?.mealsPerDay.toString() ?? '2',
  );
  late final _amountController = TextEditingController(
    text: widget.existing?.amountPerMeal.toString() ?? '',
  );
  late final _thresholdController = TextEditingController(
    text: widget.existing?.lowStockDays.toString() ?? '3',
  );
  late final _dailyUsageController = TextEditingController(
    text: widget.existing?.dailyUsage?.toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _remainingController.dispose();
    _mealsController.dispose();
    _amountController.dispose();
    _thresholdController.dispose();
    _dailyUsageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPet = widget.state.petByIdOrNull(_petId);
    return AppSheetFrame(
      title: widget.existing == null ? '添加库存记录' : '编辑库存记录',
      maxHeightFactor: 0.94,
      footer: PrimaryButton(label: '保存食物', onPressed: _save),
      child: Column(
        children: [
          FormSection(
            label: '库存类型',
            child: BottomSelectField<String>(
              title: '选择库存类型',
              value: _kind,
              icon: Icons.inventory_2_outlined,
              options: const [
                BottomSelectOption(value: '食物', label: '食物'),
                BottomSelectOption(value: '用品', label: '用品 / 耗材'),
              ],
              onChanged: (value) => setState(() => _kind = value),
            ),
          ),
          FormSection(
            label: '关联宠物',
            child: widget.lockPet && selectedPet != null
                ? PaperCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: selectedPet.species.gradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: AnimalArt(
                            species: selectedPet.species,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            selectedPet.name,
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
                    title: '选择宠物',
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
            label: _kind == '食物' ? '食物名称' : '用品名称',
            child: TextField(
              key: const ValueKey('food-name-field'),
              controller: _nameController,
              style: AppText.body(13.5),
              decoration: InputDecoration(
                hintText: _kind == '食物' ? '例如：活饵、滋养丸' : '例如：垫材、过滤棉、钙粉',
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: FormSection(
                  label: '剩余量',
                  child: TextField(
                    key: const ValueKey('food-remaining-field'),
                    controller: _remainingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(13.5),
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
                    options: const ['g', 'kg', '只', '粒', 'ml']
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
          if (_kind == '食物')
            Row(
              children: [
                Expanded(
                  child: FormSection(
                    label: '每天几餐',
                    child: TextField(
                      key: const ValueKey('food-meals-field'),
                      controller: _mealsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppText.number(13.5),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FormSection(
                    label: '每餐用量',
                    child: TextField(
                      key: const ValueKey('food-amount-field'),
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppText.number(13.5),
                    ),
                  ),
                ),
              ],
            )
          else
            FormSection(
              label: '每天消耗量',
              child: TextField(
                controller: _dailyUsageController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppText.number(13.5),
                decoration: InputDecoration(hintText: '单位：$_unit'),
              ),
            ),
          FormSection(
            label: '低库存提醒阈值（天）',
            child: TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              style: AppText.number(13.5),
            ),
          ),
          Callout(
            message: _kind == '食物'
                ? '可用天数 = 剩余量 ÷（每天餐数 × 每餐用量）。达到阈值后会安排本地通知。'
                : '可用天数 = 剩余量 ÷ 每天消耗量。达到阈值后会安排本地通知。',
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final remaining = double.tryParse(_remainingController.text);
    final meals = double.tryParse(_mealsController.text);
    final amount = double.tryParse(_amountController.text);
    final dailyUsage = double.tryParse(_dailyUsageController.text);
    final threshold = int.tryParse(_thresholdController.text) ?? 3;
    if (name.isEmpty) {
      showAppMessage(context, '请填写${_kind == '食物' ? '食物' : '用品'}名称');
      return;
    }
    if (_petId.isEmpty) {
      showAppMessage(context, '请先添加并选择宠物');
      return;
    }
    if (remaining == null || remaining < 0) {
      showAppMessage(context, '请填写有效的剩余量');
      return;
    }
    if (_kind == '食物' && (meals == null || meals <= 0)) {
      showAppMessage(context, '请检查每天餐数');
      return;
    }
    if (_kind == '食物' && (amount == null || amount <= 0)) {
      showAppMessage(context, '请检查每餐用量');
      return;
    }
    if (_kind == '用品' && (dailyUsage == null || dailyUsage <= 0)) {
      showAppMessage(context, '请检查每天消耗量');
      return;
    }
    if (threshold < 0) {
      showAppMessage(context, '低库存提醒天数不能小于 0');
      return;
    }
    widget.state.upsertFoodSupply(
      id: widget.existing?.id,
      petId: _petId,
      name: name,
      unit: _unit,
      remainingAmount: remaining,
      mealsPerDay: meals ?? 1,
      amountPerMeal: _kind == '食物' ? amount! : dailyUsage!,
      kind: _kind,
      dailyUsage: _kind == '用品' ? dailyUsage : null,
      lowStockDays: threshold,
    );
    showAppMessageAndPop(context, '库存记录已保存');
  }
}

class RestockFoodSheet extends StatefulWidget {
  const RestockFoodSheet({
    super.key,
    required this.state,
    required this.supply,
  });

  final AppState state;
  final FoodSupply supply;

  @override
  State<RestockFoodSheet> createState() => _RestockFoodSheetState();
}

class _RestockFoodSheetState extends State<RestockFoodSheet> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: '补充 ${widget.supply.name}',
      maxHeightFactor: 0.48,
      footer: PrimaryButton(
        label: '确认补充',
        onPressed: () {
          final amount = double.tryParse(_amountController.text);
          if (amount == null || amount <= 0) {
            showAppMessage(context, '请输入有效补充数量');
            return;
          }
          widget.state.restockFood(widget.supply.id, amount);
          showAppMessageAndPop(context, '库存已补充');
        },
      ),
      child: FormSection(
        label: '补充数量（${widget.supply.unit}）',
        child: TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppText.number(15),
          decoration: const InputDecoration(hintText: '输入购买或入库数量'),
        ),
      ),
    );
  }
}

class _ManagementPage extends StatelessWidget {
  const _ManagementPage({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final List<Widget> children;

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
                  child: StackHeader(
                    title: title,
                    subtitle: subtitle,
                    action: action,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...children, const SizedBox(height: 30)],
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
