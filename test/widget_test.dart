import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare_manager/app_theme.dart';
import 'package:petcare_manager/knowledge_content.dart';
import 'package:petcare_manager/main.dart';
import 'package:petcare_manager/models.dart';
import 'package:petcare_manager/notification_service.dart';
import 'package:petcare_manager/screens/auth_screens.dart';
import 'package:petcare_manager/screens/care_management_screens.dart';
import 'package:petcare_manager/screens/create_screens.dart';
import 'package:petcare_manager/screens/stack_screens.dart';
import 'package:petcare_manager/services/app_update_service.dart';
import 'package:petcare_manager/sheets.dart';
import 'package:petcare_manager/widgets/app_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

PetCareApp _testApp() => PetCareApp(state: AppState.inMemory());
void _noop() {}

void main() {
  testWidgets('主导航和内容页可用', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('下一项行动'), findsNothing);
    expect(find.text('今天也要\n照顾好它们'), findsNothing);
    expect(find.byKey(const ValueKey('weather-card')), findsOneWidget);
    expect(find.text('每日知识'), findsOneWidget);
    expect(find.text('接下来要做'), findsOneWidget);
    expect(find.byType(TaskTile), findsNWidgets(5));
    expect(find.text('5 项'), findsNothing);
    expect(find.text('0 项已完成，5 项待处理'), findsNothing);

    await tester.tap(find.text('动物').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('糯米'), findsWidgets);
    expect(find.text('观察图鉴'), findsNothing);
    expect(find.text('最近查看'), findsNothing);
    expect(find.text('3 只'), findsNothing);
    expect(find.byType(ChipRow), findsNothing);
    expect(find.text('♂'), findsNothing);
    expect(find.text('♀'), findsNothing);

    await tester.tap(find.text('任务'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('上午'), findsOneWidget);
    expect(find.text('全部'), findsNothing);
    expect(find.text('待完成'), findsNothing);
    expect(find.text('已完成'), findsNothing);
    expect(find.text('5 项任务 · 0 项完成'), findsNothing);
    expect(find.text('5 项'), findsNothing);
    expect(find.text('已错过'), findsNothing);
    expect(find.text('完成'), findsWidgets);
    expect(find.text('管理每日照护需求'), findsNothing);
    expect(find.text('必做'), findsWidgets);
    expect(find.textContaining('糯米：检查温湿度', findRichText: true), findsOneWidget);
    expect(find.text('环境'), findsNothing);
    await tester.fling(
      find.byKey(const PageStorageKey('tasks-scroll')),
      const Offset(-420, 0),
      1200,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('今日日程'), findsNothing);
    expect(find.text('首页'), findsWidgets);
  });

  testWidgets('首页天气卡可以切换手动城市', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState.inMemory();
    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byKey(const ValueKey('weather-city-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('city-option-北京-北京')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.city, '北京');
  });

  testWidgets('任务页可以一键完成并撤销', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('任务'));
    await tester.pump(const Duration(milliseconds: 400));

    final taskScroll = find.descendant(
      of: find.byKey(const PageStorageKey('tasks-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('一键完成'),
      500,
      scrollable: taskScroll,
    );
    await tester.tap(find.text('一键完成'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('完成 5 项照护？'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    await tester.tap(find.text('确认完成'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('完成'), findsNothing);
    expect(find.text('已完成'), findsWidgets);
    expect(find.text('撤销'), findsOneWidget);

    await tester.tap(find.text('撤销'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('完成'), findsWidgets);
  });

  testWidgets('任务页把已完成任务放在所在时段末尾', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    final completedTask = state.todayTasks.firstWhere(
      (task) => task.petId == 'mochi' && task.title == '检查温湿度',
    );
    final completedPet = state.petById(completedTask.petId);
    state.completeTask(completedTask.id);

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('任务'));
    await tester.pump(const Duration(milliseconds: 500));

    final tasksScroll = find.byKey(const PageStorageKey('tasks-scroll'));
    final pendingTask = find.descendant(
      of: tasksScroll,
      matching: find.textContaining('露露：更换饮水', findRichText: true),
    );
    final completed = find.descendant(
      of: tasksScroll,
      matching: find.textContaining(
        '${completedPet.name}：${completedTask.title}',
        findRichText: true,
      ),
    );
    final afternoonTask = find.descendant(
      of: tasksScroll,
      matching: find.textContaining('小蓝：检查水面与滤材', findRichText: true),
    );
    expect(pendingTask, findsOneWidget);
    expect(completed, findsOneWidget);
    expect(afternoonTask, findsOneWidget);
    expect(
      tester.getTopLeft(completed).dy,
      greaterThan(tester.getTopLeft(pendingTask).dy),
    );
    expect(
      tester.getTopLeft(completed).dy,
      lessThan(tester.getTopLeft(afternoonTask).dy),
    );
  });

  testWidgets('今日首页使用参考设计并保留任务入口', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('按时间'), findsNothing);
    expect(find.text('按房间'), findsNothing);
    expect(find.text('查看全部'), findsNothing);
    expect(find.text('动物'), findsOneWidget);
    expect(find.text('全部任务'), findsNothing);
  });

  testWidgets('首页最多展示五条待完成任务', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    for (var index = 0; index < 3; index++) {
      state.addTask(
        petId: 'mochi',
        title: '额外任务$index',
        time: '1${index + 5}:00',
        type: '环境',
        recurring: false,
      );
    }

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(TaskTile), findsNWidgets(5));
  });

  testWidgets('首页有未完成任务时仍保留已完成任务样式', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    final completed = state.todayTasks.first;
    state.completeTask(completed.id);

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(TaskTile), findsNWidgets(4));
    final completedCard = find.byKey(
      ValueKey('completed-home-task-${completed.id}'),
    );
    final todayScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('today-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      completedCard,
      300,
      scrollable: todayScroll,
    );

    expect(find.text('今天已完成'), findsOneWidget);
    expect(completedCard, findsOneWidget);
    expect(
      find.descendant(
        of: completedCard,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('首页全部完成后显示今日完成和明天第一项', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    for (final task in [...state.todayTasks]) {
      state.completeTask(task.id);
    }

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('今天已完成'), findsOneWidget);
    expect(find.byKey(const ValueKey('tomorrow-first-task')), findsOneWidget);
    expect(find.text('明天第一项'), findsOneWidget);
    expect(find.text('每日知识'), findsOneWidget);

    await tester.tap(find.text('检查温湿度').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('恢复为待完成'), findsOneWidget);
  });

  testWidgets('今日已完成支持展开后最多显示十条', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    for (var index = 0; index < 8; index++) {
      state.addTask(
        petId: 'mochi',
        title: '已完成记录$index',
        time: '1${index % 5}:${(index * 7) % 60}'.padLeft(5, '0'),
        type: '清洁',
        recurring: false,
      );
    }
    for (final task in [...state.todayTasks]) {
      state.completeTask(task.id);
    }

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));
    final todayScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('today-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('completed-list-toggle')),
      350,
      scrollable: todayScroll,
    );
    await tester.tap(find.byKey(const ValueKey('completed-list-toggle')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(10));
    expect(find.text('收起'), findsOneWidget);
  });

  testWidgets('可以从首页任务卡打开详情', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.textContaining('糯米：检查温湿度', findRichText: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('执行说明'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, '完成'), findsOneWidget);
  });

  testWidgets('首页每日知识可以进入知识库', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    final todayScroll = find.descendant(
      of: find.byKey(const PageStorageKey('today-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('每日知识'),
      500,
      scrollable: todayScroll,
    );

    await tester.tap(find.byKey(const ValueKey('daily-knowledge')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('养护知识库'), findsOneWidget);
    expect(find.text('爬宠环境与蜕皮'), findsOneWidget);

    await tester.tap(find.text('爬宠环境与蜕皮'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('观察重点'), findsOneWidget);
    expect(find.textContaining('Merck Veterinary Manual'), findsWidgets);
  });

  testWidgets('添加动物页面显示完整资料字段', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('动物'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('添加动物'), findsOneWidget);
    expect(find.text('提交保存'), findsOneWidget);
    expect(
      find.widgetWithText(FormSection, '1 · 宠物照片（最多 9 张）'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pet-add-photo')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('1 · 宠物照片（最多 9 张）')).dy,
      lessThan(tester.getTopLeft(find.text('2 · 选择物种模板')).dy),
    );
    final addPetScroll = find
        .descendant(
          of: find.byKey(const ValueKey('add-pet-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('4 · 动物昵称'),
      500,
      scrollable: addPetScroll,
    );
    expect(find.widgetWithText(FormSection, '4 · 动物昵称'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '环境名称',
      ),
      findsOneWidget,
    );
  });

  testWidgets('健康记录入口使用完整页面', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('动物'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('糯米').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('健康记录'), findsOneWidget);

    await tester.tap(find.text('健康记录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('记录健康观察'), findsOneWidget);
    expect(find.byType(AppSheetFrame), findsNothing);
  });

  testWidgets('从动物档案新增任务时锁定当前动物', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('动物'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('糯米').first);
    await tester.tap(find.text('糯米').first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('健康记录'), findsOneWidget);
    expect(find.text('新增养护任务'), findsNothing);
    await tester.tap(find.text('养护任务'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TaskTile), findsWidgets);
    expect(find.text('完成'), findsWidgets);
    expect(find.text('新增养护任务'), findsOneWidget);
    await tester.tap(find.text('新增养护任务').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('新增养护任务'), findsWidgets);
    expect(find.text('选择动物'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('糯米'), findsWidgets);
  });

  testWidgets('动物页右下角新增按钮可以进入建档页面', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('动物').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('添加动物'), findsOneWidget);
  });

  testWidgets('每日照护需求无宠物时显示空状态', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory(seed: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DailyNeedsScreen(state: state),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('暂无每日照护需求'), findsOneWidget);
    expect(find.textContaining('请先在“动物”页面添加宠物'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('强制更新保留必须更新提示并使用平台文案', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AppUpdateDialog(
            currentVersion: '1.0.0',
            info: const AppUpdateInfo(
              version: '2.0.0',
              downloadUrl: 'https://example.test/app',
              notes: '重要安全更新',
              force: true,
              platform: AppUpdatePlatform.ios,
            ),
            onLater: null,
            onUpdate: _noop,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('必须更新'), findsOneWidget);
    expect(find.text('iOS 版本必须更新'), findsOneWidget);
    expect(find.text('打开 App Store'), findsOneWidget);
    final updateIcon = tester.widget<Image>(
      find.byKey(const ValueKey('update-app-icon')),
    );
    expect(updateIcon.image, isA<AssetImage>());
    expect(
      (updateIcon.image as AssetImage).assetName,
      'assets/images/app_icon.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: AppUpdateDialog(
            currentVersion: '1.0.0',
            info: const AppUpdateInfo(
              version: '2.0.0',
              downloadUrl: 'https://example.test/app.apk',
              notes: '安卓应用内更新',
              force: false,
              platform: AppUpdatePlatform.android,
              androidMode: AndroidUpdateMode.inApp,
            ),
            onLater: _noop,
            onUpdate: _noop,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('下载并安装'), findsOneWidget);
    expect(find.textContaining('安装结束后 App 会自动重启'), findsOneWidget);
  });

  testWidgets('borrowFlag 非 1 时不执行更新检查', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    final context = tester.element(find.byType(Scaffold));

    final result = await AppUpdateService().checkAndShow(
      context,
      borrowFlag: 0,
    );

    expect(result.status, UpdateCheckStatus.skipped);
    expect(find.byKey(const ValueKey('app-update-dialog')), findsNothing);
  });

  test('状态与任务执行记录可以恢复', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.resetDemo();
    await state.flush();
    final task = state.todayTasks.first;
    state.completeTask(task.id, note: '温度 29°C');
    final added = state.addPet(
      species: PetSpecies.gecko,
      name: '新宠',
      environment: '测试饲养箱',
      roomId: state.rooms.first.id,
      startedAt: DateTime(2025, 5, 1),
      birthday: DateTime(2024, 3, 12),
      gender: '雌性',
      photos: const ['/tmp/pet-1.jpg', '/tmp/pet-2.jpg'],
    )!;
    await state.flush();

    final restored = await AppState.load();
    final restoredTask = restored.todayTasks.firstWhere(
      (item) => item.definitionId == task.definitionId,
    );
    expect(restoredTask.status, TaskStatus.done);
    expect(restoredTask.latestRun?.note, '温度 29°C');
    expect(restored.petById(added.id).startedAt, DateTime(2025, 5, 1));
    expect(restored.petById(added.id).birthday, DateTime(2024, 3, 12));
    expect(restored.petById(added.id).gender, '雌性');
    expect(restored.petById(added.id).photos.length, 2);
  });

  test('知识库包含多物种文章且文章标题不重复', () {
    expect(knowledgeArticles.length, greaterThanOrEqualTo(12));
    expect(
      knowledgeArticles.map((article) => article.title).toSet().length,
      knowledgeArticles.length,
    );
    expect(
      knowledgeArticles.map((article) => article.category).toSet().length,
      greaterThanOrEqualTo(6),
    );
  });

  test('自定义模板、房间和食物库存可以持久化', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.resetDemo();
    await state.flush();
    final template = state.addSpeciesTemplate(
      label: '布偶猫',
      category: '哺乳',
      artStyle: 'cat',
      background: const Color(0xFFF2E8DE),
      backgroundEnd: const Color(0xFFE4D4C3),
      ink: const Color(0xFF72523C),
      note: '长毛猫模板',
    );
    final room = state.addRoom(name: '猫咪房', type: '室内');
    state.updateProfile(nickname: '小王', avatarPath: '/tmp/profile-avatar.jpg');
    state.updateCity('杭州');
    state.upsertFoodSupply(
      petId: 'mochi',
      name: '测试粮',
      unit: 'g',
      remainingAmount: 12,
      mealsPerDay: 2,
      amountPerMeal: 2,
      lowStockDays: 3,
    );
    state.movePetToRoom('mochi', room.id);
    state.updatePetMetrics(
      'mochi',
      temperature: '30.1°C',
      humidity: '61%',
      weight: '63 g',
    );
    state.consumeFoodSupply('food-mochi', 2);
    state.upsertFoodSupply(
      petId: 'mochi',
      name: '测试垫材',
      unit: 'kg',
      remainingAmount: 5,
      mealsPerDay: 1,
      amountPerMeal: 0.5,
      kind: '用品',
      dailyUsage: 0.5,
    );
    await state.flush();

    final restored = await AppState.load();
    expect(
      restored.speciesTemplates.any((item) => item.id == template.id),
      isTrue,
    );
    expect(restored.rooms.any((item) => item.id == room.id), isTrue);
    final food = restored.foodSupplies.firstWhere((item) => item.name == '测试粮');
    expect(food.daysRemaining, 3);
    expect(food.needsRestock, isTrue);
    expect(restored.petById('mochi').roomId, room.id);
    expect(restored.nickname, '小王');
    expect(restored.avatarPath, '/tmp/profile-avatar.jpg');
    expect(restored.city, '浙江 · 杭州');
    expect(
      restored.foodSupplies
          .firstWhere((item) => item.name == '测试垫材')
          .daysRemaining,
      10,
    );
    expect(restored.petById('mochi').temperature, '30.1°C');
    expect(restored.petById('mochi').humidity, '61%');
    expect(restored.petById('mochi').weight, '63 g');
    expect(
      restored.foodSupplies
          .firstWhere((item) => item.id == 'food-mochi')
          .remainingAmount,
      16,
    );
  });

  test('每日需求会自动生成次日任务，一次性任务不会重复', () async {
    final state = AppState.inMemory();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    state.addTask(
      petId: 'mochi',
      title: '每日喂食',
      time: '08:00',
      type: '喂食',
      recurring: true,
    );
    state.addTask(
      petId: 'mochi',
      title: '仅今天清洁',
      time: '12:00',
      type: '清洁',
      recurring: false,
    );
    state.ensureTodayOccurrences(tomorrow);

    expect(
      state.tasks.any(
        (task) =>
            task.title == '每日喂食' &&
            task.date.day == tomorrow.day &&
            task.recurring,
      ),
      isTrue,
    );
    expect(
      state.tasks.any(
        (task) => task.title == '仅今天清洁' && task.date.day == tomorrow.day,
      ),
      isFalse,
    );
  });

  testWidgets('我的页精简并重新分组', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('照护管理'), findsOneWidget);
    expect(find.text('今日任务'), findsNothing);
    expect(find.text('需要关注'), findsNothing);
    expect(find.text('待补库存'), findsNothing);
    expect(find.text('上海市 · 静安区'), findsNothing);
    await tester.tap(find.text('栖护主人'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('动物档案'), findsNothing);

    await tester.drag(
      find.byKey(const PageStorageKey('my-scroll')),
      const Offset(0, -400),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('分享与报告'), findsNothing);
    await tester.drag(
      find.byKey(const PageStorageKey('my-scroll')),
      const Offset(0, -450),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('游客临时备份'), findsNothing);
    expect(find.text('隐私与账号'), findsNothing);
    expect(find.text('生成短时权限链接'), findsNothing);
    expect(find.text('数据收集、设备权限与删除'), findsNothing);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('平台注册协议'), findsOneWidget);

    await tester.tap(find.text('隐私政策'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('协议内容加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('用户信息可以更改市级城市', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('profile-city-field')), findsOneWidget);
    expect(find.textContaining('头像、昵称、城市和养宠标签之后'), findsNothing);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '猫猫教'))
          .showCheckmark,
      isFalse,
    );
    await tester.tap(find.byKey(const ValueKey('profile-city-field')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('city-search-field')),
      '洛阳',
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('city-option-河南-洛阳')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('河南 · 洛阳'), findsOneWidget);
    await tester.tap(find.text('异宠观察员'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('保存修改'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.city, '河南 · 洛阳');
  });

  testWidgets('保存库存记录后列表立即刷新', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('食物与用品'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('food-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
      find.byKey(const ValueKey('food-name-field')),
      '测试新粮',
    );
    await tester.enterText(
      find.byKey(const ValueKey('food-remaining-field')),
      '120',
    );
    await tester.enterText(
      find.byKey(const ValueKey('food-amount-field')),
      '10',
    );
    await tester.tap(find.text('保存食物'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('测试新粮'), findsOneWidget);
    expect(state.foodSupplies.any((food) => food.name == '测试新粮'), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('科学计算工具分别打开对应计算器', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: VolumeCalculatorSheet()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VolumeCalculatorSheet), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: SalinityCalculatorSheet()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SalinityCalculatorSheet), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: EquipmentLifeSheet()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EquipmentLifeSheet), findsOneWidget);
  });

  testWidgets('退出登录会进入本地登录页', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 400));
    final scrollable = find.descendant(
      of: find.byKey(const PageStorageKey('my-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('退出登录'),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('退出登录').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('欢迎来到栖护'), findsOneWidget);
    expect(find.text('游客模式'), findsOneWidget);
  });

  testWidgets('注销账号会清空本地数据', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 400));
    final scrollable = find.descendant(
      of: find.byKey(const PageStorageKey('my-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('注销账号'),
      500,
      scrollable: scrollable,
    );
    await tester.tap(find.text('注销账号'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('确认注销'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('欢迎来到栖护'), findsOneWidget);
    expect(state.pets, isEmpty);
    expect(state.signedIn, isFalse);
  });

  testWidgets('登录后进入资料引导并完成设置', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory()
      ..signOut()
      ..memberOnboardingCompleted = false;

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('密码登录'), findsOneWidget);
    expect(find.text('验证码登录'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('login-consent-checkbox')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('login-privacy-link')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-agreement-link')), findsOneWidget);
    final checkboxCenter = tester.getCenter(
      find.byKey(const ValueKey('login-consent-checkbox')),
    );
    final copyCenter = tester.getCenter(
      find.byKey(const ValueKey('login-consent-copy')),
    );
    expect((checkboxCenter.dy - copyCenter.dy).abs(), lessThan(1));
    final loginButton = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, '登录'),
    );
    expect(loginButton.onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('login-phone-field')),
      '13800138000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('login-consent-checkbox')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('认识一下你'), findsOneWidget);
    expect(find.text('城市'), findsOneWidget);
    expect(find.text('养宠标签'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '小王');
    await tester.tap(find.text('猫猫教'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('首页'), findsWidgets);
    expect(state.isGuest, isFalse);
    expect(state.nickname, '小王');
    expect(state.careTags, contains('猫猫教'));
  });

  testWidgets('已完成资料的会员再次登录直接进入首页', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory()..signOut();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const ValueKey('login-phone-field')),
      '13800138000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('login-consent-checkbox')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('认识一下你'), findsNothing);
    expect(find.text('首页'), findsWidgets);
    expect(state.memberOnboardingCompleted, isTrue);
  });

  testWidgets('登录页协议仅使用后台配置并在缺失时显示错误', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory()..signOut();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('login-privacy-link')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('协议内容加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('login-agreement-link')));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('协议内容加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
  });

  testWidgets('手机号验证码可以登录', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory()
      ..signOut()
      ..memberOnboardingCompleted = false;

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('验证码登录'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('login-phone-field')),
      '13800138000',
    );
    await tester.tap(find.byKey(const ValueKey('login-consent-checkbox')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('send-login-code')));
    await tester.pump(const Duration(milliseconds: 300));

    final message = tester.widget<Text>(find.textContaining('本地演示验证码：')).data!;
    final code = RegExp(r'(\d{6})$').firstMatch(message)!.group(1)!;
    await tester.enterText(
      find.byKey(const ValueKey('login-code-field')),
      code,
    );
    await tester.tap(find.widgetWithText(PrimaryButton, '验证码登录'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('认识一下你'), findsOneWidget);
    expect(state.signedIn, isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('游客模式无需同意协议即可进入', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory(seed: false)..signOut();

    await tester.pumpWidget(PetCareApp(state: state));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('privacy-consent-dialog')), findsNothing);
    final guestButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('游客模式'), matching: find.byType(TextButton)),
    );
    expect(guestButton.onPressed, isNotNull);

    await tester.tap(find.text('游客模式'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(state.isGuest, isTrue);
    expect(state.signedIn, isTrue);
    expect(find.text('首页'), findsWidgets);
    expect(find.byKey(const ValueKey('guest-guide-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-pet-home')), findsOneWidget);
    expect(find.text('今天的照护已完成'), findsNothing);

    await tester.tap(find.text('动物').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('guest-guide-animals')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-pet-animals')), findsOneWidget);

    await tester.tap(find.text('任务'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('guest-guide-tasks')), findsOneWidget);
    expect(find.byKey(const ValueKey('first-pet-tasks')), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('guest-guide-mine')), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pump(const Duration(milliseconds: 300));
    final homeLogin = find.descendant(
      of: find.byKey(const ValueKey('guest-guide-home')),
      matching: find.text('去登录'),
    );
    await tester.ensureVisible(homeLogin);
    await tester.tap(homeLogin);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('登录栖护'), findsOneWidget);
  });

  testWidgets('会员协议升级后需要重新确认', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    var accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MemberConsentScreen(
          state: state,
          onAccepted: () => accepted = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('隐私政策与注册协议已更新'), findsOneWidget);
    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, '同意并继续'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('login-consent-checkbox')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(accepted, isTrue);
  });

  test('游客模式从空空间开始且最多添加 3 只宠物', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load()
      ..enterGuestMode();
    expect(state.isGuest, isTrue);
    expect(state.pets, isEmpty);
    for (var index = 0; index < 3; index++) {
      expect(
        state.addPet(
          species: PetSpecies.gecko,
          name: '游客宠物$index',
          environment: '测试环境',
          roomId: state.rooms.first.id,
        ),
        isNotNull,
      );
    }
    expect(state.canAddPet, isFalse);
    expect(
      state.addPet(
        species: PetSpecies.gecko,
        name: '第四只',
        environment: '测试环境',
        roomId: state.rooms.first.id,
      ),
      isNull,
    );
  });

  test('游客数据到期后自动清空并开启新的三天窗口', () {
    final state = AppState.inMemory(seed: false)..enterGuestMode();
    state.addPet(species: PetSpecies.gecko, name: '临时动物', environment: '测试环境');
    state.guestExpiresAt = DateTime.now().subtract(const Duration(minutes: 1));

    expect(state.refreshGuestDataWindow(), isTrue);
    expect(state.pets, isEmpty);
    expect(state.consumeGuestDataReset(), isTrue);
    expect(state.guestExpiresAt!.isAfter(DateTime.now()), isTrue);
  });

  test('登录会员会清空游客本地数据', () {
    final state = AppState.inMemory(seed: false)..enterGuestMode();
    state.addPet(species: PetSpecies.gecko, name: '游客动物', environment: '测试环境');

    state.startMemberLogin();

    expect(state.isGuest, isFalse);
    expect(state.pets, isEmpty);
    expect(state.taskDefinitions, isEmpty);
    expect(state.tasks, isEmpty);
    expect(state.guestExpiresAt, isNull);
  });

  test('已有云端资料登录后不再进入首次资料引导', () {
    final state = AppState.inMemory(seed: false)
      ..signOut()
      ..memberOnboardingCompleted = false;

    state.startMemberLogin(profileCompleted: true);

    expect(state.memberOnboardingCompleted, isTrue);
    expect(state.needsMemberOnboarding, isFalse);
  });

  test('borrowFlag 严格等于 1 才允许更新检查', () {
    final state = AppState.inMemory();
    expect(state.updateChecksAllowed, isFalse);

    state.updateBorrowFlag(0);
    expect(state.updateChecksAllowed, isFalse);

    state.updateBorrowFlag(1);
    expect(state.updateChecksAllowed, isTrue);
  });

  test('未退出登录重启后仍保留进入首页检查更新的资格', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.signedIn = true;
    state.isGuest = false;
    state.memberOnboardingCompleted = true;
    state.updateBorrowFlag(1);
    await state.flush();

    final restored = await AppState.load();

    expect(restored.signedIn, isTrue);
    expect(restored.isGuest, isFalse);
    expect(restored.memberOnboardingCompleted, isTrue);
    expect(restored.updateChecksAllowed, isTrue);
  });

  test('提醒快照会随健康复看时间变化', () {
    final state = AppState.inMemory();
    final before = PetNotificationService.snapshot(state);
    state.addHealthLog(
      petId: 'mochi',
      tag: '需要复看',
      description: '明天复查状态',
      followUpAt: DateTime.now().add(const Duration(days: 1)),
      riskLevel: 'watch',
    );
    final after = PetNotificationService.snapshot(state);
    expect(after, isNot(before));
    expect(after, contains('需要复看'));
  });

  test('高频修改后持久化保留最后一次状态', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    for (var index = 0; index < 40; index++) {
      state.updateNickname('主人$index');
    }
    await state.flush();

    final restored = await AppState.load();
    expect(restored.nickname, '主人39');
  });

  test('iOS 通知计划限制数量并保留健康提醒', () {
    final state = AppState.inMemory(seed: false);
    for (var index = 0; index < 30; index++) {
      state.addPet(
        species: PetSpecies.gecko,
        name: '测试宠物$index',
        environment: '测试环境',
      );
    }
    state.addHealthLog(
      petId: state.pets.first.id,
      tag: '需要复看',
      description: '观察恢复情况',
      followUpAt: DateTime.now().add(const Duration(days: 2)),
    );

    final reminders = PetNotificationService.buildPlan(state);

    expect(
      reminders.length,
      lessThanOrEqualTo(PetNotificationService.maxIosNotifications),
    );
    expect(
      reminders.map((item) => item.id).toSet(),
      hasLength(reminders.length),
    );
    expect(
      reminders.any((item) => item.kind == PetReminderKind.health),
      isTrue,
    );
    expect(
      reminders.every((item) => item.when.isAfter(DateTime.now())),
      isTrue,
    );
  });

  test('任务统计限定当前宠物和时间范围', () {
    final state = AppState.inMemory();
    final pet = state.pets.first;
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    final expected = state.tasks
        .where(
          (task) =>
              task.petId == pet.id &&
              !task.date.isBefore(start) &&
              task.date.isBefore(
                DateTime(today.year, today.month, today.day + 1),
              ),
        )
        .length;

    expect(state.taskCountForPetSince(pet.id), expected);
    expect(state.taskCountForPetSince('missing-pet'), 0);
  });

  test('不存在的宠物 ID 不再回退为第一只宠物', () {
    final state = AppState.inMemory();
    expect(state.petByIdOrNull('missing-pet'), isNull);
    expect(() => state.petById('missing-pet'), throwsStateError);
  });

  test('任务支持指定星期和固定日期', () {
    final state = AppState.inMemory(seed: false);
    final pet = state.addPet(
      species: PetSpecies.cat,
      name: '测试猫',
      environment: '客厅',
    )!;
    state.addTask(
      petId: pet.id,
      title: '周一和周三称重',
      time: '09:15',
      type: '称重',
      weekdays: const {DateTime.monday, DateTime.wednesday},
    );

    final recurring = state.tasks.where((task) => task.title == '周一和周三称重');
    expect(recurring, isNotEmpty);
    expect(
      recurring.every(
        (task) =>
            task.date.weekday == DateTime.monday ||
            task.date.weekday == DateTime.wednesday,
      ),
      isTrue,
    );

    final fixedDate = DateTime.now().add(const Duration(days: 3));
    state.addTask(
      petId: pet.id,
      title: '固定日期体检',
      time: '14:30',
      type: '健康',
      recurring: false,
      date: fixedDate,
    );
    final fixedTask = state.tasks.singleWhere((task) => task.title == '固定日期体检');
    expect(fixedTask.recurring, isFalse);
    expect(fixedTask.date.day, fixedDate.day);
  });

  testWidgets('动物档案中同一重复任务只显示一张卡片', (tester) async {
    final state = AppState.inMemory(seed: false);
    final pet = state.addPet(
      species: PetSpecies.cat,
      name: '测试猫',
      environment: '客厅',
    )!;
    state.addTask(petId: pet.id, title: '每日称重', time: '09:00', type: '称重');
    expect(
      state.tasks.where((task) => task.title == '每日称重').length,
      greaterThan(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PetDetailScreen(state: state, petId: pet.id),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('养护任务'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('每日称重', findRichText: true), findsOneWidget);
  });

  testWidgets('重新打开体重记录时数值保持为空', (tester) async {
    final state = AppState.inMemory();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordWeightSheet(state: state, pet: state.pets.first),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('从动物档案添加食物计划时锁定当前宠物', (tester) async {
    final state = AppState.inMemory();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddFoodSheet(
            state: state,
            initialPetId: state.pets.first.id,
            lockPet: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('选择宠物'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('执行时间弹窗按内容收缩高度', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState.inMemory();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AddTaskScreen(
          state: state,
          initialPetId: state.pets.first.id,
          lockPet: true,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('task-time-field')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('选择执行时间'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppSheetFrame)).height,
      lessThan(900 * 0.58),
    );
  });

  test('模板删除会保留至少一个并持久化内置模板隐藏状态', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    final builtInId = PetSpecies.cat.id;
    expect(state.deleteSpeciesTemplate(builtInId), isTrue);
    await state.flush();

    final restored = await AppState.load();
    expect(
      restored.speciesTemplates.any((template) => template.id == builtInId),
      isFalse,
    );
  });
}
