import 'package:flutter/material.dart';
import '../../main.dart';
import '../services/auth.dart';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  _EditPasswordPageState createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _oldPasswordObscured = true;
  bool _newPasswordObscured = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPw = _oldPasswordController.text.trim();
    final newPw = _newPasswordController.text.trim();
    if (oldPw.isEmpty || newPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password lama dan baru harus diisi')),
      );
      return;
    }

    final user = _authService.getCurrentUser();
    try {
      await _authService.editPassword(
        userId: user!['id'],
        oldPassword: oldPw,
        newPassword: newPw,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
        title: const Text('Edit Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Password Lama', style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            _buildPasswordField(_oldPasswordController, _oldPasswordObscured, (val) {
              setState(() => _oldPasswordObscured = !val);
            }),
            const SizedBox(height: 24),
            const Text('Password Baru', style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 8),
            _buildPasswordField(_newPasswordController, _newPasswordObscured, (val) {
              setState(() => _newPasswordObscured = !val);
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _changePassword,
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

  Widget _buildPasswordField(TextEditingController controller, bool obscure, ValueChanged<bool> onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white38),
          onPressed: () => onToggle(!obscure),
        ),
        hintText: 'Masukkan password',
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
    );
  }
}
