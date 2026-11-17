import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'models.dart';
import 'notification_service.dart';
import 'screens/auth_screens.dart';
import 'screens/care_management_screens.dart';
import 'screens/create_screens.dart';
import 'screens/main_screens.dart';
import 'screens/privacy_gate.dart';
import 'screens/stack_screens.dart';
import 'services/app_update_service.dart';
import 'sheets.dart';
import 'widgets/app_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PetNotificationService.initialize();
  final state = await AppState.load();
  CareReminderObserver(state);
  unawaited(PetNotificationService.syncAll(state, ''));
  runApp(PetCareApp(state: state));
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key, required this.state});

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
      builder: (context, child) {
        return _PreviewFrame(child: child ?? const SizedBox.shrink());
      },
      home: PrivacyGate(child: AppShell(state: state)),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF101815),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 620) return child;
          final height = constraints.maxHeight.clamp(640.0, 900.0);
          return Center(
            child: Container(
              width: 430,
              height: height,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(52),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C3733), Color(0xFF0C110F)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 80,
                    offset: Offset(0, 35),
                  ),
                  BoxShadow(
                    color: Color(0x24FFFFFF),
                    blurRadius: 1,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(43),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});

  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _tab = 0;
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.ensureOccurrencesThrough();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        if (!widget.state.signedIn) {
          return LocalLoginScreen(state: widget.state);
        }
        if (!widget.state.onboardingCompleted) {
          return OnboardingScreen(state: widget.state);
        }
        if (!_updateChecked) {
          _updateChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) AppUpdateService().checkAndShow(context);
          });
        }
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: AppBackground(
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.015, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      TodayScreen(
                        state: widget.state,
                        onOpenTask: _openTask,
                        onOpenKnowledge: _openKnowledge,
                      ),
                      AnimalsScreen(
                        state: widget.state,
                        onOpenPet: _openPet,
                        onAddPet: _openAddPet,
                      ),
                      TasksScreen(state: widget.state, onOpenTask: _openTask),
                      MineScreen(
                        state: widget.state,
                        onOpenDailyNeeds: _openDailyNeeds,
                        onOpenRooms: _openRooms,
                        onOpenFoodInventory: _openFoodInventory,
                        onOpenKnowledge: _openKnowledge,
                        onOpenTools: _openTools,
                        onOpenSettings: _openSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: _tab,
            onChanged: _selectTab,
          ),
        );
      },
    );
  }

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
  }

  Future<void> _openPet(String petId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PetDetailScreen(state: widget.state, petId: petId),
      ),
    );
  }

  Future<void> _openStack(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openTask(CareTask task) {
    showAppSheet(
      context: context,
      child: TaskDetailSheet(state: widget.state, task: task),
    );
  }

  Future<void> _openAddPet() async {
    if (!widget.state.canAddPet) {
      showAppMessage(context, '游客模式最多添加 3 只宠物，登录后可继续添加');
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddPetScreen(state: widget.state)),
    );
    if (created == true && mounted) {
      _selectTab(1);
      showAppMessage(context, '档案已创建，并生成了首个养护任务');
    }
  }

  void _openDailyNeeds() => _openStack(DailyNeedsScreen(state: widget.state));
  void _openRooms() => _openStack(RoomsScreen(state: widget.state));
  void _openFoodInventory() =>
      _openStack(FoodInventoryScreen(state: widget.state));
  void _openKnowledge() => _openStack(const KnowledgeScreen());
  void _openTools() => _openStack(const ToolsScreen());
  void _openSettings() => _openStack(SettingsScreen(state: widget.state));
}
