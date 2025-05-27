import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                Text(item['emoji'], style: const TextStyle(fontSize: 40)),
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
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildEditDialog(context),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditDialog(BuildContext context) {
    final mulaiController = TextEditingController(text: 'dd/mm/yyyy --:--');
    final bangunController = TextEditingController(text: 'dd/mm/yyyy --:--');

    return Dialog(
      backgroundColor: const Color(0xFF0D1840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Data Tidur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDateTimeInput(
                context,
                mulaiController,
                'Waktu Mulai Tidur',
              ),
              const SizedBox(height: 20),
              _buildDateTimeInput(context, bangunController, 'Waktu Bangun'),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeInput(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder:
              (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.pinkAccent,
                    surface: Color(0xFF1F2A52),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF1F2A52),
                ),
                child: child!,
              ),
        );

        if (date == null) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder:
              (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  timePickerTheme: const TimePickerThemeData(
                    backgroundColor: Color(0xFF1F2A52),
                    hourMinuteTextColor: Colors.white,
                    dialHandColor: Colors.pinkAccent,
                  ),
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.pinkAccent,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              ),
        );

        if (time == null) return;

        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        controller.text = DateFormat('dd/MM/yyyy – kk:mm').format(dateTime);
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
