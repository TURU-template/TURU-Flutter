import 'package:flutter/material.dart';
import '../../main.dart';

class ProfileDetailsPage extends StatelessWidget {
  const ProfileDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.darkblue,
      appBar: AppBar(
        backgroundColor: TuruColors.darkblue,
        title: const Text('Detail Profil', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("Edit Profil", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/edit_profil');
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text("Ganti Password", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/edit_password');
              },
            ),
          ],
        ),
      ),
    );
  }
}
