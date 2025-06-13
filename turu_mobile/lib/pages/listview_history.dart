// TURU-Flutter
// Lokasi: lib/pages/listview_history.dart

import 'dart:developer'; // Import 'developer' untuk logging
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turu_mobile/services/auth.dart';
import 'package:turu_mobile/services/sleep_service.dart';

class SleepHistoryPage extends StatefulWidget {
  const SleepHistoryPage({super.key});

  @override
  State<SleepHistoryPage> createState() => _SleepHistoryPageState();
}

class _SleepHistoryPageState extends State<SleepHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sleepData = [];

  final List<Map<String, dynamic>> _dummyData = [
    {
      'emoji': '🦁',
      'tanggal': 'Senin, 19 Mei 2025',
      'skor': 99,
      'mulai': '20:25',
      'selesai': '05:25',
    },
    {
      'emoji': '🐲',
      'tanggal': 'Minggu, 18 Mei 2025',
      'skor': 70,
      'mulai': '01:25',
      'selesai': '11:25',
    },
  ];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _loadSleepHistory();
  }

  Future<void> _loadSleepHistory() async {
    if (!mounted) return;

    List<Map<String, dynamic>> formattedData = [];

    try {
      final authService = AuthService();
      final userData = authService.getCurrentUser();

      if (userData == null || userData['id'] == null) {
        // PERMINTAAN 1: Log saat fallback karena user tidak login
        log('================================================================');
        log('DEBUG: Pengguna tidak login atau ID null. Menampilkan data dummy.');
        log('================================================================');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dynamic userId = userData['id'];
      // PERBAIKAN PENTING: Pastikan userId adalah integer
      if (userId is! int) {
         log('================================================================');
         log('ERROR: Tipe data User ID salah! Diterima: ${userId.runtimeType}, seharusnya int.');
         log('================================================================');
         setState(() { _isLoading = false; });
         return;
      }
      
      // DEBUG: Cetak ID yang akan dikirim ke API
      log('================================================================');
      log('DEBUG: Mencoba mengambil data tidur untuk User ID: $userId');
      log('================================================================');


      final sleepService = SleepService();
      final List<dynamic> fetchedData = await sleepService.getSleepHistory(userId);

      if (mounted) {
        formattedData = fetchedData.map((item) {
          final waktuMulai = DateTime.tryParse(item['waktuMulai'] ?? '');
          final waktuSelesai = DateTime.tryParse(item['waktuSelesai'] ?? '');
          final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
          if (waktuMulai == null || waktuSelesai == null || tanggal == null) {
            return null;
          }
          final formattedTanggal = DateFormat('EEEE, d MMMM yyyy').format(tanggal);
          return {
            'emoji': '🦁',
            'tanggal': formattedTanggal,
            'skor': item['skor'] as int,
            'mulai': DateFormat('HH:mm').format(waktuMulai),
            'selesai': DateFormat('HH:mm').format(waktuSelesai),
          };
        }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
      }
    } catch (error, stackTrace) {
      log('FATAL: Terjadi error saat memuat riwayat tidur:', error: error, stackTrace: stackTrace);
    } finally {
      if (mounted) {
        // PERMINTAAN 1: Log saat fallback karena API tidak mengembalikan data
        if(formattedData.isEmpty) {
            log('================================================================');
            log('DEBUG: Panggilan API berhasil, namun tidak ada data yang cocok. Menampilkan data dummy.');
            log('================================================================');
        }
        setState(() {
          _sleepData = formattedData;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan data mana yang akan ditampilkan.
    final dataToShow = _sleepData.isNotEmpty ? _sleepData : _dummyData;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Tidur'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dataToShow.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = dataToShow[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(item['emoji'],
                          style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
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
                            // Widget ini dibuat lebih aman jika data tidak ada
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text('Skor: ${item['skor'] ?? 'N/A'}'),
                                  const SizedBox(width: 16),
                                  Text('Mulai: ${item['mulai'] ?? 'N/A'}'),
                                  const SizedBox(width: 16),
                                  Text('Selesai: ${item['selesai'] ?? 'N/A'}'),
                                ],
                              ),
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