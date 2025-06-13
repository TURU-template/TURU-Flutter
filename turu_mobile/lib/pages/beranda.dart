import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:turu_mobile/pages/listview_history.dart';
import '../main.dart'; // Assuming TuruColors is defined here
import '../services/auth.dart';
import 'package:intl/intl.dart'; // Import for date formatting
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
  bool isSleeping = false;
  DateTime? sleepStartTime;
  Timer? sleepTimer;
  Duration sleepDuration = Duration.zero;

  // --- START: Perubahan untuk data pengguna ---
  Map<String, dynamic>? _loggedInUserData;
  // --- END: Perubahan untuk data pengguna ---

  @override
  void initState() {
    super.initState();
    isSleeping = widget.initialSleeping ?? false;
    sleepStartTime = widget.initialStartTime;

    // --- START: Panggil fungsi untuk memuat data pengguna ---
    _loadUserData();
    // --- END: Panggil fungsi untuk memuat data pengguna ---

    if (isSleeping && sleepStartTime != null) {
      _startSleepTimer();
    }
  }

  @override
  void dispose() {
    sleepTimer?.cancel();
    super.dispose();
  }

  // --- START: Fungsi untuk memuat data pengguna ---
  void _loadUserData() {
    setState(() {
      _loggedInUserData = AuthService().getCurrentUser();
    });
    // Opsional: Logging untuk debugging
    if (_loggedInUserData != null) {
      print('Data pengguna dimuat di BerandaPage: ${_loggedInUserData!['username']}');
    } else {
      print('Pengguna belum login atau data tidak tersedia di BerandaPage.');
    }
  }
  // --- END: Fungsi untuk memuat data pengguna ---

  void _startSleepTimer() {
    sleepTimer?.cancel();
    sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (sleepStartTime != null) {
          sleepDuration = DateTime.now().difference(sleepStartTime!);
        }
      });
    });
  }

  void _toggleSleep() {
    setState(() {
      if (isSleeping) {
        // Kalau sedang tidur, tekan -> bangun
        isSleeping = false;
        sleepTimer?.cancel();
        // TODO: PENTING! Kirim data tidur otomatis ke API di sini!
        // Anda mungkin ingin menambahkan logika untuk memanggil _saveSleepDataToApi()
        // dengan sleepStartTime dan DateTime.now() (sebagai waktu bangun)
        // setelah pengguna berhenti tidur.
      } else {
        // Kalau tidak tidur, tekan -> mulai tidur
        isSleeping = true;
        sleepStartTime = DateTime.now();
        sleepDuration = Duration.zero;
        _startSleepTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}j ${minutes}m";
  }

  // ... (Metode _showSleepAnalysisDialog tetap sama untuk sekarang, akan diperbarui nanti) ...
  void _showSleepAnalysisDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
                  const Icon(
                    BootstrapIcons.moon_stars_fill,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rerata Durasi Tidur:",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  // TODO: Ganti dengan data dinamis
                  const Text(
                    "7,5 Jam",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // TODO: Ganti dengan data dinamis dari widget.mascotName, widget.mascotDescription
                  const Text(
                    "Berdasarkan biodata Anda, tidur Anda sudah cukup baik, dapat dilambangkan dengan Singa Prima 🦁",
                    style: TextStyle(color: Colors.white70),
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
                  // TODO: Ganti dengan saran dinamis
                  const Text(
                    "Anda memerlukan tidur 30 menit lebih awal dari tidur kebiasaan Anda, atau bangun lebih akhir 30 menit dari kebiasaan bangun anda.",
                    style: TextStyle(color: Colors.white70),
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

  // --- START: Perubahan untuk Tambah Data Tidur Manual dan API ---
  // Fungsi baru untuk mengirim data tidur ke API
  Future<void> _saveSleepDataToApi({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final authService = AuthService(); // Dapatkan instance AuthService
    final baseUrl = AuthService.getBaseUrl(); // Dapatkan base URL
    final url = Uri.parse('$baseUrl/api/sleep-records/manual'); // Ganti dengan endpoint API Anda

    // Dapatkan ID pengguna dari data yang sudah login
    final userId = authService.getCurrentUser()?['id'];
    if (userId == null) {
      print("Error: User ID not found. Cannot save sleep data.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID pengguna tidak ditemukan.')),
      );
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          // Jika API Anda memerlukan otentikasi (misalnya, token JWT), tambahkan di sini:
          // 'Authorization': 'Bearer ${authService.getAuthToken()}', // Contoh jika ada token
        },
        body: jsonEncode({
          'userId': userId, // Sesuaikan dengan nama field di backend Anda
          'startTime': startTime.toIso8601String(), // Format ISO 8601 adalah yang terbaik
          'endTime': endTime.toIso8601String(),
          // 'duration': endTime.difference(startTime).inMinutes, // Opsional: kirim juga durasi dalam menit
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Sleep data saved successfully: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tidur berhasil disimpan!')),
        );
        // TODO: Refresh data di halaman Beranda atau daftar riwayat jika perlu
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Gagal menyimpan data tidur (${response.statusCode})';
        print('Failed to save sleep data: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data tidur: $errorMessage')),
        );
      }
    } on SocketException {
      print('Network error saving sleep data.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server. Periksa koneksi internet Anda.')),
      );
    } on TimeoutException {
      print('Timeout saving sleep data.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan menyimpan data tidur melebihi batas waktu.')),
      );
    } catch (e) {
      print('Unexpected error saving sleep data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan data tidur: $e')),
      );
    }
  }


  // Metode _showTambahDataTidurDialog yang diperbarui
  Future<void> _showTambahDataTidurDialog() async {
    DateTime? waktuMulai;
    DateTime? waktuBangun;
    final mulaiController = TextEditingController();
    final bangunController = TextEditingController();

    // Import untuk DateFormat jika diperlukan untuk controller.text
    // Pastikan import 'package:intl/intl.dart'; di atas
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
                        initialDate: waktuMulai ?? DateTime.now(), // Gunakan waktuMulai jika sudah ada
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)), // Batasi hingga besok
                        builder: (context, child) { // Kustomisasi tema date picker
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
                          builder: (context, child) { // Kustomisasi tema time picker
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
                        builder: (context, child) { // Kustomisasi tema date picker
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
                          builder: (context, child) { // Kustomisasi tema time picker
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
                // Validasi input
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

                // Panggil fungsi untuk menyimpan data ke API
                _saveSleepDataToApi(
                  startTime: waktuMulai!,
                  endTime: waktuBangun!,
                );

                Navigator.pop(context); // Tutup dialog setelah mencoba menyimpan
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)), // Tambahkan warna
            ),
          ],
        );
      },
    );
  }
  // --- END: Perubahan untuk Tambah Data Tidur Manual dan API ---

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fallbackWeeklyScores = [89, 76, 0, 65, 0, 95, 88];
    final fallbackDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // --- START: Gunakan data pengguna yang sudah dimuat ---
    final String username = _loggedInUserData?['username'] ?? 'Pengguna';
    // Anda bisa gunakan username ini di bagian UI yang relevan, contoh:
    // Text('Selamat datang, $username!');
    // --- END: Gunakan data pengguna yang sudah dimuat ---

    final displayedSleepScore = widget.sleepScore ?? 88;
    final displayedMascot = widget.mascot ?? '😴';
    final displayedMascotName = widget.mascotName ?? 'Koala Pemalas';
    final displayedMascotDesc =
        widget.mascotDescription ?? 'Kamu tidur nyenyak semalam!';
    final displayedScores = widget.weeklyScores ?? fallbackWeeklyScores;
    final labels = widget.dayLabels ?? fallbackDayLabels;
    final todayIndex = now.weekday % 7;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // Tombol Tidur
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _toggleSleep,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(32),
                        backgroundColor: TuruColors.lilac,
                        side: const BorderSide(
                          color: TuruColors.purple,
                          width: 4,
                        ),
                      ),
                      child: Text(
                        isSleeping ? '😴' : '😊',
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Halo, $username!", // Contoh penggunaan data pengguna
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sleepStartTime != null)
                      Text(
                        "Mulai: ${DateFormat('HH:mm').format(sleepStartTime!)}", // Format waktu mulai
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

              // This is the new data section you provided
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sleepStartTime != null
                        ? "Mulai: ${DateFormat('HH:mm').format(sleepStartTime!)}"
                        : "Mulai: 22:10", // TODO: Ganti ini dengan data dari API/fallback yang lebih cerdas
                    style: const TextStyle(color: TuruColors.textColor2),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    "|",
                    style: TextStyle(color: TuruColors.textColor2),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isSleeping
                        ? "Selesai: -"
                        : sleepStartTime != null
                            ? "Selesai: ${DateFormat('HH:mm').format(now)}"
                            : "Selesai: 06:22", // TODO: Ganti ini dengan data dari API/fallback yang lebih cerdas
                    style: const TextStyle(color: TuruColors.textColor2),
                  ),
                ],
              ),

              Text(
                sleepStartTime != null
                    ? _formatDuration(sleepDuration)
                    : "8 j 12 m", // TODO: Ganti ini dengan data dari API/fallback yang lebih cerdas
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 48),

              const _SectionTitle(title: "Skor Tidur"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(displayedMascot, style: const TextStyle(fontSize: 72)),
                  const SizedBox(width: 16),
                  Text(
                    displayedSleepScore.toString(),
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
                "07 Juni 2025 - ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}", // Tanggal dinamis
                style: const TextStyle(color: TuruColors.textColor2),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.6,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            return Column(
                              children: [
                                Text(
                                  labels[index],
                                  style: TextStyle(
                                    color:
                                        index == todayIndex
                                            ? TuruColors.pink
                                            : Colors.grey[400],
                                    fontWeight:
                                        index == todayIndex
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayedScores[index] == 0 ? '0' : displayedScores[index].toString(),
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
                      final isToday = index == todayIndex;
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
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SleepHistoryPage(),
                    ),
                  );
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