import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:turu_mobile/pages/sleep_history_page.dart';
import '../main.dart';
import '../services/auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class BerandaPage extends StatefulWidget {
  final bool? initialSleeping;
  final DateTime? initialStartTime;
  final int? sleepScore;
  final String? mascot;
  final String? mascotName;
  final String? mascotDescription;
  final List<int>? weeklyScores;
  final List<String>? dayLabels;

  const BerandaPage({
    super.key,
    this.initialSleeping,
    this.initialStartTime,
    this.sleepScore,
    this.mascot,
    this.mascotName,
    this.mascotDescription,
    this.weeklyScores,
    this.dayLabels,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final AuthService _authService = AuthService();

  bool isSleeping = false;
  DateTime? sleepStartTime;
  Timer? sleepTimer;
  Duration sleepDuration = Duration.zero;

  Map<String, dynamic>? _loggedInUserData;

  // Variabel untuk data ANALISIS (ditampilkan di dialog)
  int _analysisScore = 0;
  String _analysisMascot = '😴';
  String _analysisMascotName = 'Tertidur.. zZzZ';
  String _analysisMascotDescription = 'Belum ada analisis.';
  String _analysisSuggestion = 'Mulai lacak tidur Anda untuk mendapatkan analisis personal.';
  String _analysisAverageSleepDurationFormatted = '0.0 Jam';

  String? _analysisMessage;
  int? _requiredData;
  int? _currentData;
  String? _averageSleepTimeFormatted;
  String? _averageWakeTimeFormatted;
  String? _sleepTimeVariability;
  String? _wakeTimeVariability;
  bool? _isSleepTimeConsistent;
  bool? _isWakeTimeConsistent;

  // Variabel untuk tampilan BERANDA UTAMA (maskot dan skor dari backend)
  String _mainMascot = '😴';
  String _mainMascotName = 'Tertidur.. zZzZ';
  String _mainMascotDescription = 'Klik tombol untuk memulai sesi tidur.';
  int _mainDisplayScore = 0; // Skor yang akan ditampilkan di beranda utama

  // Data Statistik Tidur Mingguan
  List<int> _displayWeeklyScores = [];
  List<String> _displayDayLabels = [];
  int _displayTodayIndex = 0;
  String _weeklyDateRange = 'Memuat...';

  // Data Tidur Terakhir
  String _lastSleepStartTimeFormatted = '-';
  String _lastSleepEndTimeFormatted = '-';
  String _lastSleepDurationFormatted = '0j 0m';

  bool _isLoading = true;
  bool _isButtonLoading = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG_FLUTTER: BerandaPage initState called.');
    _loadUserDataAndDashboard();
  }

  @override
  void dispose() {
    sleepTimer?.cancel();
    super.dispose();
  }

  void _logResponse(String tag, Uri url, http.Response response) {
    print('DEBUG_FLUTTER: [$tag] URL: $url');
    print('DEBUG_FLUTTER: [$tag] Status: ${response.statusCode}');
    print('DEBUG_FLUTTER: [$tag] Body: ${response.body.substring(0, min(response.body.length, 200))}');
    if (response.statusCode >= 300 && response.statusCode < 400) {
      print('DEBUG_FLUTTER: [$tag] REDIRECT DETECTED! Location: ${response.headers['location']}');
    }
  }
  Future<void> _fetchSleepHistoryAndNavigate(
      BuildContext context, int? userId) async {
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID not found.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true; // Show loading indicator while fetching data
      });
    }

    try {
      final baseUrl = AuthService.getBaseUrl();
      final url = Uri.parse('$baseUrl/api/sleep-records/history/$userId');
      final response = await http
          .get(url, headers: _getApiHeaders())
          .timeout(const Duration(seconds: 10));

      _logResponse('Sleep History API', url, response);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> rawHistoryData = jsonDecode(response.body);
      final List<Map<String, dynamic>> historyData = rawHistoryData
          .map((item) => item as Map<String, dynamic>)
          .toList();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SleepHistoryPage(initialRecords: historyData),
            ),
          );
        }
      } else if (response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada riwayat tidur yang ditemukan.')),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error'] ?? 'Gagal memuat riwayat tidur (${response.statusCode})';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } on SocketException catch (e) {
      print('DEBUG_FLUTTER: Network error fetching sleep history: SocketException - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal terhubung ke server. Periksa koneksi internet Anda.')),
        );
      }
    } on TimeoutException catch (e) {
      print('DEBUG_FLUTTER: Timeout fetching sleep history: TimeoutException - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memuat riwayat tidur melebihi batas waktu.')),
        );
      }
    } catch (e) {
      print('DEBUG_FLUTTER: Unexpected error fetching sleep history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat memuat riwayat tidur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  Future<void> _loadUserDataAndDashboard() async {
    if (!mounted) return;

    print('DEBUG_FLUTTER: Starting _loadUserDataAndDashboard...');

    if (!_isButtonLoading) {
        setState(() {
            _isLoading = true;
        });
    }

    _loggedInUserData = _authService.getCurrentUser();
    print('DEBUG_FLUTTER: Logged-in User Data: $_loggedInUserData');

    if (_loggedInUserData == null || _loggedInUserData?['id'] == null) {
      print('DEBUG_FLUTTER: Pengguna belum login atau data ID tidak tersedia. Mengarahkan ke Login.');
      await _authService.logout();
      if (mounted) {
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
        return;
      }
    }

    await _fetchDashboardData();

    if (mounted && !_isButtonLoading) {
      setState(() {
        _isLoading = false;
      });
    }
    print('DEBUG_FLUTTER: _loadUserDataAndDashboard finished.');
  }

  Map<String, String> _getApiHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Future<void> _fetchDashboardData() async {
    final baseUrl = AuthService.getBaseUrl();
    final userId = _loggedInUserData?['id'];

    if (userId == null) {
      print("DEBUG_FLUTTER: Error: User ID is null. Cannot fetch dashboard data. (Already handled in _loadUserDataAndDashboard).");
      return;
    }

    print('DEBUG_FLUTTER: Starting _fetchDashboardData for userId: $userId');

    try {
      // 1. Ambil Sesi Tidur Saat Ini (untuk status tombol tidur)
      final sessionUrl = Uri.parse('$baseUrl/api/get-session-data-flutter/$userId');
      final sessionResponse = await http.get(sessionUrl, headers: _getApiHeaders()).timeout(const Duration(seconds: 5));
      _logResponse('Session API', sessionUrl, sessionResponse);

      if (sessionResponse.statusCode == 200 && sessionResponse.body.isNotEmpty) {
        final Map<String, dynamic> sessionData = jsonDecode(sessionResponse.body);
        if (mounted) {
          setState(() {
            isSleeping = sessionData['state'] ?? false;
            if (sessionData['startTime'] != null) {
              sleepStartTime = DateTime.parse(sessionData['startTime']);
              _startSleepTimer();
            } else {
              sleepStartTime = null;
              sleepDuration = Duration.zero;
            }
          });
        }
      } else if (sessionResponse.statusCode == 204 || sessionResponse.body.isEmpty) {
        print('DEBUG_FLUTTER: No active sleep session found (204 No Content/Empty Body).');
        if (mounted) {
          setState(() {
            isSleeping = false;
            sleepStartTime = null;
            sleepDuration = Duration.zero;
          });
        }
      } else {
        print('DEBUG_FLUTTER: Failed to get sleep session data: ${sessionResponse.statusCode}.');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat sesi tidur: ${sessionResponse.statusCode}.')));
      }

      // 1.5. Ambil status maskot utama dari backend
      final mainMascotStatusUrl = Uri.parse('$baseUrl/api/main-mascot-status/$userId');
      final mainMascotStatusResponse = await http.get(mainMascotStatusUrl, headers: _getApiHeaders()).timeout(const Duration(seconds: 5));
      _logResponse('Main Mascot API', mainMascotStatusUrl, mainMascotStatusResponse);

      if (mainMascotStatusResponse.statusCode == 200 && mainMascotStatusResponse.body.isNotEmpty) {
        final Map<String, dynamic> mainMascotData = jsonDecode(mainMascotStatusResponse.body);
        if (mounted) {
          setState(() {
            _mainMascot = mainMascotData['mascot'] ?? '😴';
            _mainMascotName = mainMascotData['mascotName'] ?? 'Tertidur.. zZzZ';
            _mainMascotDescription = mainMascotData['mascotDescription'] ?? 'Klik tombol untuk memulai sesi tidur.';
            _mainDisplayScore = (mainMascotData['sleepScore'] as num?)?.toInt() ?? 0;
          });
        }
      } else {
        print('DEBUG_FLUTTER: Failed to get main mascot status: ${mainMascotStatusResponse.statusCode}. Falling back to default.');
        if (mounted) {
          setState(() {
            if (isSleeping) {
              _mainMascot = '😴';
              _mainMascotName = 'Sedang Tidur';
              _mainMascotDescription = 'Jangan ganggu! zZzZ';
            } else {
              _mainMascot = '😊';
              _mainMascotName = 'Bangun!';
              _mainMascotDescription = 'Klik tombol untuk memulai sesi tidur.';
            }
            _mainDisplayScore = 0;
          });
        }
      }

      // 2. Ambil Data Tidur Terakhir (untuk bagian "Data Tidur")
      final latestRecordUrl = Uri.parse('$baseUrl/api/sleep-records/latest/$userId');
      final latestRecordResponse = await http.get(latestRecordUrl, headers: _getApiHeaders()).timeout(const Duration(seconds: 5));
      _logResponse('Latest Record API', latestRecordUrl, latestRecordResponse);

      if (latestRecordResponse.statusCode == 200 && latestRecordResponse.body.isNotEmpty) {
        final Map<String, dynamic> latestData = jsonDecode(latestRecordResponse.body);
        if (mounted) {
          setState(() {
            _lastSleepStartTimeFormatted = latestData['startTime'] != null
                ? DateFormat('HH:mm').format(DateTime.parse(latestData['startTime']))
                : '-';
            _lastSleepEndTimeFormatted = latestData['endTime'] != null
                ? DateFormat('HH:mm').format(DateTime.parse(latestData['endTime']))
                : '-';
            _lastSleepDurationFormatted = latestData['duration'] != null
                ? _formatDurationFromBackend(latestData['duration'])
                : '0j 0m';
          });
        }
      } else {
        print('DEBUG_FLUTTER: Failed to get latest sleep record: ${latestRecordResponse.statusCode}.');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data tidur terakhir: ${latestRecordResponse.statusCode}.')));
      }

      // 3. Ambil Analisis Tidur (untuk "Skor Tidur")
      final analysisUrl = Uri.parse('$baseUrl/api/sleep-analysis/$userId');
      final analysisResponse = await http.get(analysisUrl, headers: _getApiHeaders()).timeout(const Duration(seconds: 5));
      _logResponse('Analysis API', analysisUrl, analysisResponse);

      if (analysisResponse.statusCode == 200 && analysisResponse.body.isNotEmpty) {
        final Map<String, dynamic> analysisData = jsonDecode(analysisResponse.body);
        if (mounted) {
          setState(() {
            _analysisMessage = analysisData['message'];

            if (_analysisMessage != null && _analysisMessage!.contains('Not enough sleep data')) {
              _requiredData = (analysisData['requiredData'] as num?)?.toInt();
              _currentData = (analysisData['currentData'] as num?)?.toInt();
              
              _analysisScore = 0;
              _analysisMascot = '❓';
              _analysisMascotName = 'Tidak Ada Data';
              _analysisMascotDescription = 'Belum ada cukup data tidur untuk analisis.';
              _analysisSuggestion = analysisData['suggestion'] ?? 'Mulai lacak tidur Anda untuk mendapatkan analisis personal.';
              _analysisAverageSleepDurationFormatted = analysisData['averageSleepDurationFormatted'] ?? '0.0 Jam';
              
              _averageSleepTimeFormatted = null;
              _averageWakeTimeFormatted = null;
              _sleepTimeVariability = null;
              _wakeTimeVariability = null;
              _isSleepTimeConsistent = null;
              _isWakeTimeConsistent = null;

            } else {
              _analysisScore = (analysisData['averageSleepScore'] as num?)?.toInt() ?? 0;
              _analysisMascot = analysisData['mascot'] ?? '😴';
              _analysisMascotName = analysisData['mascotName'] ?? 'Tidak Ada Data';
              _analysisMascotDescription = analysisData['mascotDescription'] ?? 'Mulai lacak tidur Anda untuk mendapatkan analisis personal.';
              _analysisSuggestion = analysisData['suggestion'] ?? 'Tidak ada saran spesifik saat ini.';
              _analysisAverageSleepDurationFormatted = analysisData['averageSleepDurationFormatted'] ?? '0.0 Jam';
              
              _averageSleepTimeFormatted = analysisData['averageSleepTime'];
              _averageWakeTimeFormatted = analysisData['averageWakeTime'];
              _sleepTimeVariability = _formatMinutesToDurationString((analysisData['sleepTimeVariabilityMinutes'] as num?)?.toInt() ?? 0);
              _wakeTimeVariability = _formatMinutesToDurationString((analysisData['wakeTimeVariabilityMinutes'] as num?)?.toInt() ?? 0);
              _isSleepTimeConsistent = analysisData['isSleepTimeConsistent'];
              _isWakeTimeConsistent = analysisData['isWakeTimeConsistent'];
            }
          });
        }
      } else {
        print('DEBUG_FLUTTER: Failed to get sleep analysis: ${analysisResponse.statusCode}.');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat analisis tidur: ${analysisResponse.statusCode}.')));
      }

      // 4. Ambil Statistik Tidur Mingguan (untuk "Statistik Tidur Mingguan")
      final statsUrl = Uri.parse('$baseUrl/api/sleep-stats/weekly/$userId');
      final statsResponse = await http.get(statsUrl, headers: _getApiHeaders()).timeout(const Duration(seconds: 5));
      _logResponse('Weekly Stats API', statsUrl, statsResponse);

      if (statsResponse.statusCode == 200 && statsResponse.body.isNotEmpty) {
        final Map<String, dynamic> statsData = jsonDecode(statsResponse.body);
        if (mounted) {
          setState(() {
            _displayWeeklyScores = (statsData['weeklyScores'] as List?)?.cast<int>() ?? List.filled(7, 0);
            _displayDayLabels = (statsData['dayLabels'] as List?)?.cast<String>() ?? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
            _displayTodayIndex = (statsData['todayIndex'] as num?)?.toInt() ?? DateTime.now().weekday % 7;
            _weeklyDateRange = "${statsData['dateRangeStart']} - ${statsData['dateRangeEnd']}";
          });
        }
      } else {
        print('DEBUG_FLUTTER: Failed to get weekly stats: ${statsResponse.statusCode}.');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat statistik mingguan: ${statsResponse.statusCode}.')));
      }

    } on SocketException catch (e) {
      print('DEBUG_FLUTTER: Network error fetching dashboard data: SocketException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server. Periksa koneksi internet Anda.')));
    } on TimeoutException catch (e) {
      print('DEBUG_FLUTTER: Timeout fetching dashboard data: TimeoutException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memuat data dashboard melebihi batas waktu.')));
    } catch (e) {
      print('DEBUG_FLUTTER: Unexpected error fetching dashboard data: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kesalahan saat memuat data dashboard: $e')));
    }
    print('DEBUG_FLUTTER: _fetchDashboardData finished.');
  }

  // Helper untuk memformat durasi dari backend (misalnya "HH:MM:SS" dari LocalTime Java)
  // atau ISO 8601 Duration (misal "PT8H30M").
  String _formatDurationFromBackend(String durationString) {
    try {
      if (durationString.startsWith('PT')) {
        int totalMinutes = 0;
        String remaining = durationString.substring(2);

        RegExp hoursRegExp = RegExp(r'(\d+)H');
        Match? hoursMatch = hoursRegExp.firstMatch(remaining);
        if (hoursMatch != null) {
          totalMinutes += (int.tryParse(hoursMatch.group(1)!) ?? 0) * 60;
          remaining = remaining.replaceFirst(hoursMatch.group(0)!, '');
        }

        RegExp minutesRegExp = RegExp(r'(\d+)M');
        Match? minutesMatch = minutesRegExp.firstMatch(remaining);
        if (minutesMatch != null) {
          totalMinutes += (int.tryParse(minutesMatch.group(1)!) ?? 0);
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        return "${hours}j ${minutes}m";

      } else {
        final parts = durationString.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          return "${hours}j ${minutes}m";
        }
      }
    } catch (e) {
      print("DEBUG_FLUTTER: Error parsing duration string: $e");
    }
    return "0j 0m";
  }
  
  // Helper untuk memformat menit ke string durasi (misal: "30m", "1j 15m")
  String _formatMinutesToDurationString(int totalMinutes) {
    if (totalMinutes < 0) return 'N/A';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}j ${minutes}m';
    } else if (hours > 0) {
      return '${hours}j';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  void _startSleepTimer() {
    sleepTimer?.cancel();
    sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (sleepStartTime != null) {
            sleepDuration = DateTime.now().difference(sleepStartTime!);
          }
        });
      }
    });
  }

  void _toggleSleep() async {
    final baseUrl = AuthService.getBaseUrl();
    final userId = _loggedInUserData?['id'];

    if (userId == null) {
      print("DEBUG_FLUTTER: Error: User ID not available for toggle sleep. Cannot change sleep status.");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda belum login. Gagal mengubah status tidur.')));
      return;
    }

    if (mounted) {
      setState(() {
        _isButtonLoading = true;
      });
    }

    try {
      if (isSleeping) {
        final endTime = DateTime.now();
        final url = Uri.parse('$baseUrl/api/sleep/end');
        final response = await http.post(
          url,
          headers: _getApiHeaders(),
          body: jsonEncode({
            'userId': userId,
            'endTime': endTime.toUtc().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 10));

        _logResponse('End Sleep API', url, response);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final bool isDeleted = responseData['message']?.contains('too short') ?? false;
          if (isDeleted) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidur terlalu singkat dan dihapus.')));
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tidur berhasil disimpan!')));
          }
          if (mounted) {
            setState(() {
              isSleeping = false;
              sleepTimer?.cancel();
              sleepStartTime = null;
              sleepDuration = Duration.zero;
            });
            _fetchDashboardData();
          }
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['error'] ?? 'Gagal mengakhiri sesi tidur (${response.statusCode})';
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } else {
        final startTime = DateTime.now();
        final url = Uri.parse('$baseUrl/api/sleep/start');
        final response = await http.post(
          url,
          headers: _getApiHeaders(),
          body: jsonEncode({
            'userId': userId,
            'startTime': startTime.toUtc().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 10));

        _logResponse('Start Sleep API', url, response);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            setState(() {
              isSleeping = true;
              sleepStartTime = startTime;
              sleepDuration = Duration.zero;
              _startSleepTimer();
            });
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi tidur dimulai!')));
          }
        } else {
          final errorBody = jsonDecode(response.body);
          final errorMessage = errorBody['error'] ?? 'Gagal memulai sesi tidur (${response.statusCode})';
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    } on SocketException catch (e) {
      print('DEBUG_FLUTTER: Network error during toggle sleep: SocketException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server. Periksa koneksi internet Anda.')));
    } on TimeoutException catch (e) {
      print('DEBUG_FLUTTER: Timeout during toggle sleep: TimeoutException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan melebihi batas waktu.')));
    } catch (e) {
      print('DEBUG_FLUTTER: Unexpected error during toggle sleep: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
          _isLoading = false;
        });
      }
    }
  }
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}j ${minutes}m";
  }

  void _showSleepAnalysisDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TuruColors.darkblue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          "Analisis Tidur",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_analysisMessage != null && _analysisMessage!.contains('Not enough sleep data'))
                Column(
                  children: [
                    Text(
                      _analysisMascot,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _analysisMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (_requiredData != null && _currentData != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Anda memiliki $_currentData dari $_requiredData data yang diperlukan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _analysisSuggestion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      _analysisMascot,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Rerata Durasi Tidur:",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _analysisAverageSleepDurationFormatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _analysisMascotDescription,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("Tidur Rata-Rata:", style: TextStyle(color: TuruColors.textColor2)),
                            Text(_averageSleepTimeFormatted ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Bangun Rata-Rata:", style: TextStyle(color: TuruColors.textColor2)),
                            Text(_averageWakeTimeFormatted ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSleepTimeConsistent == true ? 'Tidur: Konsisten' : 'Tidur: Tidak Konsisten (Variasi: ${_sleepTimeVariability ?? '-'})',
                      style: TextStyle(color: _isSleepTimeConsistent == true ? TuruColors.indigo : TuruColors.pink),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _isWakeTimeConsistent == true ? 'Bangun: Konsisten' : 'Bangun: Tidak Konsisten (Variasi: ${_wakeTimeVariability ?? '-'})',
                      style: TextStyle(color: _isWakeTimeConsistent == true ? TuruColors.indigo : TuruColors.pink),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Saran",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analysisSuggestion,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSleepDataToApi({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final baseUrl = AuthService.getBaseUrl();
    final url = Uri.parse('$baseUrl/api/sleep-records/manual');

    final userId = _loggedInUserData?['id'];
    if (userId == null) {
      print("DEBUG_FLUTTER: Error: User ID not found. Cannot save sleep data.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID pengguna tidak ditemukan.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.post(
        url,
        headers: _getApiHeaders(),
        body: jsonEncode({
          'userId': userId,
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      _logResponse('Manual Sleep API', url, response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data tidur berhasil disimpan!')),
          );
        }
        _fetchDashboardData();
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Gagal menyimpan data tidur (${response.statusCode})';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data tidur: $errorMessage'))
        );
      }
    } on SocketException catch (e) {
      print('DEBUG_FLUTTER: Network error saving sleep data: SocketException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server. Periksa koneksi internet Anda.'))
      );
    } on TimeoutException catch (e) {
      print('DEBUG_FLUTTER: Timeout saving sleep data: TimeoutException - $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan menyimpan data tidur melebihi batas waktu.'))
      );
    } catch (e) {
      print('DEBUG_FLUTTER: Unexpected error saving sleep data: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan data tidur: $e'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTambahDataTidurDialog() async {
    DateTime? waktuMulai;
    DateTime? waktuBangun;
    final mulaiController = TextEditingController();
    final bangunController = TextEditingController();

    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2230),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Data Tidur',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: mulaiController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'dd/mm/yyyy --:--',
                      labelText: 'Waktu Mulai Tidur',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: waktuMulai ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) {
                          return Theme(
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
                          );
                        },
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: waktuMulai != null ? TimeOfDay.fromDateTime(waktuMulai!) : TimeOfDay.now(),
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
                        if (pickedTime != null) {
                          final selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          setState(() {
                            waktuMulai = selectedDateTime;
                            mulaiController.text = formatter.format(selectedDateTime);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bangunController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'dd/mm/yyyy --:--',
                      labelText: 'Waktu Bangun',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: waktuBangun ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) {
                          return Theme(
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
                          );
                        },
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: waktuBangun != null ? TimeOfDay.fromDateTime(waktuBangun!) : TimeOfDay.now(),
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
                        if (pickedTime != null) {
                          final selectedDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                          setState(() {
                            waktuBangun = selectedDateTime;
                            bangunController.text = formatter.format(selectedDateTime);
                          });
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Kembali', style: TextStyle(color: TuruColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TuruColors.pink),
              onPressed: () {
                if (waktuMulai == null || waktuBangun == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap lengkapi waktu mulai dan waktu bangun.')),
                  );
                  return;
                }
                if (waktuBangun!.isBefore(waktuMulai!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Waktu bangun tidak boleh sebelum waktu mulai tidur.')),
                  );
                  return;
                }

                _saveSleepDataToApi(
                  startTime: waktuMulai!,
                  endTime: waktuBangun!,
                );

                Navigator.pop(context);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fallbackWeeklyScores = [89, 76, 0, 65, 0, 95, 88];
    final fallbackDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // --- START: Gunakan data pengguna yang sudah dimuat ---
    final String username = _loggedInUserData?['username'] ?? 'Tamu';
    // --- END: Gunakan data pengguna yang sudah dimuat ---

    // MODIFIED: Menggunakan data untuk tampilan utama dari state _main*
    final displayedMascot = _mainMascot;
    final displayedMascotName = _mainMascotName;
    final displayedMascotDesc = _mainMascotDescription;
    
    // Skor di beranda utama selalu dari _analysisScore (hasil analisis dari backend)
    // FIX: Menggunakan _analysisScore yang sudah diperbarui
    final displayedSleepScore = _analysisScore; 

    final displayedScores = _displayWeeklyScores.isNotEmpty ? _displayWeeklyScores : fallbackWeeklyScores; // Gunakan fallback jika API kosong
    final labels = _displayDayLabels.isNotEmpty ? _displayDayLabels : fallbackDayLabels; // Gunakan fallback jika API kosong
    final todayIndex = _displayTodayIndex; // Gunakan dari API

    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/BG_Beranda.svg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: TuruColors.indigo))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Tombol Tidur
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _isButtonLoading ? null : _toggleSleep,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(32),
                              backgroundColor: TuruColors.lilac,
                              side: const BorderSide(
                                color: TuruColors.purple,
                                width: 4,
                              ),
                            ),
                            child: _isButtonLoading
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    isSleeping ? '😴' : '😊',
                                    style: const TextStyle(fontSize: 64),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Halo, $username!",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sleepStartTime != null && isSleeping)
                            Text(
                              "Mulai: ${DateFormat('HH:mm').format(sleepStartTime!)}",
                              style: const TextStyle(color: TuruColors.textColor2),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            isSleeping ? "Sedang Tidur" : "Klik tombol untuk memulai",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    const _SectionTitle(title: "Data Tidur"),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Mulai: $_lastSleepStartTimeFormatted",
                          style: const TextStyle(color: TuruColors.textColor2),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          "|",
                          style: TextStyle(color: TuruColors.textColor2),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Selesai: $_lastSleepEndTimeFormatted",
                          style: const TextStyle(color: TuruColors.textColor2),
                        ),
                      ],
                    ),

                    Text(
                      _lastSleepDurationFormatted,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 48),

                    const _SectionTitle(title: "Skor Tidur"),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(displayedMascot, style: const TextStyle(fontSize: 72)),
                            const SizedBox(width: 16),
                            Text(
                              _mainDisplayScore.toString(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          displayedMascotName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            displayedMascotDesc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: TuruColors.textColor2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _showSleepAnalysisDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuruColors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Analisis Tidur",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 64),

                    const _SectionTitle(title: "Statistik Tidur Mingguan"),
                    const SizedBox(height: 8),
                    Text(
                      _weeklyDateRange,
                      style: const TextStyle(color: TuruColors.textColor2),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: _displayWeeklyScores.isNotEmpty
                          ? BarChart(
                                BarChartData(
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, _) {
                                          final index = value.toInt();
                                          final labelText = index < _displayDayLabels.length ? _displayDayLabels[index] : '';
                                          final scoreText = index < _displayWeeklyScores.length ? _displayWeeklyScores[index].toString() : '0';

                                          return Column(
                                            children: [
                                              Text(
                                                labelText,
                                                style: TextStyle(
                                                  color: index == _displayTodayIndex
                                                      ? TuruColors.pink
                                                      : Colors.grey[400],
                                                  fontWeight: index == _displayTodayIndex
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                scoreText == '0' ? '0' : scoreText,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        reservedSize: 45,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  barGroups: List.generate(displayedScores.length, (index) {
                                    final score = displayedScores[index];
                                    final isToday = index == _displayTodayIndex;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: score == 0 ? 3 : score.toDouble(),
                                          width: 16,
                                          color: isToday ? TuruColors.purple : TuruColors.indigo,
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ],
                                    );
                                  }),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              )
                          : const Center(child: Text("Tidak ada data mingguan.", style: TextStyle(color: Colors.white70))),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        await _fetchSleepHistoryAndNavigate(context, _loggedInUserData?['id']); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuruColors.indigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Lihat Riwayat Tidur",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
        ),

        // Floating Action Button
        Positioned(
          bottom: 80,
          right: 20,
          child: SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton(
              backgroundColor: TuruColors.pink,
              onPressed: () {
                _showTambahDataTidurDialog();
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 28),
                  SizedBox(height: 6),
                  Text(
                    "Tambah",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: TuruColors.pink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}