import 'package:flutter/material.dart';
import '../../main.dart';
import '../services/auth.dart'; // Tambahkan import AuthService

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  // String? _imagePath; // Hapus ini, kita akan ambil dari AuthService
  String? _profileImageUrl; // Gunakan ini untuk URL gambar profil

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = AuthService().getCurrentUser();
    setState(() {
      _profileImageUrl = user?['profilePictureUrl'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: TuruColors.navbarBackground,
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
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white24,
                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage('${AuthService.getBaseUrl()}$_profileImageUrl') as ImageProvider<Object>
                    : const AssetImage('assets/images/LOGO_Turu.png') as ImageProvider<Object>,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white38, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            _menuItem(
              icon: Icons.photo_camera,
              label: "Edit Foto Profil",
              onTap: () async {
                await Navigator.pushNamed(context, '/edit_foto');
                // Setelah kembali dari EditFotoPage, refresh data profil di DetailProfilPage
                _loadProfileData();
              },
            ),
            const Divider(color: Colors.white24),
            _menuItem(
              icon: Icons.edit,
              label: "Edit Nama User",
              onTap: () async {
                await Navigator.pushNamed(context, '/edit_profil');
                _loadProfileData(); // Refresh data setelah edit nama
              },
            ),
            const Divider(color: Colors.white24),
            _menuItem(
              icon: Icons.lock,
              label: "Ganti Password",
              onTap: () async {
                await Navigator.pushNamed(context, '/edit_password');
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