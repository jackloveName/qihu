import 'models.dart';

class KnowledgeSection {
  const KnowledgeSection(this.title, this.body);

  final String title;
  final String body;
}

class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.keywords,
    required this.species,
    required this.sections,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String keywords;
  final PetSpecies species;
  final List<KnowledgeSection> sections;
  final String sourceName;
  final String sourceUrl;
}

const knowledgeArticles = <KnowledgeArticle>[
  KnowledgeArticle(
    id: 'reptile-environment',
    title: '爬宠环境与蜕皮',
    subtitle: '温湿度、UVB 与常见观察',
    category: '爬宠',
    keywords: '爬宠 守宫 环境 蜕皮 温湿度 UVB 晒点',
    species: PetSpecies.gecko,
    sections: [
      KnowledgeSection(
        '观察重点',
        '在饲养箱内设置温度与湿度梯度，让动物自行选择合适区域。记录测量位置、测量时间和蜕皮进度，比只记录一个温度数字更有参考价值。',
      ),
      KnowledgeSection(
        '需要求助',
        '出现持续蜕皮残留、长时间拒食、精神沉郁或呼吸困难时，应尽快联系异宠兽医。应用不会提供自动诊断。',
      ),
    ],
    sourceName: 'Merck Veterinary Manual',
    sourceUrl: 'https://www.merckvetmanual.com/exotic-and-laboratory-animals/reptiles/overview-of-reptiles',
  ),
  KnowledgeArticle(
    id: 'reptile-lighting',
    title: 'UVB 灯与晒点怎么配合',
    subtitle: '灯具类型、距离和每日记录',
    category: '爬宠',
    keywords: '爬宠 UVB 灯 晒点 光照 温度 灯具',
    species: PetSpecies.beardedDragon,
    sections: [
      KnowledgeSection(
        '布局原则',
        'UVB 灯与晒点需要按物种需求配置，灯具类型、安装距离和遮挡物都会影响实际暴露。没有适合所有物种的统一灯具方案，不确定时应咨询异宠兽医。',
      ),
      KnowledgeSection(
        '日常记录',
        '记录灯具启用日期、晒点温度以及动物每天是否主动晒背。灯具老化后外观可能仍正常，但输出会下降。',
      ),
    ],
    sourceName: 'Merck Veterinary Manual · Nutrition in Reptiles',
    sourceUrl: 'https://www.merckvetmanual.com/management-and-nutrition/nutrition-exotic-and-zoo-animals/nutrition-in-reptiles',
  ),
  KnowledgeArticle(
    id: 'snake-feeding',
    title: '蛇类喂食与环境温度',
    subtitle: '拒食时先核对环境条件',
    category: '爬宠',
    keywords: '蛇 球蟒 玉米蛇 喂食 拒食 温度 蜕皮',
    species: PetSpecies.ballPython,
    sections: [
      KnowledgeSection(
        '先检查环境',
        '蛇类的喂食行为和消化与环境温度有关。出现拒食时，先核对物种适宜温度、躲避空间、近期蜕皮和近期喂食记录。',
      ),
      KnowledgeSection(
        '持续拒食',
        '如果拒食持续、伴随体重下降、呼吸困难或异常分泌物，应联系异宠兽医，不要自行加量或频繁强迫喂食。',
      ),
    ],
    sourceName: 'Merck Veterinary Manual',
    sourceUrl: 'https://www.merckvetmanual.com/all-other-pets/reptiles/providing-a-home-for-a-reptile',
  ),
  KnowledgeArticle(
    id: 'fish-water-quality',
    title: '水族换水与水质',
    subtitle: '过滤、溶氧和换水后的行为观察',
    category: '水族',
    keywords: '水族 鱼 斗鱼 换水 水质 过滤 溶氧 氨',
    species: PetSpecies.betta,
    sections: [
      KnowledgeSection('维护重点', '家庭水族箱需要持续管理水质、过滤、废物清除和增氧。换水后同时观察鱼的呼吸、游姿和摄食变化。'),
      KnowledgeSection(
        '高风险信号',
        '低溶氧和高氨是可能直接威胁鱼类的水质问题。出现集体浮头、异常急促呼吸或突然死亡时，应优先检查水质与设备。',
      ),
    ],
    sourceName: 'Merck Veterinary Manual',
    sourceUrl: 'https://www.merckvetmanual.com/all-other-pets/fish/special-considerations-for-fish',
  ),
  KnowledgeArticle(
    id: 'fish-new-tank',
    title: '新缸前六周要谨慎',
    subtitle: '新缸综合症与隔离观察',
    category: '水族',
    keywords: '新缸 综合症 水族 新鱼 隔离 过滤 氨',
    species: PetSpecies.betta,
    sections: [
      KnowledgeSection(
        '新缸风险',
        '新缸综合症通常出现在开始养鱼后的前六周，与水质和生物过滤尚未稳定有关。新鱼入缸后应减少干扰并定期观察。',
      ),
      KnowledgeSection(
        '新增鱼类',
        '新增鱼只建议先隔离观察，避免把潜在问题带入已有水体。出现异常时先检查温度、溶氧、过滤和氨氮。',
      ),
    ],
    sourceName: 'Merck Veterinary Manual · Aquarium Fish',
    sourceUrl: 'https://www.merckvetmanual.com/exotic-and-laboratory-animals/aquarium-fish/management-of-aquarium-fish',
  ),
  KnowledgeArticle(
    id: 'bird-breathing',
    title: '鸟类呼吸变化要早发现',
    subtitle: '张口呼吸、喷嚏与活动量变化',
    category: '鸟类',
    keywords: '鸟 玄凤 鹦鹉 呼吸 张口 喷嚏 羽毛 行为',
    species: PetSpecies.cockatiel,
    sections: [
      KnowledgeSection(
        '观察重点',
        '留意张口呼吸、呼吸频率上升、喘息、咳嗽、喷嚏、羽毛蓬松和活动量下降。先记录持续时间、环境温度和是否刚经历应激。',
      ),
      KnowledgeSection(
        '需要求助',
        '呼吸困难的症状持续或伴随精神沉郁时，应尽快咨询鸟类兽医。鸟类常会隐藏不适，不要等到完全拒食才处理。',
      ),
    ],
    sourceName: 'RSPCA · Caring for Pet Birds in Winter',
    sourceUrl:
        'https://www.rspca.org.uk/adviceandwelfare/seasonal/winter/pets/birds',
  ),
  KnowledgeArticle(
    id: 'bird-housing',
    title: '鸟笼空间与安全',
    subtitle: '翼展、躲避与外部风险',
    category: '鸟类',
    keywords: '鸟 鹦鹉 鸟笼 空间 翼展 安全 环境',
    species: PetSpecies.cockatiel,
    sections: [
      KnowledgeSection(
        '空间判断',
        '群养时，笼体的高度、宽度和深度至少应为最大鸟只翼展的两倍。空间之外，还需要考虑栖木、食物、水源和躲避位置。',
      ),
      KnowledgeSection(
        '安全距离',
        '保持鸟笼与厨房烟雾、化学清洁剂和开放窗户等风险源的距离。外出或散养时，先确认门窗、其他宠物和电线安全。',
      ),
    ],
    sourceName: 'RSPCA · Housing and Environments for Pet Birds',
    sourceUrl:
        'https://www.rspca.org.uk/adviceandwelfare/pets/birds/environment',
  ),
  KnowledgeArticle(
    id: 'cat-water-litter',
    title: '猫咪饮水与猫砂日常',
    subtitle: '清洁、位置和排泄变化',
    category: '猫',
    keywords: '猫 饮水 水碗 猫砂 排便 排尿 行为',
    species: PetSpecies.cat,
    sections: [
      KnowledgeSection(
        '基础维护',
        '每天清洗并补充清水，及时清理猫砂。多猫家庭应分散食物、饮水、猫砂和休息资源，减少竞争与冲突。',
      ),
      KnowledgeSection('需要求助', '猫咪突然不用猫砂盆，或排尿、排便习惯明显改变时，应先考虑健康问题，并咨询兽医。'),
    ],
    sourceName: 'ASPCA · General Cat Care',
    sourceUrl: 'https://www.aspca.org/pet-care/cat-care/general-cat-care',
  ),
  KnowledgeArticle(
    id: 'cat-urinary',
    title: '频繁排尿可能是急症',
    subtitle: '尤其注意排尿困难和公猫风险',
    category: '猫',
    keywords: '猫 排尿 频繁 尿闭 急症 猫砂 泌尿',
    species: PetSpecies.cat,
    sections: [
      KnowledgeSection(
        '危险信号',
        '频繁进出猫砂盆、只排出少量尿液、排尿时叫喊或长时间蹲伏，都可能提示排尿困难。尿路阻塞可迅速危及生命。',
      ),
      KnowledgeSection('立即处理', '如果怀疑无法排尿，应立即联系兽医或急诊机构，不要等待观察一整晚，也不要自行给药。'),
    ],
    sourceName: 'ASPCA · Urinary Blockage in Cats',
    sourceUrl: 'https://www.aspca.org/news/pet-health-alert-urinary-blockage-cats-can-be-life-threatening',
  ),
  KnowledgeArticle(
    id: 'dog-heat',
    title: '狗狗热应激的早期信号',
    subtitle: '高温天气下的观察与处置',
    category: '狗',
    keywords: '狗 高温 热应激 中暑 喘息 流涎 急症',
    species: PetSpecies.dog,
    sections: [
      KnowledgeSection(
        '危险信号',
        '快速呼吸或剧烈喘息、大量流涎、虚弱嗜睡、意识混乱、呕吐腹泻、牙龈颜色异常或干黏，都可能是热应激信号。',
      ),
      KnowledgeSection('立即处理', '出现上述表现应立即联系兽医或急诊机构。不要把冰水直接浇在宠物身上，也不要强行大量灌水。'),
    ],
    sourceName: 'American Veterinary Medical Association',
    sourceUrl:
        'https://avma.org/resources/pet-owners/petcare/warm-weather-pet-safety',
  ),
  KnowledgeArticle(
    id: 'rabbit-hay',
    title: '兔子的主食应该是干草',
    subtitle: '纤维、牙齿与肠道健康',
    category: '兔',
    keywords: '兔 干草 草 饮食 牙齿 肠道 便便',
    species: PetSpecies.rabbit,
    sections: [
      KnowledgeSection(
        '饮食结构',
        '优质、无霉变、香气自然的干草和牧草应始终可用，构成兔子的主要食物。蔬菜和颗粒饲料属于补充，不能替代干草。',
      ),
      KnowledgeSection('需要求助', '如果兔子长时间不进食、排便明显减少，或频繁留下未食用的盲肠便，应咨询兽医。'),
    ],
    sourceName: 'RSPCA · Rabbit Diet',
    sourceUrl: 'https://www.rspca.org.uk/adviceandwelfare/pets/rabbits/diet',
  ),
  KnowledgeArticle(
    id: 'guinea-pig-vitamin-c',
    title: '豚鼠需要稳定的维生素 C',
    subtitle: '干草、维生素与躲避空间',
    category: '豚鼠',
    keywords: '豚鼠 维生素C 干草 饮食 躲避 群养',
    species: PetSpecies.guineaPig,
    sections: [
      KnowledgeSection(
        '饮食重点',
        '豚鼠不能像兔子一样自行合成足够的维生素 C，需要从饮食中稳定获得。优质干草仍应持续供应，并保留安全的躲避空间。',
      ),
      KnowledgeSection(
        '群养注意',
        '如果与兔子同养，应分别满足两种动物的饮食和躲避需求。豚鼠需要能自由进入、但兔子无法进入的安全空间。',
      ),
    ],
    sourceName: 'RSPCA · Guinea Pig Diet and Housing',
    sourceUrl: 'https://www.rspca.org.uk/adviceandwelfare/pets/rodents/guineapigs/diet',
  ),
  KnowledgeArticle(
    id: 'hamster-water',
    title: '每天检查仓鼠饮水',
    subtitle: '水嘴堵塞、笼舍位置与饮水习惯',
    category: '仓鼠',
    keywords: '仓鼠 饮水 水瓶 水嘴 笼舍 躲避 饮食',
    species: PetSpecies.hamster,
    sections: [
      KnowledgeSection(
        '每日检查',
        '保持饮水充足，并每天检查水嘴是否堵塞。观察仓鼠是否正常饮水，饮水明显减少时同时检查设备与身体状态。',
      ),
      KnowledgeSection('笼舍布置', '睡眠区应保持昏暗、安静并远离漏水风险，同时提供合适的垫材、躲避空间和磨牙条件。'),
    ],
    sourceName: 'RSPCA · Hamster Care',
    sourceUrl: 'https://www.rspca.org.uk/adviceandwelfare/pets/rodents/hamsters/environment',
  ),
  KnowledgeArticle(
    id: 'reptile-hygiene',
    title: '接触爬宠后要洗手',
    subtitle: '笼舍清洁与家庭卫生',
    category: '爬宠',
    keywords: '爬宠 洗手 清洁 笼舍 卫生 沙门氏菌',
    species: PetSpecies.gecko,
    sections: [
      KnowledgeSection('清洁习惯', '接触爬宠、笼舍或清理排泄物后，应使用肥皂和流动清水洗手。清洁区域与食物准备区域分开。'),
      KnowledgeSection('减少暴露', '不要让爬宠接触食物准备台面，也不要与爬宠亲吻。儿童、孕妇和免疫力较弱者应减少直接接触。'),
    ],
    sourceName: 'Merck Veterinary Manual · Reptile Hygiene',
    sourceUrl: 'https://www.merckvetmanual.com/all-other-pets/reptiles/special-considerations-for-reptiles',
  ),
  KnowledgeArticle(
    id: 'pet-emergency',
    title: '这些情况不要等待观察',
    subtitle: '呼吸困难、意识异常与明显出血',
    category: '急症',
    keywords: '急症 呼吸困难 抽搐 昏迷 出血 中毒 急诊',
    species: PetSpecies.dog,
    sections: [
      KnowledgeSection(
        '立即联系',
        '呼吸困难、抽搐、失去意识、明显出血、疑似中毒、虚弱崩溃或无法排尿，都属于需要立即联系兽医或急诊机构的情况。',
      ),
      KnowledgeSection('就医途中', '先将宠物安置在安全、限制活动的小空间，提前联系医院说明症状和到达时间。不要自行催吐或喂药。'),
    ],
    sourceName: 'American Veterinary Medical Association',
    sourceUrl: 'https://avma.org/resources/pet-owners/emergencycare/13-animal-emergencies-require-immediate-veterinary-consultation-andor-care',
  ),
];
