import 'package:flutter/material.dart';
import '../../main.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor:TuruColors.navbarBackground,
        elevation: 0,
        title: const Text(
          'Detail Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _menuItem(
              icon: Icons.photo_camera,
              label: "Edit Foto Profil",
              onTap: () {
                // Belum ada aksi
              },
            ),
            const Divider(color: Colors.white24),
            _menuItem(
              icon: Icons.edit,
              label: "Edit Nama User",
              onTap: () {
                Navigator.pushNamed(context, '/edit_profil');
              },
            ),
            const Divider(color: Colors.white24),
            _menuItem(
              icon: Icons.lock,
              label: "Ganti Password",
              onTap: () {
                Navigator.pushNamed(context, '/edit_password');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
