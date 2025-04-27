import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SleepReminderService {
  static final SleepReminderService _instance = SleepReminderService._internal();
  
  factory SleepReminderService() {
    return _instance;
  }
  
  SleepReminderService._internal();

  // Set the sleep reminder time
  Future<void> setSleepReminder(int hour, int minute, int second) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save the reminder time
    await prefs.setInt('sleep_reminder_hour', hour);
    await prefs.setInt('sleep_reminder_minute', minute);
    await prefs.setInt('sleep_reminder_second', second);
    
    // Set reminder active status
    await prefs.setBool('sleep_reminder_active', true);
  }
  
  // Cancel the sleep reminder
  Future<void> cancelSleepReminder() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Set reminder inactive
    await prefs.setBool('sleep_reminder_active', false);
  }
  
  // Check if a sleep reminder is set
  Future<bool> isSleepReminderActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sleep_reminder_active') ?? false;
  }
  
  // Get the saved sleep reminder time
  Future<Map<String, int>?> getSleepReminderTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
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
  
  // Get formatted time string (HH:MM:SS)
  Future<String> getFormattedTimeString() async {
    final reminderTime = await getSleepReminderTime();
    
    if (reminderTime != null) {
      final hour = reminderTime['hour']!.toString().padLeft(2, '0');
      final minute = reminderTime['minute']!.toString().padLeft(2, '0');
      final second = reminderTime['second']!.toString().padLeft(2, '0');
      
      return '$hour:$minute:$second';
    }
    
    return '--:--:--';
  }
  
  // Get next reminder time
  Future<DateTime?> getNextReminderTime() async {
    final reminderTime = await getSleepReminderTime();
    final isActive = await isSleepReminderActive();
    
    if (reminderTime != null && isActive) {
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year, 
        now.month, 
        now.day,
        reminderTime['hour']!,
        reminderTime['minute']!,
        reminderTime['second']!,
      );
      
      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      return scheduledTime;
    }
    
    return null;
  }
  
  // Format time to display in a user-friendly way
  String formatTimeRemaining(DateTime targetTime) {
    final now = DateTime.now();
    final difference = targetTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} hari, ${difference.inHours % 24} jam';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam, ${difference.inMinutes % 60} menit';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit, ${difference.inSeconds % 60} detik';
    } else {
      return '${difference.inSeconds} detik';
    }
  }
} 