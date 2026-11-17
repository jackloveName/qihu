import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

enum PetReminderKind { health, stock, task }

class PetReminder {
  const PetReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.kind,
  });

  final int id;
  final String title;
  final String body;
  final DateTime when;
  final PetReminderKind kind;
}

abstract final class PetNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const maxIosNotifications = 60;

  static Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  static Future<void> syncAll(AppState state, String previousSnapshot) async {
    if (!_ready) return;
    final currentSnapshot = snapshot(state);
    if (currentSnapshot == previousSnapshot) return;
    final reminders = state.notifications
        ? buildPlan(state)
        : const <PetReminder>[];
    final desiredIds = reminders.map((item) => item.id).toSet();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!desiredIds.contains(request.id)) {
        await _plugin.cancel(request.id);
      }
    }
    for (final reminder in reminders) {
      await _schedule(reminder);
    }
  }

  @visibleForTesting
  static List<PetReminder> buildPlan(
    AppState state, {
    DateTime? now,
    int maxNotifications = maxIosNotifications,
  }) {
    if (!state.notifications) return const [];
    final current = now ?? DateTime.now();
    final limit = maxNotifications.clamp(1, maxIosNotifications);
    final remindersById = <int, PetReminder>{};

    void addReminder(PetReminder reminder) {
      if (reminder.when.isAfter(current)) {
        remindersById[reminder.id] = reminder;
      }
    }

    for (final food in state.lowStockFoods) {
      final pet = state.petByIdOrNull(food.petId);
      if (pet == null) continue;
      final days = food.daysRemaining;
      final daysText = days == null
          ? '用量设置需要检查'
          : '预计还可使用 ${days.toStringAsFixed(days < 1 ? 1 : 0)} 天';
      addReminder(
        PetReminder(
          id: _notificationId('stock:${food.id}'),
          title: '库存即将用完',
          body: '${pet.name} 的${food.name}$daysText，请及时补充。',
          when: current.add(const Duration(minutes: 5)),
          kind: PetReminderKind.stock,
        ),
      );
    }

    for (final task in state.tasks) {
      if (task.status != TaskStatus.pending) continue;
      final pet = state.petByIdOrNull(task.petId);
      if (pet == null) continue;
      addReminder(
        PetReminder(
          id: _notificationId('task:${task.id}'),
          title: '照护时间到了',
          body: '${pet.name}：${task.title}',
          when: _taskDateTime(task),
          kind: PetReminderKind.task,
        ),
      );
    }

    for (final pet in state.pets) {
      for (var index = 0; index < pet.logs.length; index++) {
        final log = pet.logs[index];
        final followUp = log.followUpAt;
        if (followUp == null) continue;
        addReminder(
          PetReminder(
            id: _notificationId(
              'follow-up:${pet.id}:${log.occurredAt?.toIso8601String()}:$index',
            ),
            title: '健康复看时间到了',
            body: '给 ${pet.name} 做一次健康复看：${log.title}',
            when: followUp,
            kind: PetReminderKind.health,
          ),
        );
      }
    }

    final health =
        remindersById.values
            .where((item) => item.kind == PetReminderKind.health)
            .toList()
          ..sort((a, b) => a.when.compareTo(b.when));
    final stock =
        remindersById.values
            .where((item) => item.kind == PetReminderKind.stock)
            .toList()
          ..sort((a, b) => a.when.compareTo(b.when));
    final tasks =
        remindersById.values
            .where((item) => item.kind == PetReminderKind.task)
            .toList()
          ..sort((a, b) => a.when.compareTo(b.when));

    final selected = <PetReminder>[...health.take(12), ...stock.take(8)];
    final selectedIds = selected.map((item) => item.id).toSet();
    for (final task in tasks) {
      if (selected.length >= limit) break;
      if (selectedIds.add(task.id)) selected.add(task);
    }
    if (selected.length < limit) {
      final remaining =
          remindersById.values
              .where((item) => !selectedIds.contains(item.id))
              .toList()
            ..sort(_compareReminders);
      for (final reminder in remaining) {
        if (selected.length >= limit) break;
        selected.add(reminder);
      }
    }
    selected.sort(_compareReminders);
    return selected.take(limit).toList(growable: false);
  }

  static int _compareReminders(PetReminder a, PetReminder b) {
    final byTime = a.when.compareTo(b.when);
    return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
  }

  static DateTime _taskDateTime(CareTask task) {
    final pieces = task.time.split(':');
    final hour = pieces.isNotEmpty ? int.tryParse(pieces.first) ?? 23 : 23;
    final minute = pieces.length > 1 ? int.tryParse(pieces[1]) ?? 59 : 59;
    return DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      hour,
      minute,
    );
  }

  static Future<void> _schedule(PetReminder reminder) {
    return _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()!
        .zonedSchedule(
          reminder.id,
          reminder.title,
          reminder.body,
          tz.TZDateTime.from(reminder.when, tz.local),
          const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
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
            .where((task) => task.status == TaskStatus.pending)
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
    final pets = state.pets.map((pet) => '${pet.id}:${pet.name}').toList()
      ..sort();
    return '${state.notifications}|'
        '${foods.join(',')}|${tasks.join(',')}|${followUps.join(',')}|'
        '${pets.join(',')}';
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
