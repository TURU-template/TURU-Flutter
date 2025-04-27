import 'package:flutter/material.dart';

class SleepHistoryPage extends StatelessWidget {
  const SleepHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final displayedScores = [80, 70, 90, 65, 85, 75, 95]; // contoh data

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tidur'),
      ),
      body: ListView.builder(
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final day = labels[index];
          final score = displayedScores[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.bedtime, color: Colors.indigo),
              title: Text(day),
              subtitle: Text('Skor: ${score == 0 ? "-" : score}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
