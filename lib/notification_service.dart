import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

abstract final class PetNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> syncAll(AppState state, String previousSnapshot) async {
    if (!_ready) return;
    final currentSnapshot = snapshot(state);
    if (currentSnapshot == previousSnapshot) return;
    await _plugin.cancelAll();
    if (!state.notifications) return;
    await _scheduleLowStock(state);
    await _scheduleTasks(state);
    await _scheduleHealthFollowUps(state);
  }

  static Future<void> _scheduleLowStock(AppState state) async {
    final now = tz.TZDateTime.now(tz.local);
    for (final food in state.lowStockFoods) {
      final pet = state.petById(food.petId);
      final days = food.daysRemaining;
      final daysText = days == null
          ? '用量设置需要检查'
          : '预计还可使用 ${days.toStringAsFixed(days < 1 ? 1 : 0)} 天';
      await _schedule(
        id: _notificationId('stock:${food.id}'),
        title: '库存即将用完',
        body: '${pet.name} 的${food.name}$daysText，请及时补充。',
        when: now.add(const Duration(minutes: 5)),
        channelId: 'food_stock',
        channelName: '食物库存提醒',
        channelDescription: '食物即将用完时提醒购买',
      );
    }
  }

  static Future<void> _scheduleTasks(AppState state) async {
    final now = tz.TZDateTime.now(tz.local);
    for (final task in state.tasks) {
      if (task.status != TaskStatus.pending) continue;
      final pieces = task.time.split(':');
      final hour = pieces.isNotEmpty ? int.tryParse(pieces.first) ?? 23 : 23;
      final minute = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 59 : 59;
      final localDateTime = tz.TZDateTime(
        tz.local,
        task.date.year,
        task.date.month,
        task.date.day,
        hour,
        minute,
      );
      if (!localDateTime.isAfter(now)) continue;
      final pet = state.petById(task.petId);
      await _schedule(
        id: _notificationId('task:${task.id}'),
        title: '照护时间到了',
        body: '${pet.name}：${task.title}',
        when: localDateTime,
        channelId: 'care_tasks',
        channelName: '养护任务提醒',
        channelDescription: '在养护任务计划时间发送提醒',
      );
    }
  }

  static Future<void> _scheduleHealthFollowUps(AppState state) async {
    final now = tz.TZDateTime.now(tz.local);
    for (final pet in state.pets) {
      for (var index = 0; index < pet.logs.length; index++) {
        final log = pet.logs[index];
        final followUp = log.followUpAt;
        if (followUp == null) continue;
        final localDateTime = tz.TZDateTime.from(followUp, tz.local);
        if (!localDateTime.isAfter(now)) continue;
        await _schedule(
          id: _notificationId(
            'follow-up:${pet.id}:${log.occurredAt?.toIso8601String()}:$index',
          ),
          title: '健康复看时间到了',
          body: '给 ${pet.name} 做一次健康复看：${log.title}',
          when: localDateTime,
          channelId: 'health_followup',
          channelName: '健康复看提醒',
          channelDescription: '按健康记录中设置的复看时间发送提醒',
        );
      }
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String snapshot(AppState state) {
    final foods =
        state.lowStockFoods
            .map(
              (food) =>
                  '${food.id}:${food.remainingAmount.toStringAsFixed(2)}:'
                  '${food.mealsPerDay}:${food.amountPerMeal}:${food.lowStockDays}',
            )
            .toList()
          ..sort();
    final tasks =
        state.tasks
            .map((task) => '${task.id}:${task.status.name}:${task.time}')
            .toList()
          ..sort();
    final followUps = <String>[];
    for (final pet in state.pets) {
      for (final log in pet.logs) {
        final time = log.followUpAt;
        if (time != null) {
          followUps.add('${pet.id}:${time.toIso8601String()}:${log.title}');
        }
      }
    }
    followUps.sort();
    return '${state.notifications}|'
        '${foods.join(',')}|${tasks.join(',')}|${followUps.join(',')}';
  }

  static int _notificationId(String value) {
    return value.hashCode & 0x7fffffff;
  }
}

class CareReminderObserver {
  CareReminderObserver(this.state) {
    _lastSnapshot = PetNotificationService.snapshot(state);
    state.addListener(_schedule);
  }

  final AppState state;
  late String _lastSnapshot;
  Timer? _debounce;

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final nextSnapshot = PetNotificationService.snapshot(state);
      if (nextSnapshot == _lastSnapshot) return;
      final previous = _lastSnapshot;
      _lastSnapshot = nextSnapshot;
      unawaited(PetNotificationService.syncAll(state, previous));
    });
  }
}
