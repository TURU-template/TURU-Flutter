// ignore: avoid_web_libraries_in_flutter
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      print("Web platform detected: Notification service not initialized.");
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      print("Unsupported platform for notifications.");
      return;
    }

    tz.initializeTimeZones();
    final String timeZoneName = 'Asia/Jakarta';
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        print('Notification tapped: \${notificationResponse.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_sleep_reminder_channel',
        'Daily Sleep Reminders',
        description: 'Channel for daily sleep reminder notifications.',
        importance: Importance.max,
      );
      await androidImplementation.createNotificationChannel(channel);
      print("Created notification channel: \${channel.id}");
    }

    await _requestAndroidPermissions();
    await _requestBatteryOptimizationPermission();
  }

  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      print('Notification permission granted: \$granted');
      final bool? exactAlarmGranted =
          await androidImplementation.requestExactAlarmsPermission();
      print('Exact alarm permission granted: \$exactAlarmGranted');
    }
  }

  Future<void> _requestBatteryOptimizationPermission() async {
    PermissionStatus status =
        await Permission.ignoreBatteryOptimizations.status;
    print('Ignore battery optimizations status: \$status');
    if (!status.isGranted) {
      PermissionStatus requestedStatus =
          await Permission.ignoreBatteryOptimizations.request();
      print('Ignore battery optimizations requested status: \$requestedStatus');
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
  }) async {
    final tz.TZDateTime nextInstanceOfTime = _nextInstanceOfTime(scheduledTime);
    print('Attempting to schedule notification for: \$nextInstanceOfTime');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      nextInstanceOfTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_sleep_reminder_channel',
          'Daily Sleep Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'Daily Sleep Reminder Payload',
    );

    String formattedTime =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    print('Scheduled daily notification for \$formattedTime');
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled notification with id: \$id');
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled all notifications');
  }

  Future<void> showImmediateNotification({
    int id = 99,
    String title = "Test Notifikasi",
    String body = "Berhasil!",
    String payload = "Test Payload",
  }) async {
    if (kIsWeb) {
      print("Skipping showImmediateNotification: Not supported on Web.");
      return;
    }

    print('Attempting to show immediate notification...');
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for immediate test notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentBadge: true,
        presentAlert: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    print('Immediate notification shown.');
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification tapped in background: \${notificationResponse.payload}');
}
