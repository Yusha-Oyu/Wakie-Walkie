
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmNotifications {
  AlarmNotifications._();
  static final AlarmNotifications instance = AlarmNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String alarmChannelId = 'alarm_channel';
  static const String alarmChannelName = 'Alarms';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        // When user taps the notification, we'll route using payload in main.dart.
        // (We handle it with onGenerateRoute + initialRoute too.)
      },
    );

    // Android 13+: request notification permission
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    // Android 12+: request exact alarm permission (some devices/settings may still block)
    await android?.requestExactAlarmsPermission();

    // Create alarm channel
    const channel = AndroidNotificationChannel(
      alarmChannelId,
      alarmChannelName,
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
    );

    await android?.createNotificationChannel(channel);
  }

  /// Schedules a full-screen alarm notification at [when].
  /// [alarmId] must be unique per alarm.
  Future<void> scheduleAlarm({
    required int alarmId,
    required DateTime when,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        // If you want your own sound later, we can set sound here.
      ),
    );

    await _plugin.zonedSchedule(
      alarmId,
      'Wakie Wakie ',
      'Tap to start steps and stop the alarm',
      tz.TZDateTime.from(when, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'alarm:$alarmId',
    );
  }

  Future<void> cancelAlarm(int alarmId) => _plugin.cancel(alarmId);

  /// Optional: show immediately (good for testing)
  Future<void> fireNow({int alarmId = 999}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        alarmChannelId,
        alarmChannelName,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      ),
    );

    await _plugin.show(
      alarmId,
      'Wakie Wakie ',
      'Tap to start steps and stop the alarm',
      details,
      payload: 'alarm:$alarmId',
    );
  }
}