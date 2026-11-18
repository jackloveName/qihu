import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'models.dart';
import 'notification_service.dart';
import 'screens/agreement_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/care_management_screens.dart';
import 'screens/create_screens.dart';
import 'screens/main_screens.dart';
import 'screens/stack_screens.dart';
import 'services/app_update_service.dart';
import 'services/account_data_sync.dart';
import 'services/local_image_store.dart';
import 'services/member_profile_store.dart';
import 'storage/privacy_consent_store.dart';
import 'storage/session_token_store.dart';
import 'sheets.dart';
import 'widgets/app_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PetNotificationService.initialize();
  final state = await AppState.load();
  if (state.consumeGuestDataReset()) {
    await LocalImageStore.deleteAll();
  }
  unawaited(AccountDataSync(state).initialize());
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
      home: AppShell(state: state),
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
  bool _homeUpdateCheckScheduled = false;
  bool _notificationPermissionRequested = false;
  bool _memberConsentChecked = false;
  bool _memberConsentCurrent = true;
  late bool _lastSignedIn = widget.state.signedIn;
  late bool _lastNeedsOnboarding = widget.state.needsMemberOnboarding;
  Timer? _guestExpiryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_handleNavigationState);
    _scheduleGuestExpiry();
    _scheduleHomeUpdateCheck();
    _loadMemberConsent();
    _ensureRemoteProfileMarker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_handleNavigationState);
    _guestExpiryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final expired = widget.state.refreshGuestDataWindow();
      if (expired) unawaited(LocalImageStore.deleteAll());
      _scheduleGuestExpiry();
      widget.state.ensureOccurrencesThrough();
      if (_tab == 0) {
        _homeUpdateCheckScheduled = false;
        _scheduleHomeUpdateCheck();
      }
    } else if (state == AppLifecycleState.paused) {
      unawaited(AccountDataSync.active?.syncNow());
    }
  }

  void _handleNavigationState() {
    final signedInNow = widget.state.signedIn;
    final needsOnboardingNow = widget.state.needsMemberOnboarding;
    final signedInBefore = _lastSignedIn;
    final signedOutNow = _lastSignedIn && !signedInNow;
    final shouldReturnHome =
        (!_lastSignedIn && signedInNow) ||
        (_lastNeedsOnboarding && !needsOnboardingNow && signedInNow);
    _lastSignedIn = signedInNow;
    _lastNeedsOnboarding = needsOnboardingNow;
    _scheduleGuestExpiry();
    if (signedOutNow) _homeUpdateCheckScheduled = false;
    if (shouldReturnHome && mounted && _tab != 0) {
      setState(() => _tab = 0);
    }
    if (!signedInBefore && signedInNow) {
      unawaited(AccountDataSync.active?.handleSignIn());
    }
    if (signedInNow && !needsOnboardingNow && _tab == 0) {
      if (shouldReturnHome) _homeUpdateCheckScheduled = false;
      _scheduleHomeUpdateCheck();
    }
  }

  void _scheduleHomeUpdateCheck() {
    if (_homeUpdateCheckScheduled ||
        _tab != 0 ||
        !widget.state.signedIn ||
        widget.state.needsMemberOnboarding ||
        !_memberConsentChecked ||
        !_memberConsentCurrent ||
        !widget.state.updateChecksAllowed) {
      return;
    }
    _homeUpdateCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tab != 0 || !widget.state.updateChecksAllowed) return;
      AppUpdateService().checkAndShow(
        context,
        borrowFlag: widget.state.borrowFlag,
      );
    });
  }

  void _scheduleGuestExpiry() {
    _guestExpiryTimer?.cancel();
    _guestExpiryTimer = null;
    final expiresAt = widget.state.guestExpiresAt;
    if (!widget.state.isGuest || expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    _guestExpiryTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () async {
        final expired = widget.state.refreshGuestDataWindow();
        if (expired) {
          await LocalImageStore.deleteAll();
          if (mounted) _scheduleGuestExpiry();
        }
      },
    );
  }

  Future<void> _loadMemberConsent() async {
    var current = true;
    if (widget.state.signedIn && !widget.state.isGuest) {
      try {
        current = await PrivacyConsentStore.hasCurrentConsent();
      } on Object {
        current = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _memberConsentCurrent = current;
      _memberConsentChecked = true;
    });
    _scheduleHomeUpdateCheck();
  }

  Future<void> _ensureRemoteProfileMarker() async {
    if (!widget.state.signedIn ||
        widget.state.isGuest ||
        !widget.state.memberOnboardingCompleted) {
      return;
    }
    final token = await SessionTokenStore.read();
    if (token == null || token.isEmpty) return;
    final store = MemberProfileStore();
    try {
      final saved = await store.read(token);
      if (saved?.completed == true) return;
      await store.save(
        token: token,
        nickname: widget.state.nickname,
        city: widget.state.city,
        careTags: widget.state.careTags,
      );
    } on Object {
      // The local profile remains usable when the account sync is unavailable.
    } finally {
      store.close();
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
        if (!_memberConsentChecked) {
          return const Scaffold(
            backgroundColor: AppColors.canvas,
            body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!widget.state.isGuest && !_memberConsentCurrent) {
          return MemberConsentScreen(
            state: widget.state,
            onAccepted: () {
              setState(() => _memberConsentCurrent = true);
              _scheduleHomeUpdateCheck();
            },
          );
        }
        if (widget.state.needsMemberOnboarding) {
          return OnboardingScreen(state: widget.state);
        }
        if (widget.state.notifications && !_notificationPermissionRequested) {
          _notificationPermissionRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final granted = await PetNotificationService.requestPermission();
            if (granted && mounted) {
              await PetNotificationService.syncAll(widget.state, '');
            }
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
                        onAddPet: _openAddPet,
                      ),
                      AnimalsScreen(
                        state: widget.state,
                        onOpenPet: _openPet,
                        onAddPet: _openAddPet,
                      ),
                      TasksScreen(
                        state: widget.state,
                        onOpenTask: _openTask,
                        onAddPet: _openAddPet,
                      ),
                      MineScreen(
                        state: widget.state,
                        onOpenDailyNeeds: _openDailyNeeds,
                        onOpenRooms: _openRooms,
                        onOpenFoodInventory: _openFoodInventory,
                        onOpenTemplates: _openTemplates,
                        onOpenKnowledge: _openKnowledge,
                        onOpenTools: _openTools,
                        onOpenSettings: _openSettings,
                        onOpenAgreements: _openAgreements,
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
    _homeUpdateCheckScheduled = false;
    if (index == 0) _scheduleHomeUpdateCheck();
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
    if (mounted && _tab == 0) {
      _homeUpdateCheckScheduled = false;
      _scheduleHomeUpdateCheck();
    }
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
  void _openTemplates() =>
      _openStack(SpeciesTemplateLibraryScreen(state: widget.state));
  void _openAgreements() => _openStack(const AgreementsScreen());
  void _openKnowledge() => _openStack(const KnowledgeScreen());
  void _openTools() => _openStack(const ToolsScreen());
  void _openSettings() => _openStack(SettingsScreen(state: widget.state));
}
