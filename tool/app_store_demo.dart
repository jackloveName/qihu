import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:petcare_manager/app_theme.dart';
import 'package:petcare_manager/main.dart';
import 'package:petcare_manager/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState.inMemory();
  final tasks = state.todayTasks;
  if (tasks.isNotEmpty) state.completeTask(tasks.first.id, note: '已完成');
  if (tasks.length > 2) state.completeTask(tasks[2].id, note: '已完成');
  state.updateProfile(
    nickname: '小栖',
    avatarPath: null,
    city: '上海',
    careTags: const ['爬宠', '鸟类', '水族'],
  );
  runApp(_AppStoreDemo(state: state));
}

class _AppStoreDemo extends StatelessWidget {
  const _AppStoreDemo({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '栖护',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AppShell(state: state),
    );
  }
}
