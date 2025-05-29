import 'package:flutter/material.dart';
import '../../main.dart';
import '../services/auth.dart';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  _EditProfilPageState createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final AuthService _authService = AuthService();
  late TextEditingController _oldNameController;
  final TextEditingController _newNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    _oldNameController = TextEditingController(text: user?['username'] ?? '');
  }

  @override
  void dispose() {
    _oldNameController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final newName = _newNameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama baru tidak boleh kosong')),
      );
      return;
    }

    final user = _authService.getCurrentUser();
    final userId = user!['id'];

    try {
      await _authService.editName(userId: userId, username: newName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: TuruColors.navbarBackground,
        elevation: 0,
        title: const Text('Edit Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Lama', style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _oldNameController,
              readOnly: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Nama lama'),
            ),
            const SizedBox(height: 24),
            const Text('Nama Baru', style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _newNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Masukkan nama baru'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuruColors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
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
      );
}
