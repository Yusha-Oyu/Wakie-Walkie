
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class AlarmScheduler {
  AlarmScheduler._();
  static final AlarmScheduler I = AlarmScheduler._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Init timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _fln.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: (resp) {},
    );
  }

  /// One-time alarm (default)
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      // Only works if you added the sound file to iOS correctly
      sound: 'alarm_sound.aiff',
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.zonedSchedule(
      id,
      title,
      body,
      when, 
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      
    );
  }

  /// Daily repeating alarm at the same time
  Future<void> scheduleDailyAlarm({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime firstTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for Alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _fln.zonedSchedule(
      id,
      title,
      body,
      firstTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, 
    );
  }

  Future<void> cancel(int id) => _fln.cancel(id);
}