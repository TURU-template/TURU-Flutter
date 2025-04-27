import 'package:flutter/material.dart';
import '../main.dart';
import '../services/sleep_reminder_service.dart';
import 'dart:async';

class SleepReminderPage extends StatefulWidget {
  const SleepReminderPage({super.key});

  @override
  State<SleepReminderPage> createState() => _SleepReminderPageState();
}

class _SleepReminderPageState extends State<SleepReminderPage> {
  final SleepReminderService _reminderService = SleepReminderService();
  
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedSeconds = 0;
  bool _isReminderSet = false;
  String _formattedTime = '';
  String _timeRemaining = '';
  
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _loadSavedReminder();
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    // Update the time remaining every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isReminderSet) {
        final nextReminder = await _reminderService.getNextReminderTime();
        if (nextReminder != null) {
          setState(() {
            _timeRemaining = _reminderService.formatTimeRemaining(nextReminder);
          });
          
          // Check if it's time to show the reminder
          final now = DateTime.now();
          final difference = nextReminder.difference(now);
          if (difference.inSeconds <= 0 && difference.inSeconds > -2) {
            _showReminderDialog();
          }
        }
      }
    });
  }
  
  void _showReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: TuruColors.darkblue,
        title: const Text(
          'Waktunya Tidur!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ayo tidur, istirahat dulu!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: TuruColors.indigo),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadSavedReminder() async {
    final reminderTime = await _reminderService.getSleepReminderTime();
    final isActive = await _reminderService.isSleepReminderActive();
    
    if (reminderTime != null) {
      setState(() {
        _selectedTime = TimeOfDay(hour: reminderTime['hour']!, minute: reminderTime['minute']!);
        _selectedSeconds = reminderTime['second']!;
        _isReminderSet = isActive;
        _formatTime();
      });
      
      // Update time remaining if reminder is active
      if (isActive) {
        final nextReminder = await _reminderService.getNextReminderTime();
        if (nextReminder != null) {
          setState(() {
            _timeRemaining = _reminderService.formatTimeRemaining(nextReminder);
          });
        }
      }
    }
  }
  
  void _formatTime() {
    String hourStr = _selectedTime.hour.toString().padLeft(2, '0');
    String minuteStr = _selectedTime.minute.toString().padLeft(2, '0');
    String secondStr = _selectedSeconds.toString().padLeft(2, '0');
    
    setState(() {
      _formattedTime = '$hourStr:$minuteStr:$secondStr';
    });
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TuruColors.indigo,
              onPrimary: Colors.white,
              surface: TuruColors.darkblue,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: TuruColors.primaryBackground,
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            useMaterial3: true,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          ),
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        _formatTime();
      });
    }
  }
  
  Future<void> _selectSeconds(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: TuruColors.darkblue,
          title: const Text('Set Seconds', style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _selectedSeconds.toDouble(),
                    min: 0,
                    max: 59,
                    divisions: 59,
                    activeColor: TuruColors.indigo,
                    label: _selectedSeconds.toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedSeconds = value.toInt();
                      });
                    },
                  ),
                  Text(
                    '${_selectedSeconds.toString().padLeft(2, '0')} seconds',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _formatTime();
                });
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: TuruColors.indigo),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _setReminder() async {
    // Set the reminder
    await _reminderService.setSleepReminder(
      _selectedTime.hour,
      _selectedTime.minute,
      _selectedSeconds,
    );
    
    setState(() {
      _isReminderSet = true;
    });
    
    // Update time remaining
    final nextReminder = await _reminderService.getNextReminderTime();
    if (nextReminder != null) {
      setState(() {
        _timeRemaining = _reminderService.formatTimeRemaining(nextReminder);
      });
    }
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep reminder set successfully!'),
          backgroundColor: TuruColors.indigo,
        ),
      );
    }
  }
  
  Future<void> _cancelReminder() async {
    await _reminderService.cancelSleepReminder();
    
    setState(() {
      _isReminderSet = false;
      _timeRemaining = '';
    });
    
    // Show cancellation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep reminder cancelled'),
          backgroundColor: TuruColors.pink,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: TuruColors.primaryBackground,
        title: const Text('Ingatkan Tidur'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            // Icon at the top
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TuruColors.indigo.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bedtime_rounded,
                size: 40,
                color: _isReminderSet ? TuruColors.indigo : Colors.white54,
              ),
            ),
            const SizedBox(height: 30),
            
            // Status text
            Text(
              _isReminderSet
                  ? 'Pengingat Tidur Aktif'
                  : 'Pengingat Tidur Tidak Aktif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isReminderSet ? TuruColors.indigo : Colors.white,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Time display
            if (_isReminderSet)
              Column(
                children: [
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Akan tidur dalam $_timeRemaining',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 50),
            
            // Time picker button
            ElevatedButton(
              onPressed: () => _selectTime(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TuruColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Pilih Jam & Menit', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 20),
            
            // Seconds picker button
            ElevatedButton(
              onPressed: () => _selectSeconds(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TuruColors.darkblue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Pilih Detik', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 40),
            
            // Action button (Set or Cancel)
            ElevatedButton(
              onPressed: _isReminderSet ? _cancelReminder : _setReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReminderSet ? TuruColors.pink : TuruColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _isReminderSet ? 'Batalkan Pengingat' : 'Aktifkan Pengingat',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 