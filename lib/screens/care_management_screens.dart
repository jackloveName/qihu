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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: templates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            mainAxisExtent: 126,
          ),
          itemBuilder: (context, index) {
            final template = templates[index];
            return Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
                side: const BorderSide(color: AppColors.hair),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => showAppMessage(
                  context,
                  template.builtIn ? '内置模板，可直接用于建档' : '自定义模板',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: template.gradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: AnimalArt(species: template, size: 27),
                          ),
                          const Spacer(),
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
                      const Spacer(),
                      Text(
                        template.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(15.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${template.category} · ${template.code}',
                        style: AppText.body(9, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openAddTemplate(BuildContext context) async {
    await showAppSheet(
      context: context,
      child: AddSpeciesTemplateSheet(state: widget.state),
    );
    if (mounted) setState(() {});
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
  const AddSpeciesTemplateSheet({super.key, required this.state});

  final AppState state;

  @override
  State<AddSpeciesTemplateSheet> createState() =>
      _AddSpeciesTemplateSheetState();
}

class _AddSpeciesTemplateSheetState extends State<AddSpeciesTemplateSheet> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: '异宠');
  final _noteController = TextEditingController();
  String _artStyle = 'paw';
  int _paletteIndex = 0;

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
  ];

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
      title: '新增宠物模板',
      maxHeightFactor: 0.9,
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
            child: BottomSelectField<String>(
              title: '选择图形类型',
              value: _artStyle,
              icon: Icons.pets_outlined,
              options: const [
                BottomSelectOption(value: 'paw', label: '通用爪印'),
                BottomSelectOption(value: 'cat', label: '猫'),
                BottomSelectOption(value: 'dog', label: '狗'),
                BottomSelectOption(value: 'rodent', label: '小型哺乳'),
                BottomSelectOption(value: 'marsupial', label: '有袋类'),
                BottomSelectOption(value: 'reptile', label: '爬宠'),
                BottomSelectOption(value: 'snake', label: '蛇类'),
                BottomSelectOption(value: 'bird', label: '鸟类'),
                BottomSelectOption(value: 'fish', label: '鱼类'),
                BottomSelectOption(value: 'amphibian', label: '两栖'),
              ],
              onChanged: (value) => setState(() => _artStyle = value),
            ),
          ),
          FormSection(
            label: '配色',
            child: Row(
              children: [
                for (var index = 0; index < _palettes.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paletteIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _palettes[index].background,
                              _palettes[index].backgroundEnd,
                            ],
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
                          _palettes[index].name,
                          style: AppText.body(
                            9,
                            color: _palettes[index].ink,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
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

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppMessage(context, '请填写模板名称');
      return;
    }
    final palette = _palettes[_paletteIndex];
    widget.state.addSpeciesTemplate(
      label: name,
      category: _categoryController.text,
      artStyle: _artStyle,
      background: palette.background,
      backgroundEnd: palette.backgroundEnd,
      ink: palette.ink,
      note: _noteController.text,
    );
    showAppMessageAndPop(context, '模板已保存');
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
                      child: const Icon(
                        Icons.meeting_room_outlined,
                        color: AppColors.brand,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room.name, style: AppText.display(17)),
                          const SizedBox(height: 3),
                          Text(
                            room.type,
                            style: AppText.body(10.5, color: AppColors.muted),
                          ),
                          if (room.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
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
                    const Icon(
                      Icons.edit_outlined,
                      size: 17,
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

class DailyNeedsScreen extends StatelessWidget {
  const DailyNeedsScreen({super.key, required this.state, this.petId});

  final AppState state;
  final String? petId;

  @override
  Widget build(BuildContext context) {
    return _ManagementPage(
      title: petId == null ? '每日照护需求' : '${state.petById(petId!).name}的每日需求',
      subtitle: '创建一次 · 每天自动生成',
      action: RoundIconButton(
        icon: Icons.add_rounded,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AddTaskScreen(
              state: state,
              initialPetId: petId,
              initialRecurring: true,
            ),
          ),
        ),
      ),
      children: [
        for (final pet in state.pets.where(
          (pet) => petId == null || pet.id == petId,
        )) ...[
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
                title: '还没有每日需求',
                message: '可以为这只宠物设置喂食、清洁、环境检查等每日固定需求。',
              ),
            )
          else
            for (final definition in state.taskDefinitions.where(
              (item) => item.petId == pet.id,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PaperCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: definition.enabled
                              ? AppColors.brandWash
                              : AppColors.paper2,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.repeat_rounded,
                          size: 18,
                          color: definition.enabled
                              ? AppColors.brand
                              : AppColors.faint,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              definition.title,
                              style: AppText.body(13, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${definition.defaultTime} · ${definition.type} · 每天',
                              style: AppText.body(9.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: definition.enabled,
                        onChanged: (value) => state.setTaskDefinitionEnabled(
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
        ],
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
  late String _type = widget.existing?.type ?? '室内';

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetFrame(
      title: widget.existing == null ? '新增饲养空间' : '编辑饲养空间',
      maxHeightFactor: 0.72,
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
            child: BottomSelectField<String>(
              title: '选择空间类型',
              value: _type,
              icon: Icons.home_work_outlined,
              options: const ['室内', '温控房间', '水族空间', '阳台', '室外围栏']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value),
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
    final existing = widget.existing;
    if (existing == null) {
      widget.state.addRoom(
        name: _nameController.text,
        type: _type,
        notes: _notesController.text,
      );
    } else {
      widget.state.updateRoom(
        id: existing.id,
        name: _nameController.text,
        type: _type,
        notes: _notesController.text,
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
  });

  final AppState state;
  final FoodSupply? existing;
  final String? initialPetId;

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
            child: BottomSelectField<String>(
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
