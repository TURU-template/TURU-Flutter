import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turu_mobile/services/auth.dart';
import 'package:turu_mobile/services/sleep_service.dart';
import 'package:turu_mobile/main.dart'; // Asumsi TuruColors ada di sini

class SleepHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialRecords;

  const SleepHistoryPage({super.key, this.initialRecords});

  @override
  State<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends State<SleepHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _displaySleepData = [];

  // Dummy data hanya sebagai fallback jika API gagal total dan tidak ada initialRecords
  // Pastikan format ini konsisten dengan format output processedData
  final List<Map<String, dynamic>> _fallbackDummyData = [
    {
      'emoji': '😴',
      'tanggal': 'Senin, 19 Mei 2025', // EAAA, dd MMMMYYYY
      'skor': 85,
      'mulai': '20:00', // HH:mm
      'selesai': '05:30', // HH:mm
      'durasi': '9j 30m', // Xj Ym
      'sortTimestamp': DateTime(2025, 5, 19, 5, 30).millisecondsSinceEpoch,
    },
    {
      'emoji': '😴',
      'tanggal': 'Minggu, 18 Mei 2025',
      'skor': 60,
      'mulai': '01:00',
      'selesai': '09:00',
      'durasi': '8j 0m',
      'sortTimestamp': DateTime(2025, 5, 18, 9, 0).millisecondsSinceEpoch,
    },
  ];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _loadSleepHistory();
  }

  // Helper untuk mendapatkan emoji berdasarkan skor (fallback jika backend tidak mengirimnya)
  String _getEmojiFromScore(int score) {
    if (score >= 90) return '🦁';
    if (score >= 70) return '🐻';
    if (score >= 50) return '😴';
    return '🦈';
  }

  // Fungsi ini menangani format "HH:MM:SS" (dari LocalTime.toString() Java)
  // dan juga format ISO 8601 Duration (misal "PT8H30M").
  String _formatDurationFromBackend(String? backendDuration) {
    if (backendDuration == null || backendDuration.isEmpty) return '0j 0m';
    try {
      // Kasus 1: Format ISO 8601 Duration (contoh: "PT8H30M", "PT1H5M0S")
      if (backendDuration.startsWith('PT')) {
        int totalMinutes = 0;
        String remaining = backendDuration.substring(2); // Hapus "PT"

        // Ekstrak jam
        RegExp hoursRegExp = RegExp(r'(\d+)H');
        Match? hoursMatch = hoursRegExp.firstMatch(remaining);
        if (hoursMatch != null) {
          totalMinutes += (int.tryParse(hoursMatch.group(1)!) ?? 0) * 60;
          remaining = remaining.replaceFirst(hoursMatch.group(0)!, '');
        }

        // Ekstrak menit
        RegExp minutesRegExp = RegExp(r'(\d+)M');
        Match? minutesMatch = minutesRegExp.firstMatch(remaining);
        if (minutesMatch != null) {
          totalMinutes += (int.tryParse(minutesMatch.group(1)!) ?? 0);
          remaining = remaining.replaceFirst(minutesMatch.group(0)!, '');
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        return "${hours}j ${minutes}m";

      } else {
        // Kasus 2: Format HH:MM:SS (contoh: "08:30:00") - Ini yang mungkin dikirim LocalTime.toString()
        final parts = backendDuration.split(':');
        if (parts.length >= 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          return "${hours}j ${minutes}m";
        }
      }
    } catch (e) {
      log("ERROR: Gagal memformat durasi '$backendDuration': $e");
    }
    return "0j 0m"; // Fallback jika tidak ada format yang cocok atau terjadi error
  }

  Future<void> _loadSleepHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> processedData = [];

    try {
      final authService = AuthService();
      final userData = authService.getCurrentUser();

      if (userData == null || userData['id'] == null) {
        log('DEBUG: Pengguna tidak login atau ID null. Menampilkan data dummy.');
        processedData = _fallbackDummyData;
        return;
      }

      final dynamic userId = userData['id'];
      if (userId is! int) {
        log('ERROR: Tipe data User ID salah! Diterima: ${userId.runtimeType}, seharusnya int.');
        processedData = _fallbackDummyData;
        return;
      }
      
      log('DEBUG: Mencoba mengambil data tidur untuk User ID: $userId');

      final sleepService = SleepService();
      final List<dynamic> fetchedRawData = await sleepService.getSleepHistory(userId);

      if (fetchedRawData.isEmpty) {
        log('DEBUG: Panggilan API berhasil, namun tidak ada data yang diambil. Menampilkan data kosong.');
        return;
      }
      
      for (var item in fetchedRawData) {
        // --- Periksa dan Ambil Data dari API ---
        final String? waktuMulaiStr = item['startTime'] as String?;
        final String? waktuSelesaiStr = item['endTime'] as String?;
        final String? tanggalBackendStr = item['date'] as String?;
        final int skor = (item['score'] as num?)?.toInt() ?? 0;
        final String durasiApiStr = item['duration'] as String? ?? '00:00:00';
        final String? backendEmoji = item['emoji'] as String?;

        // --- Proses Tanggal ---
        String formattedTanggal = 'N/A';
        DateTime? parsedTanggalUntukSorting;
        if (tanggalBackendStr != null) {
          try {
            parsedTanggalUntukSorting = DateTime.tryParse(tanggalBackendStr);
            if (parsedTanggalUntukSorting != null) {
              formattedTanggal = DateFormat('EEEE, d MMMM YYYY', 'id_ID').format(parsedTanggalUntukSorting);
            }
          } catch (e) {
            log('ERROR: Gagal parsing tanggal "$tanggalBackendStr": $e');
            try {
              parsedTanggalUntukSorting = DateTime.tryParse(tanggalBackendStr + 'T00:00:00');
              if (parsedTanggalUntukSorting != null) {
                 formattedTanggal = DateFormat('EEEE, d MMMM YYYY', 'id_ID').format(parsedTanggalUntukSorting);
              }
            } catch (e2) {
              log('ERROR: Gagal parsing tanggal sebagai Date only "$tanggalBackendStr": $e2');
            }
          }
        }

        // --- Proses Waktu Mulai ---
        String formattedWaktuMulai = 'N/A';
        DateTime? parsedWaktuMulai;
        if (waktuMulaiStr != null) {
          try {
            parsedWaktuMulai = DateTime.tryParse(waktuMulaiStr);
            if (parsedWaktuMulai != null) {
              formattedWaktuMulai = DateFormat('HH:mm').format(parsedWaktuMulai);
            }
          } catch (e) {
            log('ERROR: Gagal parsing waktu mulai "$waktuMulaiStr": $e');
          }
        }

        // --- Proses Waktu Selesai ---
        String formattedWaktuSelesai = 'N/A';
        DateTime? parsedWaktuSelesai;
        if (waktuSelesaiStr != null) {
          try {
            parsedWaktuSelesai = DateTime.tryParse(waktuSelesaiStr);
            if (parsedWaktuSelesai != null) {
              formattedWaktuSelesai = DateFormat('HH:mm').format(parsedWaktuSelesai);
            }
          } catch (e) {
            log('ERROR: Gagal parsing waktu selesai "$waktuSelesaiStr": $e');
          }
        }
        
        // Tentukan emoji: Prioritaskan dari backend, jika tidak ada, gunakan logika _getEmojiFromScore
        String displayEmoji = backendEmoji ?? _getEmojiFromScore(skor);

        processedData.add({
          'emoji': displayEmoji,
          'tanggal': formattedTanggal,
          'skor': skor,
          'mulai': formattedWaktuMulai,
          'selesai': formattedWaktuSelesai,
          'durasi': _formatDurationFromBackend(durasiApiStr), // Durasi sudah diformat di sini
          'sortTimestamp': parsedWaktuSelesai?.millisecondsSinceEpoch ?? 0,
        });
      }

      // Sortir data dari yang terbaru ke terlama berdasarkan waktu selesai
      processedData.sort((a, b) => (b['sortTimestamp'] as int).compareTo(a['sortTimestamp'] as int));

    } catch (error, stackTrace) {
      log('FATAL: Terjadi error saat memuat riwayat tidur:', error: error, stackTrace: stackTrace);
      processedData = _fallbackDummyData;
    } finally {
      if (mounted) {
        setState(() {
          _displaySleepData = processedData.isNotEmpty
              ? processedData
              : (widget.initialRecords?.isNotEmpty == true
                  ? widget.initialRecords!
                  : _fallbackDummyData);

          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Tidur'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _displaySleepData.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada riwayat tidur.",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _displaySleepData.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = _displaySleepData[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Kolom untuk emoji (Maskot)
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(item['emoji'], style: const TextStyle(fontSize: 40)),
                          ),
                          
                          // Kolom utama untuk detail tidur
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tanggal Lengkap
                                Text(
                                  item['tanggal'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Waktu Mulai, Waktu Selesai, Durasi, dan Skor dalam satu baris
                                Wrap(
                                  spacing: 12.0,
                                  runSpacing: 4.0,
                                  children: [
                                    Text(
                                      'Mulai: ${item['mulai']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    Text(
                                      'Selesai: ${item['selesai']}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    // === BARU: Durasi ditampilkan di sini ===
                                    Text(
                                      'Durasi: ${item['durasi']}', // Mengambil durasi yang sudah diformat
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    Text(
                                      'Skor: ${item['skor']}',
                                      style: TextStyle(
                                        color: item['skor'] >= 70 ? Colors.greenAccent : Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}