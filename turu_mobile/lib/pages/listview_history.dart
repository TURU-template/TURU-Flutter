import 'package:flutter/material.dart';

class SleepHistoryPage extends StatelessWidget {
  const SleepHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sleepData = [
      {
        'emoji': '🦁',
        'tanggal': 'Senin, 19 Mei 2025',
        'skor': 99,
        'mulai': '20:25',
        'selesai': '05:25',
      },
      {
        'emoji': '🦉',
        'tanggal': 'Minggu, 18 Mei 2025',
        'skor': 70,
        'mulai': '01:25',
        'selesai': '11:25',
      },
      {
        'emoji': '🦈',
        'tanggal': 'Kamis, 15 Mei 2025',
        'skor': 30,
        'mulai': '19:25',
        'selesai': '08:25',
      },
      {
        'emoji': '🐨',
        'tanggal': 'Senin, 12 Mei 2025',
        'skor': 25,
        'mulai': '20:25',
        'selesai': '12:55',
      },
      {
        'emoji': '🐨',
        'tanggal': 'Sabtu, 10 Mei 2025',
        'skor': 30,
        'mulai': '19:25',
        'selesai': '09:35',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('Riwayat Tidur'),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: sleepData.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = sleepData[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  item['emoji'] as String,
                  style: const TextStyle(fontSize: 40),
                ),
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
                      Row(
                        children: [
                          Text(
                            'Skor: ${item['skor']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Mulai: ${item['mulai']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Selesai: ${item['selesai']}',
                            style: const TextStyle(color: Colors.white70),
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
