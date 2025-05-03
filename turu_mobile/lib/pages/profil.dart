import 'dart:async'; // Import async for Timer
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import '../../main.dart'; // Keep for TuruColors
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart'; // Import NotificationService
import 'package:timezone/timezone.dart'
    as tz; // Import timezone for calculations

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  File? _profileImage;
  final String _reminderPrefsKeyHour = 'sleep_reminder_hour';
  final String _reminderPrefsKeyMinute = 'sleep_reminder_minute';
  final int _reminderNotificationId =
      0; // Unique ID for the reminder notification

  TimeOfDay? _reminderTime;
  Timer? _countdownTimer;
  String _countdownText = '';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadReminderTime(); // Load reminder time on init
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_path');
    if (path != null) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

  // Fungsi untuk ambil gambar, sudah minta izin kamera
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin kamera ditolak')));
          return;
        }
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', pickedFile.path);
    }
  }

  void _showPickImageDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Reminder Functions ---

  Future<void> _loadReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderPrefsKeyHour);
    final minute = prefs.getInt(_reminderPrefsKeyMinute);

    if (hour != null && minute != null) {
      setState(() {
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
      _startCountdown(); // Start countdown if time is loaded
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
    await _notificationService.cancelNotification(_reminderNotificationId);
    _countdownTimer?.cancel();
    setState(() {
      _reminderTime = null;
      _countdownText = '';
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Pengingat tidur dihapus.")));
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      // Ensure 24-hour format for the picker
      initialEntryMode: TimePickerEntryMode.input, // Often helps enforce format
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            // Keep existing theme customization
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: TuruColors.indigo, // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Colors.white, // body text color
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: TuruColors.indigo, // button text color
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
      await _notificationService.scheduleDailyNotification(
        id: _reminderNotificationId,
        title: '😴 Waktunya Tidur!',
        body: 'Sudah waktunya untuk istirahat. Selamat tidur!',
        scheduledTime: picked,
      );
      _startCountdown(); // Restart countdown with new time
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
    print("Attempting to start countdown..."); // Log start
    _countdownTimer?.cancel(); // Cancel any existing timer
    if (_reminderTime == null) {
      print("Countdown not started: _reminderTime is null."); // Log reason
      return;
    }

    print("Calling initial _updateCountdown()..."); // Log initial update
    _updateCountdown(); // Initial update

    print("Starting Timer.periodic..."); // Log timer start
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // print("Timer tick - calling _updateCountdown()"); // Log tick (can be verbose)
      _updateCountdown();
    });
    print("Countdown timer started successfully."); // Log success
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
      0, // Seconds set to 0
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    final Duration remaining = scheduledDateTime.difference(now);

    // print("Updating countdown text for duration: $remaining"); // Log update attempt
    if (mounted) {
      // Check if the widget is still in the tree
      setState(() {
        _countdownText = _formatDuration(remaining);
        // print("setState called. New _countdownText: $_countdownText"); // Log setState
      });
    } else {
      print("Countdown update skipped: widget not mounted."); // Log skip
      _countdownTimer?.cancel(); // Stop timer if widget is disposed
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // --- End Reminder Functions ---

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 64),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/profile_details');
            },
            child:
                _profileImage != null
                    ? CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(_profileImage!),
                    )
                    : const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(
                        'assets/images/LOGO_Turu.png',
                      ),
                    ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                Text(
                  'Nama Pengguna',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Laki-laki | 2002-03-01',
                  style: TextStyle(color: Colors.white70),
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
          // --- Sleep Reminder Section ---
          _buildReminderSection(), // Add the reminder UI
          const Divider(color: Colors.white24, height: 1), // Optional separator
          // --- End Sleep Reminder Section ---
          _settingItem(
            icon: BootstrapIcons.trash,
            label: 'Hapus Rekaman Tidur',
            color: TuruColors.pink,
            onTap:
                () => _showConfirmationDialog(
                  context: context,
                  title: "Yakin Hapus Data Tidur?",
                  description:
                      "Data rekaman tidurmu akan dihapus secara permanen. Tindakan ini tidak bisa dibatalkan.",
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
            onTap:
                () => _showConfirmationDialog(
                  context: context,
                  title: "Yakin Log Out Akun?",
                  description:
                      "Kamu akan keluar dari akun ini. Pastikan data kamu sudah tersimpan.",
                  onConfirm: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
          ),
        ],
      ),
    );
  }

  // Builds the UI section for the sleep reminder
  Widget _buildReminderSection() {
    if (_reminderTime == null) {
      // Show button to set reminder
      return _settingItem(
        icon: BootstrapIcons.clock_history, // Or BootstrapIcons.alarm
        label: 'Setel Pengingat Tidur',
        color: TuruColors.blue, // Use a distinct color
        onTap: () => _selectTime(context),
      );
    } else {
      // Show reminder details and delete button
      // Manually format time for display to ensure 24-hour format
      final String formattedTime =
          '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
      return ListTile(
        leading: const Icon(BootstrapIcons.clock_fill, color: TuruColors.blue),
        title: Text(
          'Pengingat Tidur: $formattedTime', // Use manually formatted time
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
        onTap: () => _selectTime(context), // Allow tapping to change time
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
