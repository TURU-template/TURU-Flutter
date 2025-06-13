import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final String _reminderPrefsKeyHour = 'sleep_reminder_hour';
  final String _reminderPrefsKeyMinute = 'sleep_reminder_minute';
  final int _reminderNotificationId = 0;

  TimeOfDay? _reminderTime;
  Timer? _countdownTimer;
  String _countdownText = '';
  final NotificationService _notificationService = NotificationService();

  Map<String, dynamic>? _loggedInUserData;
  DateTime _lastProfileDataLoadTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReminderTime();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _loggedInUserData = AuthService().getCurrentUser();
      _lastProfileDataLoadTime = DateTime.now();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TuruColors.darkblue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Batalkan"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuruColors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Konfirmasi",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderPrefsKeyHour);
    final minute = prefs.getInt(_reminderPrefsKeyMinute);

    if (hour != null && minute != null) {
      setState(() {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
      _startCountdown();
    }
  }

  Future<void> _saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderPrefsKeyHour, time.hour);
    await prefs.setInt(_reminderPrefsKeyMinute, time.minute);
  }

  Future<void> _clearReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reminderPrefsKeyHour);
    await prefs.remove(_reminderPrefsKeyMinute);
    _countdownTimer?.cancel();
    setState(() {
      _reminderTime = null;
      _countdownText = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pengingat tidur dihapus.")),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: TuruColors.indigo,
                onPrimary: Colors.white,
                onSurface: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: TuruColors.indigo,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveReminderTime(picked);
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Pengingat tidur diatur untuk ${picked.format(context)} setiap hari.",
          ),
        ),
      );
    }
  }

  void _startCountdown() {
    print("Attempting to start countdown...");
    _countdownTimer?.cancel();
    if (_reminderTime == null) {
      print("Countdown not started: _reminderTime is null.");
      return;
    }

    print("Calling initial _updateCountdown()...");
    _updateCountdown();

    print("Starting Timer.periodic...");
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    print("Countdown timer started successfully.");
  }

  void _updateCountdown() {
    if (_reminderTime == null) {
      setState(() {
        _countdownText = '';
      });
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _reminderTime!.hour,
      _reminderTime!.minute,
      0,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final Duration remaining = scheduledDateTime.difference(now);

    if (remaining.inSeconds <= 0 && (_countdownTimer?.isActive ?? false)) {
      print("Countdown finished. Triggering notification...");
      _countdownTimer?.cancel();

      _notificationService.showImmediateNotification(
        id: _reminderNotificationId,
        title: '😴 Waktunya Tidur!',
        body: 'Sudah waktunya untuk istirahat. Selamat tidur!',
        payload: 'Sleep Reminder Triggered',
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          print("Restarting countdown for the next day...");
          _startCountdown();
        }
      });
    } else if (mounted) {
      setState(() {
        _countdownText = _formatDuration(remaining);
      });
    } else {
      print("Countdown update skipped: widget not mounted.");
      _countdownTimer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _performLogout() async {
    await AuthService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = _loggedInUserData?['username'] ?? 'Tamu';
    final String? rawGender = _loggedInUserData?['jk'] ?? '-';
    String gender;
    if (rawGender == 'L') {
      gender = 'Laki-laki';
    } else if (rawGender == 'P') {
      gender = 'Perempuan';
    } else {
      gender = '-';
    }
    final String birthDate = _loggedInUserData?['tanggalLahir'] ?? '-';
    final String? profileImageUrl = _loggedInUserData?['profilePictureUrl'];

    String fullProfileImageUrl = '';
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      fullProfileImageUrl = '${AuthService.getBaseUrl()}$profileImageUrl';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 64),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/profile_details');
              await AuthService().refreshCurrentUser(); // Panggil ini
              _loadUserData();
            },
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              key: ValueKey(fullProfileImageUrl + _lastProfileDataLoadTime.toIso8601String()), // Update Key
              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? NetworkImage(fullProfileImageUrl) as ImageProvider<Object>
                  : const AssetImage('assets/images/LOGO_Turu.png') as ImageProvider<Object>,
              child: (profileImageUrl == null || profileImageUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white38, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$gender | $birthDate',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 72),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Pengaturan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildReminderSection(),
          _settingItem(
            icon: BootstrapIcons.trash,
            label: 'Hapus Rekaman Tidur',
            color: TuruColors.pink,
            onTap: () => _showConfirmationDialog(
              context: context,
              title: "Yakin Hapus Data Tidur?",
              description: "Data rekaman tidurmu akan dihapus secara permanen. Tindakan ini tidak bisa dibatalkan.",
              onConfirm: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data tidur dihapus.")),
                );
              },
            ),
          ),
          _settingItem(
            icon: BootstrapIcons.box_arrow_right,
            label: 'Keluar Akun',
            color: TuruColors.pink,
            onTap: () => _showConfirmationDialog(
              context: context,
              title: "Yakin Log Out Akun?",
              description: "Kamu akan keluar dari akun ini. Pastikan data kamu sudah tersimpan.",
              onConfirm: _performLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    if (_reminderTime == null) {
      return _settingItem(
        icon: BootstrapIcons.clock_history,
        label: 'Setel Pengingat Tidur',
        color: TuruColors.blue,
        onTap: () => _selectTime(context),
      );
    } else {
      final String formattedTime =
          '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
      return ListTile(
        leading: const Icon(BootstrapIcons.clock_fill, color: TuruColors.blue),
        title: Text(
          'Pengingat Tidur: $formattedTime',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Waktu tersisa: $_countdownText',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(BootstrapIcons.trash_fill, color: TuruColors.pink),
          tooltip: 'Hapus Pengingat',
          onPressed: _clearReminderTime,
        ),
        onTap: () => _selectTime(context),
      );
    }
  }

  Widget _settingItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}