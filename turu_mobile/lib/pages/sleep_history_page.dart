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
        backgroundColor: TuruColors.primaryBackground, // Set background to primary background color
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
              borderRadius: BorderRadius.circular(8), // Removed 'const'
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white54),
              borderRadius: BorderRadius.circular(8), // Removed 'const'
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
              backgroundColor: TuruColors.indigo, // Set button color to match theme
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
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
      backgroundColor: TuruColors.primaryBackground, // Set background color to primary
      appBar: AppBar(
        backgroundColor: TuruColors.navbarBackground, // Set navbar background color
        elevation: 0,
        title: const Text(
          'Riwayat Tidur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: editableScores.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${dayNames[index]}", style: const TextStyle(color: Colors.white)),
            subtitle: Text("Skor: ${editableScores[index]}", style: const TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _editScore(index),
            ),
          );
        },
      ),
    );
  }
}
