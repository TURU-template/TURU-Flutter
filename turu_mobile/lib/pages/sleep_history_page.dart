// lib/pages/sleep_history_page.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turu_mobile/services/auth.dart';
import 'package:turu_mobile/services/sleep_service.dart';
import '../../main.dart'; // Untuk TuruColors

class SleepHistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialRecords;

  const SleepHistoryPage({super.key, this.initialRecords});

  @override
  State<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends State<SleepHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _displaySleepData = [];

  final List<Map<String, dynamic>> _fallbackDummyData = [
    {
      'emoji': '❓',
      'tanggal': 'Tidak Ada Data',
      'skor': 0,
      'mulai': '00:00',
      'selesai': '00:00',
      'durasi': '0j 0m',
      'sortTimestamp': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _loadSleepHistory();
  }

  String _getEmojiFromScore(int score) {
    if (score >= 90) return '🦁';
    if (score >= 70) return '🐻';
    if (score >= 50) return '😴';
    return '🦈';
  }

  String _formatDurationFromBackend(String? backendDuration) {
    if (backendDuration == null || backendDuration.isEmpty) return '0j 0m';
    try {
      if (backendDuration.startsWith('PT')) {
        int totalMinutes = 0;
        String remaining = backendDuration.substring(2);

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
          remaining = remaining.replaceFirst(minutesMatch.group(0)!, '');
        }

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        return "${hours}j ${minutes}m";

      } else {
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
    return "0j 0m";
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
        log('DEBUG: Panggilan API berhasil, namun tidak ada data yang diambil. Menampilkan pesan kosong.');
        return; 
      }
      
      for (var item in fetchedRawData) {
        final String? waktuMulaiStr = item['startTime'] as String?;
        final String? waktuSelesaiStr = item['endTime'] as String?;
        final String? tanggalBackendStr = item['date'] as String?;
        final int skor = (item['score'] as num?)?.toInt() ?? 0;
        final String durasiApiStr = item['duration'] as String? ?? '00:00:00';
        final String? backendEmoji = item['emoji'] as String?;

        String formattedTanggal = 'N/A';
        DateTime? parsedTanggalUntukSorting;
        if (tanggalBackendStr != null) {
          try {
            parsedTanggalUntukSorting = DateTime.tryParse(tanggalBackendStr);
            if (parsedTanggalUntukSorting != null) {
              // PERBAIKAN DI SINI: Gunakan 'yyyy' untuk tahun
              formattedTanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedTanggalUntukSorting);
            }
          } catch (e) {
            log('ERROR: Gagal parsing tanggal "$tanggalBackendStr": $e');
            try {
              parsedTanggalUntukSorting = DateTime.tryParse(tanggalBackendStr + 'T00:00:00');
              if (parsedTanggalUntukSorting != null) {
                  // PERBAIKAN DI SINI: Gunakan 'yyyy' untuk tahun
                  formattedTanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsedTanggalUntukSorting);
              }
            } catch (e2) {
              log('ERROR: Gagal parsing tanggal sebagai Date only "$tanggalBackendStr": $e2');
            }
          }
        }

        String formattedWaktuMulai = 'N/A';
        if (waktuMulaiStr != null) {
          try {
            final parsed = DateTime.tryParse(waktuMulaiStr);
            if (parsed != null) {
              formattedWaktuMulai = DateFormat('HH:mm').format(parsed);
            }
          } catch (e) {
            log('ERROR: Gagal parsing waktu mulai "$waktuMulaiStr": $e');
          }
        }

        String formattedWaktuSelesai = 'N/A';
        DateTime? actualParsedWaktuSelesai;
        if (waktuSelesaiStr != null) {
          try {
            actualParsedWaktuSelesai = DateTime.tryParse(waktuSelesaiStr);
            if (actualParsedWaktuSelesai != null) {
              formattedWaktuSelesai = DateFormat('HH:mm').format(actualParsedWaktuSelesai);
            }
          } catch (e) {
            log('ERROR: Gagal parsing waktu selesai "$waktuSelesaiStr": $e');
          }
        }
        
        String displayEmoji = backendEmoji ?? _getEmojiFromScore(skor);

        processedData.add({
          'emoji': displayEmoji,
          'tanggal': formattedTanggal,
          'skor': skor,
          'mulai': formattedWaktuMulai,
          'selesai': formattedWaktuSelesai,
          'durasi': _formatDurationFromBackend(durasiApiStr),
          'sortTimestamp': actualParsedWaktuSelesai?.millisecondsSinceEpoch ?? 0,
        });
      }

      processedData.sort((a, b) => (b['sortTimestamp'] as int).compareTo(a['sortTimestamp'] as int));

    } catch (error, stackTrace) {
      log('FATAL: Terjadi error saat memuat riwayat tidur:', error: error, stackTrace: stackTrace);
      processedData = _fallbackDummyData;
    } finally {
      if (mounted) {
        setState(() {
          if (processedData.isEmpty && (widget.initialRecords == null || widget.initialRecords!.isEmpty)) {
            _displaySleepData = [];
          } else if (processedData.isEmpty && widget.initialRecords != null && widget.initialRecords!.isNotEmpty) {
            _displaySleepData = widget.initialRecords!;
          } else {
            _displaySleepData = processedData;
          }

          _isLoading = false;
        });
      }
    }
  }

  void _editScore(int index) async {
    final controller = TextEditingController(text: _displaySleepData[index]['skor'].toString());

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TuruColors.primaryBackground,
        title: const Text('Edit Skor Tidur', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Skor (0-100)',
            labelStyle: const TextStyle(color: Colors.white),
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white54),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () {
              final input = int.tryParse(controller.text);
              if (input != null && input >= 0 && input <= 100) {
                Navigator.pop(context, input);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TuruColors.indigo,
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _displaySleepData[index]['skor'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: TuruColors.navbarBackground,
        elevation: 0,
        title: const Text(
          'Riwayat Tidur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                          color: TuruColors.cardBackground, // Menggunakan TuruColors
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(item['emoji'], style: const TextStyle(fontSize: 40)),
                            ),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['tanggal'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
                                      Text(
                                        'Durasi: ${item['durasi']}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      Text(
                                        'Skor: ${item['skor']}',
                                        style: TextStyle(
                                          color: item['skor'] >= 70 ? TuruColors.purple : TuruColors.pink,
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