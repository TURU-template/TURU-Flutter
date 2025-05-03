import 'package:flutter/material.dart'; // Import material for TimeOfDay if needed later
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Attempt to import the specific type if it's not exported by default
// Note: Using internal package paths like 'src' is generally discouraged,
// but let's try it to see if it resolves the Time class issue.
// If this fails, we'll switch to using TimeOfDay.
// import 'package:flutter_local_notifications/src/types.dart';
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
    tz.initializeTimeZones();
    // Set the local location
    // You might need to adjust this based on where your users are,
    // or get the device's timezone. For now, using Jakarta.
    final String timeZoneName = 'Asia/Jakarta';
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Use app icon

    // Request permissions for iOS (if needed, though the focus is Android)
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
        // Handle notification tapped logic here if needed
        print('Notification tapped: ${notificationResponse.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request Android 13+ notification permission
    await _requestAndroidPermissions();
  }

  Future<void> _requestAndroidPermissions() async {
    // Request permission for Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImplementation != null) {
      final bool? granted =
          await androidImplementation.requestNotificationsPermission();
      print('Notification permission granted: $granted');
      // Explicitly request exact alarm permission for reliable scheduling
      final bool? exactAlarmGranted =
          await androidImplementation.requestExactAlarmsPermission();
      print('Exact alarm permission granted: $exactAlarmGranted');
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay scheduledTime, // Use TimeOfDay instead of Time
  }) async {
    final tz.TZDateTime nextInstanceOfTime = _nextInstanceOfTime(scheduledTime);
    print(
      'Attempting to schedule notification for: $nextInstanceOfTime',
    ); // Add logging

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      nextInstanceOfTime, // Use the calculated time
      // Simplify notification details for testing
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_sleep_reminder_channel', // Channel ID
          'Daily Sleep Reminders', // Channel Name
          // channelDescription removed for simplicity
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          // Keep iOS basic settings
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Match only the time for daily repetition
      payload: 'Daily Sleep Reminder Payload',
    );
    // Manually format TimeOfDay for printing (HH:MM)
    final String formattedTime =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    print('Scheduled daily notification for $formattedTime');
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    // Use TimeOfDay
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0, // Seconds set to 0 as TimeOfDay doesn't have seconds
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print('Cancelled notification with id: $id');
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Cancelled all notifications');
  }
}

// Top-level function for background notification tap handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle notification tap when the app is in the background or terminated
  print('Notification tapped in background: ${notificationResponse.payload}');
  // You could potentially navigate to a specific screen here if needed,
  // but it requires more setup (e.g., using a routing package).
}
