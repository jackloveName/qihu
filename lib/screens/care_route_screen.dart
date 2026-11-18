import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models.dart';
import '../widgets/animal_art.dart';
import '../widgets/app_widgets.dart';

class CareRouteScreen extends StatefulWidget {
  const CareRouteScreen({super.key, required this.state});

  final AppState state;

  @override
  State<CareRouteScreen> createState() => _CareRouteScreenState();
}

class _CareRouteScreenState extends State<CareRouteScreen> {
  late final List<CareTask> _route = _buildRoute();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _waterTemperatureController = TextEditingController();
  final _phController = TextEditingController();
  final _weightController = TextEditingController();
  final _foodAmountController = TextEditingController();
  final _noteController = TextEditingController();
  int _index = 0;
  int _completed = 0;
  int _skipped = 0;
  String? _foodId;
  String _healthStatus = '状态稳定';
  String _cleanScope = '日常清洁';
  String _cleanResult = '已完成';
  String _deviceKind = '温控设备';
  String _deviceStatus = '运行正常';

  @override
  void initState() {
    super.initState();
    _prepareTask();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _waterTemperatureController.dispose();
    _phController.dispose();
    _weightController.dispose();
    _foodAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<CareTask> _buildRoute() {
    final roomOrder = {
      for (var index = 0; index < widget.state.rooms.length; index++)
        widget.state.rooms[index].id: index,
    };
    final tasks = [...widget.state.pendingTasks];
    tasks.sort((a, b) {
      final aRoom = roomOrder[widget.state.petById(a.petId).roomId] ?? 999;
      final bRoom = roomOrder[widget.state.petById(b.petId).roomId] ?? 999;
      if (aRoom != bRoom) return aRoom.compareTo(bRoom);
      return a.time.compareTo(b.time);
    });
    return tasks;
  }

  CareTask? get _task => _index < _route.length ? _route[_index] : null;

  PetProfile? get _pet =>
      _task == null ? null : widget.state.petById(_task!.petId);

  List<FoodSupply> get _foodOptions {
    final pet = _pet;
    if (pet == null) return const [];
    return widget.state.foodSupplies
        .where((food) => food.petId == pet.id && food.kind == '食物')
        .toList();
  }

  void _prepareTask() {
    _temperatureController.clear();
    _humidityController.clear();
    _waterTemperatureController.clear();
    _phController.clear();
    _weightController.clear();
    _foodAmountController.clear();
    _noteController.clear();
    _healthStatus = '状态稳定';
    _cleanScope = '日常清洁';
    _cleanResult = '已完成';
    _deviceKind = '温控设备';
    _deviceStatus = '运行正常';
    final foods = _foodOptions;
    _foodId = foods.firstOrNull?.id;
    if (_foodId != null) {
      final food = foods.firstWhere((item) => item.id == _foodId);
      _foodAmountController.text = _formatNumber(food.amountPerMeal);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return _buildSummary(context);
    final task = _task!;
    final pet = _pet!;
    final room = widget.state.roomById(pet.roomId);
    final progress = (_index / _route.length).clamp(0.0, 1.0);

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
                    title: '今日照护路线',
                    subtitle: '',
                    action: Text(
                      '${_index + 1} / ${_route.length}',
                      style: AppText.number(
                        11,
                        color: AppColors.muted,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.paper3,
                      color: AppColors.brass2,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: pet.species.gradient,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              alignment: Alignment.center,
                              child: AnimalArt(species: pet.species, size: 22),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              '${room.name} · ${pet.name}',
                              style: AppText.body(
                                11,
                                color: AppColors.muted,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(task.title, style: AppText.display(30)),
                        const SizedBox(height: 7),
                        Text(
                          '${task.time} · ${task.type}',
                          style: AppText.number(11, color: AppColors.brass),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task.subtitle,
                          style: AppText.body(
                            11.5,
                            color: AppColors.muted,
                            height: 1.7,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(height: 1, color: AppColors.hair),
                        ),
                        ..._buildInputs(task),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: '完成并继续',
              icon: Icons.check_rounded,
              onPressed: () => _complete(task, pet),
            ),
            TextButton(
              onPressed: _skip,
              child: Text(
                '跳过',
                style: AppText.body(10.5, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputs(CareTask task) {
    final fields = <Widget>[];
    switch (task.type) {
      case '环境':
        fields.add(
          Row(
            children: [
              Expanded(
                child: FormSection(
                  label: '温度（°C）',
                  child: TextField(
                    controller: _temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(14),
                    decoration: const InputDecoration(hintText: '29.0'),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FormSection(
                  label: '湿度（%）',
                  child: TextField(
                    controller: _humidityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(14),
                    decoration: const InputDecoration(hintText: '58'),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case '水族':
        fields.add(
          Row(
            children: [
              Expanded(
                child: FormSection(
                  label: '水温（°C）',
                  child: TextField(
                    controller: _waterTemperatureController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(14),
                    decoration: const InputDecoration(hintText: '26.0'),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FormSection(
                  label: 'pH',
                  child: TextField(
                    controller: _phController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppText.number(14),
                    decoration: const InputDecoration(hintText: '7.2'),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case '喂食':
        final foods = _foodOptions;
        if (foods.isEmpty) {
          fields.add(
            const Callout(message: '当前动物还没有食物库存，可先到“食物计划”添加食物后再记录本次用量。'),
          );
        } else {
          fields.add(
            FormSection(
              label: '食用库存',
              child: BottomSelectField<String>(
                title: '选择食物库存',
                value: _foodId ?? foods.first.id,
                icon: Icons.restaurant_outlined,
                options: [
                  for (final food in foods)
                    BottomSelectOption(
                      value: food.id,
                      label: food.name,
                      subtitle:
                          '剩余 ${_formatNumber(food.remainingAmount)} ${food.unit}',
                    ),
                ],
                onChanged: (value) {
                  setState(() => _foodId = value);
                  final food = foods.firstWhere((item) => item.id == value);
                  _foodAmountController.text = _formatNumber(
                    food.amountPerMeal,
                  );
                },
              ),
            ),
          );
          fields.add(const SizedBox(height: 10));
          fields.add(
            FormSection(
              label: '本次用量',
              child: TextField(
                controller: _foodAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppText.number(14),
              ),
            ),
          );
        }
        break;
      case '健康':
        fields.add(
          FormSection(
            label: '健康状态',
            child: BottomSelectField<String>(
              title: '选择健康状态',
              value: _healthStatus,
              icon: Icons.health_and_safety_outlined,
              options: const ['状态稳定', '需要观察', '异常变化']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _healthStatus = value),
            ),
          ),
        );
        fields.add(const SizedBox(height: 10));
        fields.add(_weightField());
        break;
      case '称重':
        fields.add(_weightField());
        break;
      case '清洁':
        fields.add(
          FormSection(
            label: '清洁范围',
            child: BottomSelectField<String>(
              title: '选择清洁范围',
              value: _cleanScope,
              icon: Icons.cleaning_services_outlined,
              options: const ['日常清洁', '食盆与饮水器', '生活区域', '笼舍 / 缸体', '全面清洁']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _cleanScope = value),
            ),
          ),
        );
        fields.add(const SizedBox(height: 10));
        fields.add(
          FormSection(
            label: '清洁结果',
            child: BottomSelectField<String>(
              title: '选择清洁结果',
              value: _cleanResult,
              icon: Icons.task_alt_rounded,
              options: const ['已完成', '需要复看']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _cleanResult = value),
            ),
          ),
        );
        break;
      case '设备':
        fields.add(
          FormSection(
            label: '设备类型',
            child: BottomSelectField<String>(
              title: '选择设备类型',
              value: _deviceKind,
              icon: Icons.devices_other_outlined,
              options: const ['温控设备', '过滤 / 水泵', '照明设备', '通风设备']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _deviceKind = value),
            ),
          ),
        );
        fields.add(const SizedBox(height: 10));
        fields.add(
          FormSection(
            label: '运行状态',
            child: BottomSelectField<String>(
              title: '选择运行状态',
              value: _deviceStatus,
              icon: Icons.monitor_heart_outlined,
              options: const ['运行正常', '需要维护', '异常']
                  .map(
                    (value) => BottomSelectOption(value: value, label: value),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _deviceStatus = value),
            ),
          ),
        );
        break;
      default:
        break;
    }
    if (fields.isNotEmpty) fields.add(const SizedBox(height: 10));
    fields.add(
      FormSection(
        label: '补充说明（可选）',
        child: TextField(
          controller: _noteController,
          minLines: 2,
          maxLines: 4,
          style: AppText.body(13),
          decoration: const InputDecoration(hintText: '可选'),
        ),
      ),
    );
    return fields;
  }

  Widget _weightField() {
    return FormSection(
      label: '体重（g）',
      child: TextField(
        controller: _weightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppText.number(14),
        decoration: const InputDecoration(hintText: '例如：62'),
      ),
    );
  }

  void _skip() {
    final task = _task;
    if (task == null) return;
    widget.state.skipTask(task.id, note: _noteController.text);
    _skipped++;
    _advance();
  }

  void _complete(CareTask task, PetProfile pet) {
    final noteParts = <String>[];
    switch (task.type) {
      case '环境':
        final temperature = double.tryParse(_temperatureController.text);
        final humidity = double.tryParse(_humidityController.text);
        if (temperature != null) {
          widget.state.updatePetMetrics(
            pet.id,
            temperature: '${_formatNumber(temperature)}°C',
            humidity: humidity == null ? null : '${_formatNumber(humidity)}%',
          );
          noteParts.add('温度 ${_formatNumber(temperature)}°C');
          if (humidity != null) {
            noteParts.add('湿度 ${_formatNumber(humidity)}%');
          }
        }
        break;
      case '水族':
        final waterTemperature = double.tryParse(
          _waterTemperatureController.text,
        );
        final ph = double.tryParse(_phController.text);
        if (waterTemperature != null) {
          widget.state.updatePetMetrics(
            pet.id,
            temperature: '${_formatNumber(waterTemperature)}°C',
          );
          noteParts.add('水温 ${_formatNumber(waterTemperature)}°C');
        }
        if (ph != null) noteParts.add('pH ${_formatNumber(ph)}');
        break;
      case '健康':
        noteParts.add('健康状态 $_healthStatus');
        _addWeight(noteParts, pet);
        break;
      case '称重':
        _addWeight(noteParts, pet);
        break;
      case '喂食':
        final amount = double.tryParse(_foodAmountController.text);
        if (_foodId != null && amount != null && amount > 0) {
          widget.state.consumeFoodSupply(_foodId!, amount);
          final food = widget.state.foodSupplies.firstWhere(
            (item) => item.id == _foodId,
          );
          noteParts.add('${food.name} ${_formatNumber(amount)} ${food.unit}');
        }
        break;
      case '清洁':
        noteParts.add('清洁范围 $_cleanScope');
        noteParts.add('清洁结果 $_cleanResult');
        break;
      case '设备':
        noteParts.add('设备 $_deviceKind');
        noteParts.add('运行状态 $_deviceStatus');
        break;
    }
    if (_noteController.text.trim().isNotEmpty) {
      noteParts.add(_noteController.text.trim());
    }
    widget.state.completeTask(task.id, note: noteParts.join('，'));
    _completed++;
    _advance();
  }

  void _addWeight(List<String> noteParts, PetProfile pet) {
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;
    widget.state.updatePetMetrics(pet.id, weight: '${_formatNumber(weight)} g');
    noteParts.add('体重 ${_formatNumber(weight)} g');
  }

  void _advance() {
    setState(() {
      _index++;
      if (_index < _route.length) _prepareTask();
    });
  }

  Widget _buildSummary(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          child: PagePadding(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brandWash,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brandLine),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.brand,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text('今日照护完成', style: AppText.display(27)),
                  const SizedBox(height: 8),
                  Text(
                    '完成 $_completed 项 · 跳过 $_skipped 项',
                    style: AppText.body(12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: PrimaryButton(
                      label: '返回首页',
                      onPressed: () => Navigator.pop(context),
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

  String _formatNumber(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }
}
