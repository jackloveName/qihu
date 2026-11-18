import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/china_cities.dart';

class PetSpecies {
  const PetSpecies({
    required this.id,
    required this.label,
    required this.category,
    required this.background,
    required this.backgroundEnd,
    required this.ink,
    required this.artStyle,
    required this.code,
    this.builtIn = true,
    this.note = '',
  });

  final String id;
  final String label;
  final String category;
  final Color background;
  final Color backgroundEnd;
  final Color ink;
  final String artStyle;
  final String code;
  final bool builtIn;
  final String note;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, backgroundEnd],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'background': background.toARGB32(),
    'backgroundEnd': backgroundEnd.toARGB32(),
    'ink': ink.toARGB32(),
    'artStyle': artStyle,
    'code': code,
    'builtIn': builtIn,
    'note': note,
  };

  factory PetSpecies.fromJson(Map<String, dynamic> json) {
    return PetSpecies(
      id: json['id'] as String,
      label: json['label'] as String? ?? '自定义物种',
      category: json['category'] as String? ?? '异宠',
      background: Color(json['background'] as int? ?? 0xFFEAE6E1),
      backgroundEnd: Color(json['backgroundEnd'] as int? ?? 0xFFD9D2CB),
      ink: Color(json['ink'] as int? ?? 0xFF5E564C),
      artStyle: json['artStyle'] as String? ?? 'paw',
      code: json['code'] as String? ?? 'CUSTOM',
      builtIn: json['builtIn'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }

  static PetSpecies fromName(String value, {Iterable<PetSpecies>? templates}) {
    final source = templates ?? builtIns;
    return source.firstWhere(
      (species) => species.id == value || species.label == value,
      orElse: () => gecko,
    );
  }

  @override
  bool operator ==(Object other) => other is PetSpecies && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static const gecko = PetSpecies(
    id: 'gecko',
    label: '豹纹守宫',
    category: '爬宠',
    background: Color(0xFFD6E2D9),
    backgroundEnd: Color(0xFFC8D9CF),
    ink: Color(0xFF2C5546),
    artStyle: 'gecko',
    code: 'GECKO',
  );
  static const beardedDragon = PetSpecies(
    id: 'bearded-dragon',
    label: '鬃狮蜥',
    category: '爬宠',
    background: Color(0xFFF1E7D2),
    backgroundEnd: Color(0xFFE4D4B2),
    ink: Color(0xFF7A5B2A),
    artStyle: 'beardedDragon',
    code: 'DRAGON',
  );
  static const cockatiel = PetSpecies(
    id: 'cockatiel',
    label: '玄凤鹦鹉',
    category: '鸟类',
    background: Color(0xFFF7EBD6),
    backgroundEnd: Color(0xFFEFDCB4),
    ink: Color(0xFF8A6425),
    artStyle: 'cockatiel',
    code: 'AVES',
  );
  static const betta = PetSpecies(
    id: 'betta',
    label: '斗鱼',
    category: '水族',
    background: Color(0xFFE2EAF3),
    backgroundEnd: Color(0xFFCCDCEA),
    ink: Color(0xFF3A5B7D),
    artStyle: 'betta',
    code: 'BETTA',
  );
  static const rabbit = PetSpecies(
    id: 'rabbit',
    label: '兔',
    category: '哺乳',
    background: Color(0xFFF2E9E6),
    backgroundEnd: Color(0xFFE6D6D1),
    ink: Color(0xFF7C5750),
    artStyle: 'rabbit',
    code: 'RABBIT',
  );
  static const tarantula = PetSpecies(
    id: 'tarantula',
    label: '捕鸟蛛',
    category: '异宠',
    background: Color(0xFFEAE6E1),
    backgroundEnd: Color(0xFFD9D2CB),
    ink: Color(0xFF5E564C),
    artStyle: 'tarantula',
    code: 'ARACHNID',
  );

  static const cat = PetSpecies(
    id: 'cat',
    label: '猫',
    category: '哺乳',
    background: Color(0xFFF2E8DE),
    backgroundEnd: Color(0xFFE4D4C3),
    ink: Color(0xFF72523C),
    artStyle: 'cat',
    code: 'FELINE',
  );
  static const dog = PetSpecies(
    id: 'dog',
    label: '狗',
    category: '哺乳',
    background: Color(0xFFE9E1D3),
    backgroundEnd: Color(0xFFD7C8B3),
    ink: Color(0xFF634E37),
    artStyle: 'dog',
    code: 'CANINE',
  );
  static const hamster = PetSpecies(
    id: 'hamster',
    label: '仓鼠',
    category: '哺乳',
    background: Color(0xFFF4E7D8),
    backgroundEnd: Color(0xFFE7CFB4),
    ink: Color(0xFF87613C),
    artStyle: 'rodent',
    code: 'RODENT',
  );
  static const guineaPig = PetSpecies(
    id: 'guinea-pig',
    label: '豚鼠',
    category: '哺乳',
    background: Color(0xFFEFE5D7),
    backgroundEnd: Color(0xFFDDCBBA),
    ink: Color(0xFF765A43),
    artStyle: 'rodent',
    code: 'CAVY',
  );
  static const ferret = PetSpecies(
    id: 'ferret',
    label: '雪貂',
    category: '哺乳',
    background: Color(0xFFEFE7DD),
    backgroundEnd: Color(0xFFDDD0C1),
    ink: Color(0xFF67594D),
    artStyle: 'mustelid',
    code: 'FERRET',
  );
  static const chinchilla = PetSpecies(
    id: 'chinchilla',
    label: '龙猫',
    category: '哺乳',
    background: Color(0xFFE8E9E6),
    backgroundEnd: Color(0xFFD5D8D4),
    ink: Color(0xFF60645F),
    artStyle: 'rodent',
    code: 'CHINCHILLA',
  );
  static const hedgehog = PetSpecies(
    id: 'hedgehog',
    label: '刺猬',
    category: '异宠',
    background: Color(0xFFE8E2D9),
    backgroundEnd: Color(0xFFD6CCBF),
    ink: Color(0xFF655B50),
    artStyle: 'hedgehog',
    code: 'HEDGEHOG',
  );
  static const sugarGlider = PetSpecies(
    id: 'sugar-glider',
    label: '蜜袋鼯',
    category: '异宠',
    background: Color(0xFFE8E5DF),
    backgroundEnd: Color(0xFFD4CEC6),
    ink: Color(0xFF625A52),
    artStyle: 'glider',
    code: 'GLIDER',
  );
  static const kangaroo = PetSpecies(
    id: 'kangaroo',
    label: '袋鼠',
    category: '异宠',
    background: Color(0xFFEDE2D1),
    backgroundEnd: Color(0xFFDDC7AD),
    ink: Color(0xFF7A5B3C),
    artStyle: 'marsupial',
    code: 'MACROPOD',
  );
  static const ballPython = PetSpecies(
    id: 'ball-python',
    label: '球蟒',
    category: '爬宠',
    background: Color(0xFFE8E2D7),
    backgroundEnd: Color(0xFFD5C9B8),
    ink: Color(0xFF65543F),
    artStyle: 'snake',
    code: 'PYTHON',
  );
  static const cornSnake = PetSpecies(
    id: 'corn-snake',
    label: '玉米蛇',
    category: '爬宠',
    background: Color(0xFFF0E2D7),
    backgroundEnd: Color(0xFFE1C7B6),
    ink: Color(0xFF805A42),
    artStyle: 'snake',
    code: 'COLUBRID',
  );
  static const kingSnake = PetSpecies(
    id: 'king-snake',
    label: '王蛇',
    category: '爬宠',
    background: Color(0xFFE7E2DC),
    backgroundEnd: Color(0xFFD4CBC1),
    ink: Color(0xFF5B5149),
    artStyle: 'snake',
    code: 'LAMPROPELTIS',
  );
  static const crestedGecko = PetSpecies(
    id: 'crested-gecko',
    label: '睫角守宫',
    category: '爬宠',
    background: Color(0xFFE3E7D9),
    backgroundEnd: Color(0xFFCED6BD),
    ink: Color(0xFF56603F),
    artStyle: 'gecko',
    code: 'CRESTED',
  );
  static const chameleon = PetSpecies(
    id: 'chameleon',
    label: '变色龙',
    category: '爬宠',
    background: Color(0xFFDCE8DA),
    backgroundEnd: Color(0xFFC0D5BD),
    ink: Color(0xFF3F6244),
    artStyle: 'reptile',
    code: 'CHAMAELEO',
  );
  static const blueTongueSkink = PetSpecies(
    id: 'blue-tongue-skink',
    label: '蓝舌石龙子',
    category: '爬宠',
    background: Color(0xFFE8E1D3),
    backgroundEnd: Color(0xFFD4C4AE),
    ink: Color(0xFF66503A),
    artStyle: 'reptile',
    code: 'TILIQUA',
  );
  static const hermannTortoise = PetSpecies(
    id: 'hermann-tortoise',
    label: '赫曼陆龟',
    category: '爬宠',
    background: Color(0xFFE7E2CF),
    backgroundEnd: Color(0xFFD2C9AC),
    ink: Color(0xFF655C3D),
    artStyle: 'tortoise',
    code: 'TESTUDO',
  );
  static const redEaredSlider = PetSpecies(
    id: 'red-eared-slider',
    label: '巴西龟',
    category: '爬宠',
    background: Color(0xFFDDE8E0),
    backgroundEnd: Color(0xFFC2D7CC),
    ink: Color(0xFF426659),
    artStyle: 'tortoise',
    code: 'SLIDER',
  );
  static const budgie = PetSpecies(
    id: 'budgie',
    label: '虎皮鹦鹉',
    category: '鸟类',
    background: Color(0xFFE6ECD8),
    backgroundEnd: Color(0xFFD0DBB5),
    ink: Color(0xFF586B36),
    artStyle: 'bird',
    code: 'BUDGIE',
  );
  static const lovebird = PetSpecies(
    id: 'lovebird',
    label: '牡丹鹦鹉',
    category: '鸟类',
    background: Color(0xFFF0E3D5),
    backgroundEnd: Color(0xFFE0CCAF),
    ink: Color(0xFF7B5C33),
    artStyle: 'bird',
    code: 'AGAPORNIS',
  );
  static const sunConure = PetSpecies(
    id: 'sun-conure',
    label: '太阳锥尾鹦鹉',
    category: '鸟类',
    background: Color(0xFFF3E1C4),
    backgroundEnd: Color(0xFFE7C58E),
    ink: Color(0xFF8C5B1F),
    artStyle: 'bird',
    code: 'CONURE',
  );
  static const africanGrey = PetSpecies(
    id: 'african-grey',
    label: '非洲灰鹦鹉',
    category: '鸟类',
    background: Color(0xFFE4E6E4),
    backgroundEnd: Color(0xFFD0D4D1),
    ink: Color(0xFF545D58),
    artStyle: 'bird',
    code: 'GREY',
  );
  static const pigeon = PetSpecies(
    id: 'pigeon',
    label: '鸽子',
    category: '鸟类',
    background: Color(0xFFE5E7E8),
    backgroundEnd: Color(0xFFD1D5D8),
    ink: Color(0xFF56616A),
    artStyle: 'bird',
    code: 'COLUMBA',
  );
  static const duck = PetSpecies(
    id: 'duck',
    label: '鸭',
    category: '鸟类',
    background: Color(0xFFE9E8D9),
    backgroundEnd: Color(0xFFD6D6BB),
    ink: Color(0xFF626448),
    artStyle: 'waterfowl',
    code: 'ANAS',
  );
  static const goldfish = PetSpecies(
    id: 'goldfish',
    label: '金鱼',
    category: '水族',
    background: Color(0xFFF1E2D2),
    backgroundEnd: Color(0xFFE3C8AC),
    ink: Color(0xFF835A32),
    artStyle: 'fish',
    code: 'CARASSIUS',
  );
  static const guppy = PetSpecies(
    id: 'guppy',
    label: '孔雀鱼',
    category: '水族',
    background: Color(0xFFDFEAF1),
    backgroundEnd: Color(0xFFC5DCEA),
    ink: Color(0xFF446B86),
    artStyle: 'fish',
    code: 'GUPPY',
  );
  static const neonTetra = PetSpecies(
    id: 'neon-tetra',
    label: '霓虹灯鱼',
    category: '水族',
    background: Color(0xFFDDEBF0),
    backgroundEnd: Color(0xFFC1DEE8),
    ink: Color(0xFF397085),
    artStyle: 'fish',
    code: 'TETRA',
  );
  static const angelfish = PetSpecies(
    id: 'angelfish',
    label: '神仙鱼',
    category: '水族',
    background: Color(0xFFE1E7EC),
    backgroundEnd: Color(0xFFC9D5DE),
    ink: Color(0xFF4B6174),
    artStyle: 'fish',
    code: 'PTEROPHYLLUM',
  );
  static const koi = PetSpecies(
    id: 'koi',
    label: '锦鲤',
    category: '水族',
    background: Color(0xFFF0E1D5),
    backgroundEnd: Color(0xFFE1C5B3),
    ink: Color(0xFF86563F),
    artStyle: 'fish',
    code: 'KOI',
  );
  static const zebrafish = PetSpecies(
    id: 'zebrafish',
    label: '斑马鱼',
    category: '水族',
    background: Color(0xFFE2E9EC),
    backgroundEnd: Color(0xFFCBD9DF),
    ink: Color(0xFF4C6873),
    artStyle: 'fish',
    code: 'DANIO',
  );
  static const molly = PetSpecies(
    id: 'molly',
    label: '玛丽鱼',
    category: '水族',
    background: Color(0xFFE5E9E5),
    backgroundEnd: Color(0xFFCFD8CF),
    ink: Color(0xFF526456),
    artStyle: 'fish',
    code: 'POECILIA',
  );
  static const axolotl = PetSpecies(
    id: 'axolotl',
    label: '六角恐龙',
    category: '两栖',
    background: Color(0xFFF0DEDD),
    backgroundEnd: Color(0xFFE1C2C2),
    ink: Color(0xFF8B5658),
    artStyle: 'amphibian',
    code: 'AXOLOTL',
  );
  static const pacmanFrog = PetSpecies(
    id: 'pacman-frog',
    label: '角蛙',
    category: '两栖',
    background: Color(0xFFE5E6D4),
    backgroundEnd: Color(0xFFD0D2B5),
    ink: Color(0xFF5F6440),
    artStyle: 'amphibian',
    code: 'CERATOPHRYS',
  );
  static const whiteTreeFrog = PetSpecies(
    id: 'white-tree-frog',
    label: '老爷树蛙',
    category: '两栖',
    background: Color(0xFFDCE8DF),
    backgroundEnd: Color(0xFFC2D7C8),
    ink: Color(0xFF436653),
    artStyle: 'amphibian',
    code: 'LITORIA',
  );
  static const fireBellyNewt = PetSpecies(
    id: 'fire-belly-newt',
    label: '东方蝾螈',
    category: '两栖',
    background: Color(0xFFE2E4D7),
    backgroundEnd: Color(0xFFCCD1B8),
    ink: Color(0xFF5E6644),
    artStyle: 'amphibian',
    code: 'CYNOPS',
  );
  static const hermitCrab = PetSpecies(
    id: 'hermit-crab',
    label: '寄居蟹',
    category: '异宠',
    background: Color(0xFFEFE2D1),
    backgroundEnd: Color(0xFFDDC5AB),
    ink: Color(0xFF7A5A3D),
    artStyle: 'crustacean',
    code: 'COENOBITA',
  );
  static const landSnail = PetSpecies(
    id: 'land-snail',
    label: '陆生蜗牛',
    category: '异宠',
    background: Color(0xFFE8E0D3),
    backgroundEnd: Color(0xFFD4C7B2),
    ink: Color(0xFF675843),
    artStyle: 'snail',
    code: 'GASTROPODA',
  );
  static const orchidMantis = PetSpecies(
    id: 'orchid-mantis',
    label: '兰花螳螂',
    category: '异宠',
    background: Color(0xFFF0DFE3),
    backgroundEnd: Color(0xFFE1C6CE),
    ink: Color(0xFF875D68),
    artStyle: 'insect',
    code: 'MANTIS',
  );
  static const millipede = PetSpecies(
    id: 'millipede',
    label: '千足虫',
    category: '异宠',
    background: Color(0xFFE6E1D8),
    backgroundEnd: Color(0xFFD1C9BC),
    ink: Color(0xFF625A4F),
    artStyle: 'insect',
    code: 'DIPLOPODA',
  );

  static const builtIns = <PetSpecies>[
    gecko,
    beardedDragon,
    cockatiel,
    betta,
    rabbit,
    tarantula,
    cat,
    dog,
    hamster,
    guineaPig,
    ferret,
    chinchilla,
    hedgehog,
    sugarGlider,
    kangaroo,
    crestedGecko,
    chameleon,
    blueTongueSkink,
    ballPython,
    cornSnake,
    kingSnake,
    hermannTortoise,
    redEaredSlider,
    budgie,
    lovebird,
    sunConure,
    africanGrey,
    pigeon,
    duck,
    goldfish,
    guppy,
    neonTetra,
    angelfish,
    koi,
    zebrafish,
    molly,
    axolotl,
    pacmanFrog,
    whiteTreeFrog,
    fireBellyNewt,
    hermitCrab,
    landSnail,
    orchidMantis,
    millipede,
  ];
}

enum TaskStatus { pending, done, skipped }

enum TaskPriority { must, suggested }

enum TaskRunAction { completed, skipped, reopened }

class StarterCareTask {
  const StarterCareTask({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.time,
    required this.priority,
  });

  final String title;
  final String subtitle;
  final String type;
  final String time;
  final TaskPriority priority;
}

List<StarterCareTask> starterCareTasksFor(PetSpecies species) {
  return [
    const StarterCareTask(
      title: '完成首次环境检查',
      subtitle: '确认环境布置与安全区域',
      type: '环境',
      time: '18:00',
      priority: TaskPriority.must,
    ),
    ...switch (species.category) {
      '水族' => const [
        StarterCareTask(
          title: '检查水质',
          subtitle: '观察水温、水面与过滤运行',
          type: '水族',
          time: '09:00',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '准备当天喂食',
          subtitle: '按食物计划控制每餐用量',
          type: '喂食',
          time: '18:30',
          priority: TaskPriority.suggested,
        ),
      ],
      '鸟类' => const [
        StarterCareTask(
          title: '更换饮水',
          subtitle: '清洗饮水器并补充室温水',
          type: '喂食',
          time: '08:30',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '清理栖架',
          subtitle: '检查粪便与活动区域',
          type: '清洁',
          time: '19:00',
          priority: TaskPriority.suggested,
        ),
      ],
      '爬宠' => const [
        StarterCareTask(
          title: '检查温湿度',
          subtitle: '记录冷热区与躲避穴读数',
          type: '环境',
          time: '08:30',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '检查躲避穴',
          subtitle: '确认垫材与湿度状态',
          type: '环境',
          time: '20:00',
          priority: TaskPriority.suggested,
        ),
      ],
      '两栖' => const [
        StarterCareTask(
          title: '检查湿度与水质',
          subtitle: '确认喷淋、水盆与通风状态',
          type: '环境',
          time: '09:00',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '准备当天喂食',
          subtitle: '按计划记录进食情况',
          type: '喂食',
          time: '19:00',
          priority: TaskPriority.suggested,
        ),
      ],
      '哺乳' => const [
        StarterCareTask(
          title: '准备饮水和食物',
          subtitle: '清洗食盆并检查饮用水',
          type: '喂食',
          time: '08:00',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '清理生活区',
          subtitle: '检查睡眠区与排泄情况',
          type: '清洁',
          time: '20:00',
          priority: TaskPriority.suggested,
        ),
      ],
      _ => const [
        StarterCareTask(
          title: '准备当天食物',
          subtitle: '按食物计划控制用量',
          type: '喂食',
          time: '08:30',
          priority: TaskPriority.must,
        ),
        StarterCareTask(
          title: '检查饲养环境',
          subtitle: '确认温湿度、清洁与安全',
          type: '环境',
          time: '20:00',
          priority: TaskPriority.suggested,
        ),
      ],
    },
  ];
}

class JournalEntry {
  JournalEntry({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    this.occurredAt,
    this.attachmentPath,
    this.followUpAt,
    this.contactedVet = false,
    this.riskLevel = 'normal',
  });

  final String title;
  final String description;
  final String time;
  final IconData icon;
  final DateTime? occurredAt;
  final String? attachmentPath;
  final DateTime? followUpAt;
  final bool contactedVet;
  final String riskLevel;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'time': time,
    'iconKey': _iconStorageKey(icon),
    'occurredAt': occurredAt?.toIso8601String(),
    'attachmentPath': attachmentPath,
    'followUpAt': followUpAt?.toIso8601String(),
    'contactedVet': contactedVet,
    'riskLevel': riskLevel,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      title: json['title'] as String? ?? '健康观察',
      description: json['description'] as String? ?? '',
      time: json['time'] as String? ?? '',
      icon: _iconFromJson(json),
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? ''),
      attachmentPath: json['attachmentPath'] as String?,
      followUpAt: DateTime.tryParse(json['followUpAt'] as String? ?? ''),
      contactedVet: json['contactedVet'] as bool? ?? false,
      riskLevel: json['riskLevel'] as String? ?? 'normal',
    );
  }
}

class WeightRecord {
  const WeightRecord({required this.value, required this.recordedAt});

  final double value;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'value': value,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      value: (json['value'] as num? ?? 0).toDouble(),
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

List<WeightRecord> _deriveWeightHistory(
  List<double> weights,
  List<JournalEntry> logs,
) {
  final fromLogs = <WeightRecord>[];
  for (final entry in logs.reversed) {
    if (entry.title != '体重记录') continue;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(entry.description);
    final value = double.tryParse(match?.group(1) ?? '');
    if (value == null || value <= 0) continue;
    fromLogs.add(
      WeightRecord(
        value: value,
        recordedAt: entry.occurredAt ?? DateTime.now(),
      ),
    );
  }
  final positiveWeights = weights.where((value) => value > 0).toList();
  if (fromLogs.isNotEmpty && fromLogs.length >= positiveWeights.length) {
    return fromLogs;
  }
  final now = DateTime.now();
  return [
    for (var index = 0; index < positiveWeights.length; index++)
      WeightRecord(
        value: positiveWeights[index],
        recordedAt: now.subtract(
          Duration(days: (positiveWeights.length - index - 1) * 7),
        ),
      ),
  ];
}

class PetProfile {
  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.status,
    required this.environment,
    required this.age,
    required this.temperature,
    required this.humidity,
    required this.weight,
    required this.logs,
    required this.weights,
    List<WeightRecord>? weightHistory,
    this.roomId = '',
    this.warning = false,
    this.startedAt,
    this.birthday,
    this.gender = '',
    List<String>? photos,
  }) : photos = photos ?? [],
       weightHistory = weightHistory ?? _deriveWeightHistory(weights, logs);

  final String id;
  final String name;
  final PetSpecies species;
  final String status;
  final String environment;
  final String age;
  final String temperature;
  final String humidity;
  final String weight;
  final List<JournalEntry> logs;
  final List<double> weights;
  final List<WeightRecord> weightHistory;
  final String roomId;
  final bool warning;
  final DateTime? startedAt;
  final DateTime? birthday;
  final String gender;
  final List<String> photos;

  PetProfile copyWith({
    String? roomId,
    String? environment,
    String? temperature,
    String? humidity,
    String? weight,
    String? name,
    String? age,
    List<String>? photos,
    DateTime? birthday,
    String? gender,
    DateTime? startedAt,
    List<double>? weights,
    List<WeightRecord>? weightHistory,
  }) {
    return PetProfile(
      id: id,
      name: name ?? this.name,
      species: species,
      status: status,
      environment: environment ?? this.environment,
      age: age ?? this.age,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      weight: weight ?? this.weight,
      logs: logs,
      weights: weights ?? this.weights,
      weightHistory: weightHistory ?? this.weightHistory,
      roomId: roomId ?? this.roomId,
      warning: warning,
      startedAt: startedAt ?? this.startedAt,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species.id,
    'speciesTemplate': species.toJson(),
    'status': status,
    'environment': environment,
    'age': age,
    'temperature': temperature,
    'humidity': humidity,
    'weight': weight,
    'warning': warning,
    'roomId': roomId,
    'startedAt': startedAt?.toIso8601String(),
    'birthday': birthday?.toIso8601String(),
    'gender': gender,
    'photos': photos,
    'logs': logs.map((entry) => entry.toJson()).toList(),
    'weights': weights,
    'weightHistory': weightHistory.map((entry) => entry.toJson()).toList(),
  };

  factory PetProfile.fromJson(
    Map<String, dynamic> json, {
    Iterable<PetSpecies>? templates,
  }) {
    final embeddedTemplate = json['speciesTemplate'];
    final logs = (json['logs'] as List<dynamic>? ?? [])
        .map((item) => JournalEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    final weights = (json['weights'] as List<dynamic>? ?? [])
        .map((value) => (value as num).toDouble())
        .toList();
    final rawWeightHistory = json['weightHistory'] as List<dynamic>?;
    return PetProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名',
      species: embeddedTemplate is Map<String, dynamic>
          ? PetSpecies.fromJson(embeddedTemplate)
          : PetSpecies.fromName(
              json['species'] as String? ?? '',
              templates: templates,
            ),
      status: json['status'] as String? ?? '状态良好',
      environment: json['environment'] as String? ?? '未设置环境',
      age: json['age'] as String? ?? '年龄待补充',
      temperature: json['temperature'] as String? ?? '未记录',
      humidity: json['humidity'] as String? ?? '未记录',
      weight: json['weight'] as String? ?? '未记录',
      warning: json['warning'] as bool? ?? false,
      roomId: json['roomId'] as String? ?? '',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      birthday: DateTime.tryParse(json['birthday'] as String? ?? ''),
      gender: json['gender'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      logs: logs,
      weights: weights,
      weightHistory: rawWeightHistory
          ?.map((item) => WeightRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PetRoom {
  PetRoom({
    required this.id,
    required this.name,
    required this.type,
    this.notes = '',
  });

  final String id;
  final String name;
  final String type;
  final String notes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'notes': notes,
  };

  factory PetRoom.fromJson(Map<String, dynamic> json) {
    return PetRoom(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名房间',
      type: json['type'] as String? ?? '室内',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class FoodSupply {
  FoodSupply({
    required this.id,
    required this.petId,
    required this.name,
    required this.unit,
    required this.remainingAmount,
    required this.mealsPerDay,
    required this.amountPerMeal,
    this.kind = '食物',
    this.dailyUsage,
    this.lowStockDays = 3,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String petId;
  final String name;
  final String unit;
  final double remainingAmount;
  final double mealsPerDay;
  final double amountPerMeal;
  final String kind;
  final double? dailyUsage;
  final int lowStockDays;
  final DateTime updatedAt;

  double get dailyConsumption {
    return kind == '食物'
        ? mealsPerDay * amountPerMeal
        : dailyUsage ?? mealsPerDay * amountPerMeal;
  }

  double? get daysRemaining {
    if (dailyConsumption <= 0) return null;
    return remainingAmount / dailyConsumption;
  }

  bool get needsRestock {
    final days = daysRemaining;
    return days != null && days <= lowStockDays;
  }

  FoodSupply copyWith({
    String? name,
    String? unit,
    double? remainingAmount,
    double? mealsPerDay,
    double? amountPerMeal,
    String? kind,
    double? dailyUsage,
    int? lowStockDays,
    DateTime? updatedAt,
  }) {
    return FoodSupply(
      id: id,
      petId: petId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      amountPerMeal: amountPerMeal ?? this.amountPerMeal,
      kind: kind ?? this.kind,
      dailyUsage: dailyUsage ?? this.dailyUsage,
      lowStockDays: lowStockDays ?? this.lowStockDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'name': name,
    'unit': unit,
    'remainingAmount': remainingAmount,
    'mealsPerDay': mealsPerDay,
    'amountPerMeal': amountPerMeal,
    'kind': kind,
    'dailyUsage': dailyUsage,
    'lowStockDays': lowStockDays,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FoodSupply.fromJson(Map<String, dynamic> json) {
    return FoodSupply(
      id: json['id'] as String,
      petId: json['petId'] as String,
      name: json['name'] as String? ?? '食物',
      unit: json['unit'] as String? ?? 'g',
      remainingAmount: (json['remainingAmount'] as num? ?? 0).toDouble(),
      mealsPerDay: (json['mealsPerDay'] as num? ?? 1).toDouble(),
      amountPerMeal: (json['amountPerMeal'] as num? ?? 1).toDouble(),
      kind: json['kind'] as String? ?? '食物',
      dailyUsage: (json['dailyUsage'] as num?)?.toDouble(),
      lowStockDays: json['lowStockDays'] as int? ?? 3,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class CareTaskDefinition {
  CareTaskDefinition({
    required this.id,
    required this.petId,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.defaultTime,
    required this.priority,
    this.enabled = true,
    Set<int> weekdays = const {},
  }) : weekdays = Set.unmodifiable(
         weekdays.where((weekday) => weekday >= 1 && weekday <= 7),
       );

  final String id;
  final String petId;
  final String title;
  final String subtitle;
  final String type;
  final String defaultTime;
  final TaskPriority priority;
  final bool enabled;
  final Set<int> weekdays;

  String get repeatDescription {
    if (weekdays.isEmpty) return '每天';
    if (weekdays.length == 5 && weekdays.containsAll(const {1, 2, 3, 4, 5})) {
      return '工作日';
    }
    if (weekdays.length == 2 && weekdays.containsAll(const {6, 7})) {
      return '周末';
    }
    final labels = weekdays.toList()..sort();
    return '每周${labels.map(weekdayLabel).join('、')}';
  }

  bool appliesOn(DateTime date) {
    return weekdays.isEmpty || weekdays.contains(date.weekday);
  }

  static String weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => '一',
      DateTime.tuesday => '二',
      DateTime.wednesday => '三',
      DateTime.thursday => '四',
      DateTime.friday => '五',
      DateTime.saturday => '六',
      DateTime.sunday => '日',
      _ => '',
    };
  }

  CareTaskDefinition copyWith({bool? enabled, Set<int>? weekdays}) {
    return CareTaskDefinition(
      id: id,
      petId: petId,
      title: title,
      subtitle: subtitle,
      type: type,
      defaultTime: defaultTime,
      priority: priority,
      enabled: enabled ?? this.enabled,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'title': title,
    'subtitle': subtitle,
    'type': type,
    'defaultTime': defaultTime,
    'priority': priority.name,
    'enabled': enabled,
    'weekdays': (weekdays.toList()..sort()),
  };

  factory CareTaskDefinition.fromJson(Map<String, dynamic> json) {
    return CareTaskDefinition(
      id: json['id'] as String,
      petId: json['petId'] as String,
      title: json['title'] as String? ?? '养护任务',
      subtitle: json['subtitle'] as String? ?? '',
      type: json['type'] as String? ?? '照护',
      defaultTime: json['defaultTime'] as String? ?? '18:00',
      priority: TaskPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => TaskPriority.suggested,
      ),
      enabled: json['enabled'] as bool? ?? true,
      weekdays: (json['weekdays'] as List<dynamic>? ?? const [])
          .map((value) => value as int)
          .where((weekday) => weekday >= 1 && weekday <= 7)
          .toSet(),
    );
  }
}

class CareTaskRun {
  CareTaskRun({
    required this.id,
    required this.occurrenceId,
    required this.action,
    required this.note,
    required this.actor,
    required this.performedAt,
  });

  final String id;
  final String occurrenceId;
  final TaskRunAction action;
  final String note;
  final String actor;
  final DateTime performedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'occurrenceId': occurrenceId,
    'action': action.name,
    'note': note,
    'actor': actor,
    'performedAt': performedAt.toIso8601String(),
  };

  factory CareTaskRun.fromJson(Map<String, dynamic> json) {
    return CareTaskRun(
      id: json['id'] as String,
      occurrenceId: json['occurrenceId'] as String? ?? '',
      action: TaskRunAction.values.firstWhere(
        (item) => item.name == json['action'],
        orElse: () => TaskRunAction.reopened,
      ),
      note: json['note'] as String? ?? '',
      actor: json['actor'] as String? ?? '主人',
      performedAt:
          DateTime.tryParse(json['performedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class CareTask {
  CareTask({
    required this.id,
    required this.definitionId,
    required this.petId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.date,
    this.priority = TaskPriority.suggested,
    this.recurring = true,
    List<CareTaskRun>? runs,
  }) : runs = runs ?? [];

  final String id;
  final String definitionId;
  final String petId;
  final String title;
  final String subtitle;
  final String time;
  final String type;
  final DateTime date;
  final TaskPriority priority;
  final bool recurring;
  final List<CareTaskRun> runs;

  TaskStatus get status {
    if (runs.isEmpty) return TaskStatus.pending;
    return switch (runs.last.action) {
      TaskRunAction.completed => TaskStatus.done,
      TaskRunAction.skipped => TaskStatus.skipped,
      TaskRunAction.reopened => TaskStatus.pending,
    };
  }

  CareTaskRun? get latestRun => runs.isEmpty ? null : runs.last;

  Map<String, dynamic> toJson() => {
    'id': id,
    'definitionId': definitionId,
    'petId': petId,
    'title': title,
    'subtitle': subtitle,
    'time': time,
    'type': type,
    'date': date.toIso8601String(),
    'priority': priority.name,
    'recurring': recurring,
    'runs': runs.map((run) => run.toJson()).toList(),
  };

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: json['id'] as String,
      definitionId: json['definitionId'] as String? ?? '',
      petId: json['petId'] as String,
      title: json['title'] as String? ?? '养护任务',
      subtitle: json['subtitle'] as String? ?? '',
      time: json['time'] as String? ?? '18:00',
      type: json['type'] as String? ?? '照护',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => TaskPriority.suggested,
      ),
      recurring: json['recurring'] as bool? ?? true,
      runs: (json['runs'] as List<dynamic>? ?? [])
          .map((item) => CareTaskRun.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HandoffGrant {
  HandoffGrant({
    required this.id,
    required this.petId,
    required this.token,
    required this.permissions,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String petId;
  final String token;
  final Map<String, bool> permissions;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null && expiresAt.isAfter(DateTime.now());

  String get link => 'https://petcare.local/h/$token';

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'token': token,
    'permissions': permissions,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'revokedAt': revokedAt?.toIso8601String(),
  };

  factory HandoffGrant.fromJson(Map<String, dynamic> json) {
    return HandoffGrant(
      id: json['id'] as String,
      petId: json['petId'] as String,
      token: json['token'] as String,
      permissions: Map<String, bool>.from(
        json['permissions'] as Map? ?? <String, bool>{},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now(),
      revokedAt: DateTime.tryParse(json['revokedAt'] as String? ?? ''),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState._(this._preferences);

  static const _storageKey = 'petcare.state.v2';
  static const _schemaVersion = 4;
  static const _taskRetentionDays = 180;
  static const guestRetention = Duration(days: 3);
  static final List<String> availableCities = ChinaCities.all
      .map((city) => city.value)
      .toList(growable: false);
  static const careTagOptions = [
    '猫猫教',
    '狗狗派',
    '双倍毛茸茸',
    '科学喂养派',
    '环境布置控',
    '异宠观察员',
    '水族造景师',
    '鸟语爱好者',
  ];
  static const _legacyCareTagMap = {
    '猫': '猫猫教',
    '狗': '狗狗派',
    '鸟类': '鸟语爱好者',
    '水族': '水族造景师',
    '爬宠': '异宠观察员',
    '异宠': '异宠观察员',
  };

  final SharedPreferences? _preferences;
  Future<void>? _persistInFlight;
  bool _persistQueued = false;
  Object? _lastPersistenceError;
  final List<PetProfile> pets = [];
  final List<PetSpecies> speciesTemplates = [];
  final Set<String> hiddenSpeciesTemplateIds = {};
  final List<PetRoom> rooms = [];
  final List<FoodSupply> foodSupplies = [];
  final List<CareTaskDefinition> taskDefinitions = [];
  final List<CareTask> tasks = [];
  final List<HandoffGrant> handoffGrants = [];

  bool notifications = true;
  bool hapticFeedback = true;
  bool signedIn = true;
  bool isGuest = false;
  bool onboardingCompleted = true;
  bool memberOnboardingCompleted = false;
  DateTime? guestExpiresAt;
  String nickname = '栖护主人';
  String? avatarPath;
  String city = '上海';
  List<String> careTags = [];
  int? borrowFlag;

  int get petLimit => isGuest ? 3 : 999;
  bool get canAddPet => pets.length < petLimit;
  bool get needsMemberOnboarding =>
      signedIn && !isGuest && !memberOnboardingCompleted;
  bool get updateChecksAllowed => !isGuest && signedIn && borrowFlag == 1;

  static Future<AppState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final state = AppState._(preferences);
    final restored = state._restore(preferences.getString(_storageKey));
    if (!restored) {
      state._seedReferenceData();
      state.signedIn = false;
      state.onboardingCompleted = false;
      state.memberOnboardingCompleted = false;
    } else {
      state.refreshGuestDataWindow();
    }
    state.ensureOccurrencesThrough();
    await state._persist();
    return state;
  }

  factory AppState.inMemory({bool seed = true}) {
    final state = AppState._(null);
    if (seed) {
      state._seed();
      state.memberOnboardingCompleted = true;
    }
    state.ensureOccurrencesThrough();
    return state;
  }

  List<CareTask> get todayTasks {
    final today = DateTime.now();
    final result = tasks.where((task) => _isSameDay(task.date, today)).toList();
    result.sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  List<CareTask> get pendingTasks =>
      todayTasks.where((task) => task.status == TaskStatus.pending).toList();

  CareTask? get nextTask => pendingTasks.firstOrNull;

  int get completedCount =>
      todayTasks.where((task) => task.status == TaskStatus.done).length;

  int get pendingCount =>
      todayTasks.where((task) => task.status == TaskStatus.pending).length;

  int get progress {
    final total = todayTasks.length;
    return total == 0 ? 0 : ((completedCount / total) * 100).round();
  }

  int get healthLogCount =>
      pets.fold(0, (total, pet) => total + pet.logs.length);

  int taskCountForPetSince(String petId, {int days = 7, DateTime? now}) {
    final current = _dateOnly(now ?? DateTime.now());
    final start = current.subtract(Duration(days: days - 1));
    final end = current.add(const Duration(days: 1));
    return tasks
        .where(
          (task) =>
              task.petId == petId &&
              !task.date.isBefore(start) &&
              task.date.isBefore(end),
        )
        .length;
  }

  List<String> get speciesCategories {
    final categories = <String>[];
    for (final template in speciesTemplates) {
      if (!categories.contains(template.category)) {
        categories.add(template.category);
      }
    }
    return categories;
  }

  List<HandoffGrant> get activeHandoffs =>
      handoffGrants.where((grant) => grant.isActive).toList();

  List<FoodSupply> get lowStockFoods =>
      foodSupplies.where((food) => food.needsRestock).toList();

  PetProfile petById(String id) {
    final pet = petByIdOrNull(id);
    if (pet == null) throw StateError('宠物不存在：$id');
    return pet;
  }

  PetProfile? petByIdOrNull(String id) =>
      pets.where((pet) => pet.id == id).firstOrNull;

  CareTask? taskById(String id) {
    return tasks.where((task) => task.id == id).firstOrNull;
  }

  PetRoom roomById(String id) {
    return rooms.firstWhere(
      (room) => room.id == id,
      orElse: () => rooms.isEmpty
          ? PetRoom(id: 'default-room', name: '默认空间', type: '室内')
          : rooms.first,
    );
  }

  PetRoom addRoom({
    required String name,
    required String type,
    String notes = '',
  }) {
    final room = PetRoom(
      id: 'room-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      type: type,
      notes: notes.trim(),
    );
    rooms.add(room);
    notifyListeners();
    unawaited(_persist());
    return room;
  }

  void updateRoom({
    required String id,
    required String name,
    required String type,
    String notes = '',
  }) {
    final index = rooms.indexWhere((room) => room.id == id);
    if (index < 0 || name.trim().isEmpty) return;
    rooms[index] = PetRoom(
      id: rooms[index].id,
      name: name.trim(),
      type: type,
      notes: notes.trim(),
    );
    notifyListeners();
    unawaited(_persist());
  }

  bool deleteRoom(String id) {
    if (rooms.length <= 1) return false;
    final fallback = rooms.firstWhere((room) => room.id != id);
    rooms.removeWhere((room) => room.id == id);
    for (var index = 0; index < pets.length; index++) {
      if (pets[index].roomId == id) {
        pets[index] = pets[index].copyWith(roomId: fallback.id);
      }
    }
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  void movePetToRoom(String petId, String roomId) {
    final index = pets.indexWhere((pet) => pet.id == petId);
    if (index < 0 || rooms.every((room) => room.id != roomId)) return;
    pets[index] = pets[index].copyWith(roomId: roomId);
    notifyListeners();
    unawaited(_persist());
  }

  void updatePetMetrics(
    String petId, {
    String? temperature,
    String? humidity,
    String? weight,
  }) {
    final index = pets.indexWhere((pet) => pet.id == petId);
    if (index < 0) return;
    final current = pets[index];
    final nextWeights = [...current.weights];
    final nextWeightHistory = [...current.weightHistory];
    final numericWeight = weight == null
        ? null
        : double.tryParse(
            RegExp(r'-?\d+(?:\.\d+)?').firstMatch(weight)?.group(0) ?? '',
          );
    if (numericWeight != null && numericWeight > 0) {
      nextWeights.add(numericWeight);
      nextWeightHistory.add(
        WeightRecord(value: numericWeight, recordedAt: DateTime.now()),
      );
    }
    pets[index] = current.copyWith(
      temperature: temperature,
      humidity: humidity,
      weight: weight,
      weights: nextWeights,
      weightHistory: nextWeightHistory,
    );
    notifyListeners();
    unawaited(_persist());
  }

  void updatePetProfile(
    String petId, {
    required String name,
    required String environment,
    required String roomId,
    required DateTime? birthday,
    required String gender,
    required DateTime? startedAt,
    required List<String> photos,
  }) {
    final index = pets.indexWhere((pet) => pet.id == petId);
    if (index < 0) return;
    pets[index] = pets[index].copyWith(
      name: name.trim().isEmpty ? pets[index].name : name.trim(),
      environment: environment.trim(),
      roomId: roomId,
      age: birthday == null ? pets[index].age : _ageFromBirthday(birthday),
      birthday: birthday,
      gender: gender,
      startedAt: startedAt,
      photos: photos,
    );
    notifyListeners();
    unawaited(_persist());
  }

  FoodSupply upsertFoodSupply({
    String? id,
    required String petId,
    required String name,
    required String unit,
    required double remainingAmount,
    required double mealsPerDay,
    required double amountPerMeal,
    String kind = '食物',
    double? dailyUsage,
    int lowStockDays = 3,
  }) {
    final existingIndex = id == null
        ? -1
        : foodSupplies.indexWhere((food) => food.id == id);
    final supply = FoodSupply(
      id: id ?? 'food-${DateTime.now().microsecondsSinceEpoch}',
      petId: petId,
      name: name.trim(),
      unit: unit.trim(),
      remainingAmount: remainingAmount,
      mealsPerDay: mealsPerDay,
      amountPerMeal: amountPerMeal,
      kind: kind,
      dailyUsage: dailyUsage,
      lowStockDays: lowStockDays,
      updatedAt: DateTime.now(),
    );
    if (existingIndex >= 0) {
      foodSupplies[existingIndex] = supply;
    } else {
      foodSupplies.add(supply);
    }
    notifyListeners();
    unawaited(_persist());
    return supply;
  }

  void restockFood(String id, double amount) {
    final index = foodSupplies.indexWhere((food) => food.id == id);
    if (index < 0) return;
    foodSupplies[index] = foodSupplies[index].copyWith(
      remainingAmount: foodSupplies[index].remainingAmount + amount,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void consumeFoodSupply(String id, double amount) {
    if (amount <= 0) return;
    final index = foodSupplies.indexWhere((food) => food.id == id);
    if (index < 0) return;
    final nextAmount = (foodSupplies[index].remainingAmount - amount)
        .clamp(0.0, double.infinity)
        .toDouble();
    foodSupplies[index] = foodSupplies[index].copyWith(
      remainingAmount: nextAmount,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void deleteFoodSupply(String id) {
    foodSupplies.removeWhere((food) => food.id == id);
    notifyListeners();
    unawaited(_persist());
  }

  void ensureTodayOccurrences([DateTime? now]) {
    ensureOccurrencesThrough(now: now, daysAhead: 0);
  }

  void ensureOccurrencesThrough({DateTime? now, int daysAhead = 7}) {
    final start = _dateOnly(now ?? DateTime.now());
    final existing = {
      for (final task in tasks)
        if (task.definitionId.isNotEmpty)
          '${task.definitionId}:${_dateKey(task.date)}',
    };
    for (var dayOffset = 0; dayOffset <= daysAhead; dayOffset++) {
      final date = start.add(Duration(days: dayOffset));
      for (final definition in taskDefinitions.where((item) => item.enabled)) {
        if (!definition.appliesOn(date)) continue;
        final key = '${definition.id}:${_dateKey(date)}';
        if (!existing.add(key)) continue;
        tasks.add(
          CareTask(
            id: '${definition.id}-${_dateKey(date)}',
            definitionId: definition.id,
            petId: definition.petId,
            title: definition.title,
            subtitle: definition.subtitle,
            time: definition.defaultTime,
            type: definition.type,
            date: date,
            priority: definition.priority,
            recurring: true,
          ),
        );
      }
    }
    final cutoff = start.subtract(const Duration(days: _taskRetentionDays));
    tasks.removeWhere((task) => task.date.isBefore(cutoff));
    notifyListeners();
  }

  void toggleTask(String id) {
    final task = taskById(id);
    if (task == null) return;
    if (task.status == TaskStatus.done) {
      reopenTask(id);
    } else {
      completeTask(id);
    }
  }

  void completeTask(String id, {String note = ''}) {
    _appendRun(id, TaskRunAction.completed, note: note);
  }

  void skipTask(String id, {String note = ''}) {
    _appendRun(id, TaskRunAction.skipped, note: note);
  }

  void reopenTask(String id) {
    _appendRun(id, TaskRunAction.reopened, note: '撤销完成状态');
  }

  void _appendRun(String id, TaskRunAction action, {String note = ''}) {
    final task = taskById(id);
    if (task == null) return;
    final now = DateTime.now();
    task.runs.add(
      CareTaskRun(
        id: 'run-${now.microsecondsSinceEpoch}',
        occurrenceId: task.id,
        action: action,
        note: note.trim(),
        actor: '主人',
        performedAt: now,
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  PetProfile? addPet({
    required PetSpecies species,
    required String name,
    required String environment,
    String roomId = '',
    DateTime? startedAt,
    DateTime? birthday,
    String gender = '',
    List<String> photos = const [],
  }) {
    if (!canAddPet) return null;
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final pet = PetProfile(
      id: 'pet-$stamp',
      name: name,
      species: species,
      roomId: roomId,
      startedAt: startedAt,
      birthday: birthday,
      gender: gender,
      photos: List<String>.from(photos),
      status: '状态良好',
      environment: environment,
      age: birthday == null ? '年龄待补充' : _ageFromBirthday(birthday),
      temperature: '未记录',
      humidity: '未记录',
      weight: '未记录',
      logs: [
        JournalEntry(
          title: '完成建档',
          description: '已应用物种模板，可以开始记录健康与任务。',
          time: '刚刚',
          icon: Icons.auto_awesome_outlined,
          occurredAt: now,
        ),
      ],
      weights: const [0, 0, 0, 0, 0, 0],
    );
    pets.insert(0, pet);

    final starterTasks = starterCareTasksFor(species);
    for (var index = 0; index < starterTasks.length; index++) {
      final need = starterTasks[index];
      final definition = CareTaskDefinition(
        id: 'definition-$stamp-$index',
        petId: pet.id,
        title: need.title,
        subtitle: need.subtitle,
        type: need.type,
        defaultTime: need.time,
        priority: need.priority,
      );
      taskDefinitions.add(definition);
      tasks.insert(
        0,
        CareTask(
          id: '${definition.id}-${_dateKey(now)}',
          definitionId: definition.id,
          petId: pet.id,
          title: definition.title,
          subtitle: definition.subtitle,
          time: definition.defaultTime,
          type: definition.type,
          date: _dateOnly(now),
          priority: definition.priority,
        ),
      );
    }
    notifyListeners();
    unawaited(_persist());
    return pet;
  }

  PetSpecies addSpeciesTemplate({
    required String label,
    required String category,
    required String artStyle,
    required Color background,
    required Color backgroundEnd,
    required Color ink,
    String note = '',
  }) {
    final now = DateTime.now();
    final template = PetSpecies(
      id: 'custom-${now.microsecondsSinceEpoch}',
      label: label.trim(),
      category: category.trim().isEmpty ? '异宠' : category.trim(),
      background: background,
      backgroundEnd: backgroundEnd,
      ink: ink,
      artStyle: artStyle,
      code: 'CUSTOM',
      builtIn: false,
      note: note.trim(),
    );
    speciesTemplates.add(template);
    notifyListeners();
    unawaited(_persist());
    return template;
  }

  bool deleteSpeciesTemplate(String id) {
    if (speciesTemplates.length <= 1) return false;
    final before = speciesTemplates.length;
    speciesTemplates.removeWhere((template) => template.id == id);
    if (speciesTemplates.length == before) return false;
    if (PetSpecies.builtIns.any((template) => template.id == id)) {
      hiddenSpeciesTemplateIds.add(id);
    }
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  void addTask({
    required String petId,
    required String title,
    required String time,
    required String type,
    bool recurring = true,
    DateTime? date,
    Set<int> weekdays = const {},
  }) {
    final now = DateTime.now();
    final stamp = now.microsecondsSinceEpoch;
    final taskDate = _dateOnly(date ?? now);
    if (recurring) {
      taskDefinitions.add(
        CareTaskDefinition(
          id: 'definition-$stamp',
          petId: petId,
          title: title,
          subtitle: '按计划重复的照护任务',
          type: type,
          defaultTime: time,
          priority: TaskPriority.suggested,
          weekdays: weekdays,
        ),
      );
      ensureOccurrencesThrough();
    } else {
      tasks.insert(
        0,
        CareTask(
          id: 'oneoff-${_dateKey(taskDate)}-$stamp',
          definitionId: '',
          petId: petId,
          title: title,
          subtitle: '一次性养护任务',
          time: time,
          type: type,
          date: taskDate,
          priority: TaskPriority.suggested,
          recurring: false,
        ),
      );
    }
    notifyListeners();
    unawaited(_persist());
  }

  void setTaskDefinitionEnabled(String id, bool enabled) {
    final index = taskDefinitions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    taskDefinitions[index] = taskDefinitions[index].copyWith(enabled: enabled);
    notifyListeners();
    unawaited(_persist());
  }

  void deleteTaskDefinition(String id) {
    taskDefinitions.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_persist());
  }

  void addHealthLog({
    required String petId,
    required String tag,
    required String description,
    String? attachmentPath,
    DateTime? followUpAt,
    bool contactedVet = false,
    String riskLevel = 'normal',
  }) {
    final pet = petById(petId);
    final now = DateTime.now();
    final icon = switch (tag) {
      '进食' => Icons.ramen_dining_outlined,
      '蜕皮' => Icons.auto_awesome_outlined,
      '排便' => Icons.eco_outlined,
      _ => Icons.visibility_outlined,
    };
    pet.logs.insert(
      0,
      JournalEntry(
        title: tag,
        description: description.trim().isEmpty ? '健康观察已记录。' : description,
        time: '刚刚',
        icon: icon,
        occurredAt: now,
        attachmentPath: attachmentPath,
        followUpAt: followUpAt,
        contactedVet: contactedVet,
        riskLevel: riskLevel,
      ),
    );
    notifyListeners();
    unawaited(_persist());
  }

  HandoffGrant createHandoff({
    required String petId,
    required int durationDays,
    required Map<String, bool> permissions,
  }) {
    final now = DateTime.now();
    final grant = HandoffGrant(
      id: 'handoff-${now.microsecondsSinceEpoch}',
      petId: petId,
      token: _generateToken(),
      permissions: Map<String, bool>.from(permissions),
      createdAt: now,
      expiresAt: now.add(Duration(days: durationDays)),
    );
    handoffGrants.insert(0, grant);
    notifyListeners();
    unawaited(_persist());
    return grant;
  }

  void revokeHandoff(String id) {
    final index = handoffGrants.indexWhere((grant) => grant.id == id);
    if (index == -1) return;
    final current = handoffGrants[index];
    handoffGrants[index] = HandoffGrant(
      id: current.id,
      petId: current.petId,
      token: current.token,
      permissions: current.permissions,
      createdAt: current.createdAt,
      expiresAt: current.expiresAt,
      revokedAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void updateSettings({bool? notifications, bool? hapticFeedback}) {
    if (notifications != null) this.notifications = notifications;
    if (hapticFeedback != null) this.hapticFeedback = hapticFeedback;
    notifyListeners();
    unawaited(_persist());
  }

  void updateNickname(String value) {
    final next = value.trim();
    if (next.isEmpty) return;
    nickname = next;
    notifyListeners();
    unawaited(_persist());
  }

  void updateCity(String value) {
    final next = normalizeCity(value);
    if (next.isEmpty) return;
    city = next;
    notifyListeners();
    unawaited(_persist());
  }

  void updateProfile({
    required String nickname,
    required String? avatarPath,
    String? city,
    List<String>? careTags,
  }) {
    final next = nickname.trim();
    if (next.isEmpty) return;
    this.nickname = next;
    this.avatarPath = avatarPath;
    if (city != null && city.trim().isNotEmpty) {
      this.city = normalizeCity(city);
    }
    if (careTags != null) this.careTags = List<String>.from(careTags);
    notifyListeners();
    unawaited(_persist());
  }

  void updateBorrowFlag(int? value) {
    if (borrowFlag == value) return;
    borrowFlag = value;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> flush() async {
    await _persist();
    final error = _lastPersistenceError;
    if (error != null) {
      throw StateError('本地数据保存失败：$error');
    }
  }

  bool refreshGuestDataWindow({DateTime? now}) {
    if (!isGuest) return false;
    final current = now ?? DateTime.now();
    guestExpiresAt ??= current.add(guestRetention);
    if (current.isBefore(guestExpiresAt!)) return false;
    _clearUserData();
    guestExpiresAt = current.add(guestRetention);
    _guestDataResetPending = true;
    notifyListeners();
    unawaited(_persist());
    return true;
  }

  bool _guestDataResetPending = false;

  bool consumeGuestDataReset() {
    final pending = _guestDataResetPending;
    _guestDataResetPending = false;
    return pending;
  }

  void signOut() {
    signedIn = false;
    borrowFlag = null;
    notifyListeners();
    unawaited(_persist());
  }

  void startMemberLogin({bool profileCompleted = false}) {
    if (isGuest) _clearUserData();
    if (profileCompleted) {
      memberOnboardingCompleted = true;
      onboardingCompleted = true;
    }
    signedIn = true;
    isGuest = false;
    guestExpiresAt = null;
    onboardingCompleted = memberOnboardingCompleted;
    notifyListeners();
    unawaited(_persist());
  }

  void enterGuestMode() {
    _seedReferenceData();
    ensureOccurrencesThrough();
    signedIn = true;
    isGuest = true;
    borrowFlag = null;
    guestExpiresAt ??= DateTime.now().add(guestRetention);
    onboardingCompleted = true;
    notifyListeners();
    unawaited(_persist());
  }

  void completeOnboarding({
    required String nickname,
    required String? avatarPath,
    required String city,
    required List<String> careTags,
  }) {
    _seedReferenceData();
    ensureOccurrencesThrough();
    updateProfile(
      nickname: nickname,
      avatarPath: avatarPath,
      city: city,
      careTags: careTags,
    );
    signedIn = true;
    isGuest = false;
    memberOnboardingCompleted = true;
    onboardingCompleted = true;
    notifyListeners();
    unawaited(_persist());
  }

  void deleteLocalAccount() {
    _clearUserData();
    speciesTemplates.clear();
    hiddenSpeciesTemplateIds.clear();
    rooms.clear();
    notifications = true;
    hapticFeedback = true;
    signedIn = false;
    isGuest = false;
    onboardingCompleted = false;
    memberOnboardingCompleted = false;
    guestExpiresAt = null;
    borrowFlag = null;
    notifyListeners();
    unawaited(_persist());
  }

  void resetDemo() {
    pets.clear();
    speciesTemplates.clear();
    hiddenSpeciesTemplateIds.clear();
    rooms.clear();
    foodSupplies.clear();
    taskDefinitions.clear();
    tasks.clear();
    handoffGrants.clear();
    _seed();
    borrowFlag = null;
    memberOnboardingCompleted = true;
    onboardingCompleted = true;
    ensureOccurrencesThrough();
    notifyListeners();
    unawaited(_persist());
  }

  void _clearUserData() {
    pets.clear();
    foodSupplies.clear();
    taskDefinitions.clear();
    tasks.clear();
    handoffGrants.clear();
    nickname = '栖护主人';
    avatarPath = null;
    city = '上海';
    careTags = [];
  }

  void _seed() {
    _seedReferenceData();
    pets.addAll(seedPets());
    foodSupplies.addAll(seedFoodSupplies());
    taskDefinitions.addAll(seedTaskDefinitions());
  }

  void _seedReferenceData() {
    if (speciesTemplates.isEmpty) {
      speciesTemplates.addAll(
        PetSpecies.builtIns.where(
          (template) => !hiddenSpeciesTemplateIds.contains(template.id),
        ),
      );
    }
    if (rooms.isEmpty) rooms.addAll(seedRooms());
  }

  bool _restore(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if ((data['schemaVersion'] as int? ?? 0) < 1) return false;
      hiddenSpeciesTemplateIds
        ..clear()
        ..addAll(
          (data['hiddenSpeciesTemplateIds'] as List<dynamic>? ?? const []).map(
            (value) => value.toString(),
          ),
        );
      final restoredTemplates =
          (data['speciesTemplates'] as List<dynamic>? ?? [])
              .map((item) => PetSpecies.fromJson(item as Map<String, dynamic>))
              .toList();
      speciesTemplates
        ..clear()
        ..addAll(
          PetSpecies.builtIns.where(
            (template) => !hiddenSpeciesTemplateIds.contains(template.id),
          ),
        )
        ..addAll(
          restoredTemplates.where(
            (template) => !PetSpecies.builtIns.any(
              (builtIn) => builtIn.id == template.id,
            ),
          ),
        );
      rooms
        ..clear()
        ..addAll(
          (data['rooms'] as List<dynamic>? ?? []).map(
            (item) => PetRoom.fromJson(item as Map<String, dynamic>),
          ),
        );
      if (rooms.isEmpty) rooms.addAll(seedRooms());
      pets
        ..clear()
        ..addAll(
          (data['pets'] as List<dynamic>? ?? []).map(
            (item) => PetProfile.fromJson(
              item as Map<String, dynamic>,
              templates: speciesTemplates,
            ),
          ),
        );
      foodSupplies
        ..clear()
        ..addAll(
          (data['foodSupplies'] as List<dynamic>? ?? []).map(
            (item) => FoodSupply.fromJson(item as Map<String, dynamic>),
          ),
        );
      taskDefinitions
        ..clear()
        ..addAll(
          (data['taskDefinitions'] as List<dynamic>? ?? []).map(
            (item) => CareTaskDefinition.fromJson(item as Map<String, dynamic>),
          ),
        );
      tasks
        ..clear()
        ..addAll(
          (data['tasks'] as List<dynamic>? ?? []).map(
            (item) => CareTask.fromJson(item as Map<String, dynamic>),
          ),
        );
      handoffGrants
        ..clear()
        ..addAll(
          (data['handoffGrants'] as List<dynamic>? ?? []).map(
            (item) => HandoffGrant.fromJson(item as Map<String, dynamic>),
          ),
        );
      notifications = data['notifications'] as bool? ?? true;
      hapticFeedback = data['hapticFeedback'] as bool? ?? true;
      signedIn = data['signedIn'] as bool? ?? true;
      isGuest = data['isGuest'] as bool? ?? false;
      onboardingCompleted = data['onboardingCompleted'] as bool? ?? true;
      memberOnboardingCompleted =
          data['memberOnboardingCompleted'] as bool? ??
          (onboardingCompleted && !isGuest);
      guestExpiresAt = DateTime.tryParse(
        data['guestExpiresAt'] as String? ?? '',
      );
      nickname = data['nickname'] as String? ?? '栖护主人';
      avatarPath = data['avatarPath'] as String?;
      city = normalizeCity(data['city'] as String? ?? '上海');
      careTags = (data['careTags'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .map((tag) => _legacyCareTagMap[tag] ?? tag)
          .where(careTagOptions.contains)
          .toSet()
          .toList();
      borrowFlag = int.tryParse(data['borrowFlag']?.toString() ?? '');
      return true;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }

  Future<void> _persist() {
    final preferences = _preferences;
    if (preferences == null) return Future.value();
    _persistQueued = true;
    return _persistInFlight ??= _drainPersistenceQueue();
  }

  Future<void> _drainPersistenceQueue() async {
    try {
      while (_persistQueued) {
        _persistQueued = false;
        try {
          await _writeSnapshot();
          _lastPersistenceError = null;
        } on Object catch (error) {
          _lastPersistenceError = error;
        }
      }
    } finally {
      _persistInFlight = null;
    }
  }

  Future<void> _writeSnapshot() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final data = {
      'schemaVersion': _schemaVersion,
      'pets': pets.map((pet) => pet.toJson()).toList(),
      'speciesTemplates': speciesTemplates
          .where((template) => !template.builtIn)
          .map((template) => template.toJson())
          .toList(),
      'hiddenSpeciesTemplateIds': hiddenSpeciesTemplateIds.toList()..sort(),
      'rooms': rooms.map((room) => room.toJson()).toList(),
      'foodSupplies': foodSupplies.map((food) => food.toJson()).toList(),
      'taskDefinitions': taskDefinitions
          .map((definition) => definition.toJson())
          .toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'handoffGrants': handoffGrants.map((grant) => grant.toJson()).toList(),
      'notifications': notifications,
      'hapticFeedback': hapticFeedback,
      'signedIn': signedIn,
      'isGuest': isGuest,
      'onboardingCompleted': onboardingCompleted,
      'memberOnboardingCompleted': memberOnboardingCompleted,
      'guestExpiresAt': guestExpiresAt?.toIso8601String(),
      'nickname': nickname,
      'avatarPath': avatarPath,
      'city': city,
      'careTags': careTags,
      'borrowFlag': borrowFlag,
    };
    await preferences.setString(_storageKey, jsonEncode(data));
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String normalizeCity(String value) {
    final matched = ChinaCities.match(value);
    if (matched != null) return matched.value;
    final parts = value
        .split('·')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    final city = parts.last.replaceFirst(RegExp(r'市$'), '');
    return parts.length == 1 ? city : '${parts.first} · $city';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateKey(DateTime value) {
    return '${value.year}${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}

String _ageFromBirthday(DateTime birthday, [DateTime? now]) {
  final current = now ?? DateTime.now();
  var years = current.year - birthday.year;
  var months = current.month - birthday.month;
  if (current.day < birthday.day) months--;
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years < 0) return '年龄待补充';
  if (years == 0) return '${months.clamp(0, 11)} 个月';
  return '$years 岁${months > 0 ? ' $months 个月' : ''}';
}

String _iconStorageKey(IconData icon) {
  if (icon.codePoint == Icons.ramen_dining_outlined.codePoint) return 'meal';
  if (icon.codePoint == Icons.auto_awesome_outlined.codePoint) return 'sparkle';
  if (icon.codePoint == Icons.monitor_weight_outlined.codePoint) {
    return 'weight';
  }
  if (icon.codePoint == Icons.eco_outlined.codePoint) return 'leaf';
  if (icon.codePoint == Icons.water_drop_outlined.codePoint) return 'water';
  return 'observation';
}

IconData _iconFromJson(Map<String, dynamic> json) {
  final key = json['iconKey'] as String?;
  if (key == 'meal') return Icons.ramen_dining_outlined;
  if (key == 'sparkle') return Icons.auto_awesome_outlined;
  if (key == 'weight') return Icons.monitor_weight_outlined;
  if (key == 'leaf') return Icons.eco_outlined;
  if (key == 'water') return Icons.water_drop_outlined;

  final codePoint = json['iconCodePoint'] as int?;
  if (codePoint == Icons.ramen_dining_outlined.codePoint) {
    return Icons.ramen_dining_outlined;
  }
  if (codePoint == Icons.auto_awesome_outlined.codePoint) {
    return Icons.auto_awesome_outlined;
  }
  if (codePoint == Icons.monitor_weight_outlined.codePoint) {
    return Icons.monitor_weight_outlined;
  }
  if (codePoint == Icons.eco_outlined.codePoint) return Icons.eco_outlined;
  if (codePoint == Icons.water_drop_outlined.codePoint) {
    return Icons.water_drop_outlined;
  }
  return Icons.visibility_outlined;
}

List<PetProfile> seedPets() {
  final now = DateTime.now();
  return [
    PetProfile(
      id: 'mochi',
      name: '糯米',
      species: PetSpecies.gecko,
      status: '状态良好',
      environment: '雨林躲避箱',
      age: '1 岁 4 个月',
      temperature: '29.2°C',
      humidity: '58%',
      weight: '62 g',
      roomId: 'room-reptile',
      gender: '雄性',
      birthday: DateTime(now.year - 1, now.month - 4, now.day),
      startedAt: now.subtract(const Duration(days: 240)),
      logs: [
        JournalEntry(
          title: '进食完成',
          description: '吃下 3 只活饵，状态活跃。',
          time: '今天 08:42',
          icon: Icons.ramen_dining_outlined,
          occurredAt: DateTime(now.year, now.month, now.day, 8, 42),
        ),
        JournalEntry(
          title: '完成蜕皮',
          description: '脚趾与尾部蜕皮完整，未发现残留。',
          time: '3 天前',
          icon: Icons.auto_awesome_outlined,
          occurredAt: now.subtract(const Duration(days: 3)),
        ),
        JournalEntry(
          title: '体重记录',
          description: '本月体重从 58 g 增至 62 g。',
          time: '6 天前',
          icon: Icons.monitor_weight_outlined,
          occurredAt: now.subtract(const Duration(days: 6)),
        ),
      ],
      weights: const [54, 56, 57, 58, 59, 62],
    ),
    PetProfile(
      id: 'lulu',
      name: '露露',
      species: PetSpecies.cockatiel,
      status: '需要通风',
      environment: '客厅鸟笼',
      age: '2 岁 1 个月',
      temperature: '24.6°C',
      humidity: '46%',
      weight: '88 g',
      roomId: 'room-living',
      gender: '雌性',
      birthday: DateTime(now.year - 2, now.month - 1, now.day),
      startedAt: now.subtract(const Duration(days: 210)),
      warning: true,
      logs: [
        JournalEntry(
          title: '羽毛检查',
          description: '羽毛状态正常，活动量稳定。',
          time: '今天 09:10',
          icon: Icons.eco_outlined,
          occurredAt: DateTime(now.year, now.month, now.day, 9, 10),
        ),
      ],
      weights: const [86, 86, 87, 87, 88, 88],
    ),
    PetProfile(
      id: 'blue',
      name: '小蓝',
      species: PetSpecies.betta,
      status: '状态良好',
      environment: '15 L 草缸',
      age: '8 个月',
      temperature: '26.1°C',
      humidity: '—',
      weight: '3.2 g',
      roomId: 'room-aquatic',
      gender: '雄性',
      birthday: now.subtract(const Duration(days: 240)),
      startedAt: now.subtract(const Duration(days: 150)),
      logs: [
        JournalEntry(
          title: '换水记录',
          description: '更换 25% 水量，水质清澈。',
          time: '昨天 19:20',
          icon: Icons.water_drop_outlined,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      weights: const [2.4, 2.6, 2.8, 3.0, 3.1, 3.2],
    ),
  ];
}

List<PetRoom> seedRooms() {
  return [
    PetRoom(
      id: 'room-reptile',
      name: '爬宠房',
      type: '温控房间',
      notes: '独立温控与排风，适合守宫、蛇和陆龟。',
    ),
    PetRoom(id: 'room-living', name: '客厅', type: '公共空间', notes: '鸟类与家庭成员活动区域。'),
    PetRoom(
      id: 'room-aquatic',
      name: '水族区',
      type: '水族空间',
      notes: '鱼缸、过滤与备用电源集中区域。',
    ),
  ];
}

List<FoodSupply> seedFoodSupplies() {
  final now = DateTime.now();
  return [
    FoodSupply(
      id: 'food-mochi',
      petId: 'mochi',
      name: '活饵',
      unit: '只',
      remainingAmount: 18,
      mealsPerDay: 2,
      amountPerMeal: 2,
      lowStockDays: 3,
      updatedAt: now,
    ),
    FoodSupply(
      id: 'food-lulu',
      petId: 'lulu',
      name: '滋养丸',
      unit: 'g',
      remainingAmount: 82,
      mealsPerDay: 2,
      amountPerMeal: 6,
      lowStockDays: 3,
      updatedAt: now,
    ),
    FoodSupply(
      id: 'food-blue',
      petId: 'blue',
      name: '斗鱼颗粒',
      unit: 'g',
      remainingAmount: 12,
      mealsPerDay: 2,
      amountPerMeal: 0.25,
      lowStockDays: 5,
      updatedAt: now,
    ),
  ];
}

List<CareTaskDefinition> seedTaskDefinitions() {
  return [
    CareTaskDefinition(
      id: 'definition-environment',
      petId: 'mochi',
      title: '检查温湿度',
      subtitle: '记录加热垫与躲避穴温度',
      type: '环境',
      defaultTime: '08:30',
      priority: TaskPriority.must,
    ),
    CareTaskDefinition(
      id: 'definition-water',
      petId: 'lulu',
      title: '更换饮水',
      subtitle: '清洗水杯并补充室温水',
      type: '喂食',
      defaultTime: '10:00',
      priority: TaskPriority.must,
    ),
    CareTaskDefinition(
      id: 'definition-aquarium',
      petId: 'blue',
      title: '检查水面与滤材',
      subtitle: '确认无浮油与异常泡沫',
      type: '水族',
      defaultTime: '12:30',
      priority: TaskPriority.suggested,
    ),
    CareTaskDefinition(
      id: 'definition-calcium',
      petId: 'mochi',
      title: '补充钙粉',
      subtitle: '与下次喂食一同进行',
      type: '喂食',
      defaultTime: '18:00',
      priority: TaskPriority.suggested,
    ),
    CareTaskDefinition(
      id: 'definition-weight',
      petId: 'lulu',
      title: '称重记录',
      subtitle: '每周一次，保持同一时间',
      type: '健康',
      defaultTime: '20:00',
      priority: TaskPriority.suggested,
    ),
  ];
}
