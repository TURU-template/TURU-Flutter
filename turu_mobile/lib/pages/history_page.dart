import 'package:flutter/material.dart';
import '../../main.dart';

class HistorySleepPage extends StatefulWidget {
  final List<int> scores;

  const HistorySleepPage({super.key, required this.scores});

  @override
  State<HistorySleepPage> createState() => _HistorySleepPageState();
}

class _HistorySleepPageState extends State<HistorySleepPage> {
  late List<int> editableScores;

  @override
  void initState() {
    super.initState();
    editableScores = List<int>.from(widget.scores);
  }

  void _editScore(int index) async {
    final controller = TextEditingController(text: editableScores[index].toString());

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Skor Tidur'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Skor (0-100)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final input = int.tryParse(controller.text);
              if (input != null && input >= 0 && input <= 100) {
                Navigator.pop(context, input);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        editableScores[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Tidur")),
      body: ListView.builder(
        itemCount: editableScores.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${dayNames[index]}"),
            subtitle: Text("Skor: ${editableScores[index]}"),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editScore(index),
            ),
          );
        },
      ),
    );
  }
}
