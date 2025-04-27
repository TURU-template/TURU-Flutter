import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Configure Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configure iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    
    // Initialize settings
    final InitializationSettings initializationSettings = 
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS
        );
    
    // Initialize notification plugin
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // We can handle notification taps here
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Request permission for notifications (Android 13+)
  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final bool? granted = await androidPlugin.requestPermission();
      return granted ?? false;
    }
    
    return true;
  }

  // Schedule a sleep reminder notification
  Future<void> scheduleSleepReminder(int hour, int minute, int second) async {
    // Save the reminder time to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleep_reminder_hour', hour);
    await prefs.setInt('sleep_reminder_minute', minute);
    await prefs.setInt('sleep_reminder_second', second);
    
    // Cancel any previous scheduled notifications
    await cancelSleepReminder();
    
    // Calculate when to schedule the notification
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(now.year, now.month, now.day, hour, minute, second);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    // Create notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sleep_reminder_channel',
      'Sleep Reminders',
      channelDescription: 'Notifications for sleep reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    
    // Schedule the notification
    await notificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Waktunya Tidur!',
      'Ayo tidur, istirahat dulu!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
    );
  }
  
  // Cancel the sleep reminder notification
  Future<void> cancelSleepReminder() async {
    await notificationsPlugin.cancel(0);
  }
  
  // Get the scheduled sleep reminder time
  Future<Map<String, int>?> getSleepReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hour = prefs.getInt('sleep_reminder_hour');
    final minute = prefs.getInt('sleep_reminder_minute');
    final second = prefs.getInt('sleep_reminder_second');
    
    if (hour != null && minute != null && second != null) {
      return {
        'hour': hour,
        'minute': minute,
        'second': second,
      };
    }
    
    return null;
  }
} 