import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import '../main.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: TuruColors.darkblue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 64),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Batalkan"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuruColors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Konfirmasi",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 64),
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/LOGO_Turu.png'),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                Text(
                  'Nama Pengguna',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Laki-laki | 2002-03-01',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 72),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Pengaturan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _settingItem(
            icon: BootstrapIcons.trash,
            label: 'Hapus Rekaman Tidur',
            color: TuruColors.pink,
            onTap:
                () => _showConfirmationDialog(
                  context: context,
                  title: "Yakin Hapus Data Tidur?",
                  description:
                      "Data rekaman tidurmu akan dihapus secara permanen. Tindakan ini tidak bisa dibatalkan.",
                  onConfirm: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Data tidur dihapus.")),
                    );
                  },
                ),
          ),
          _settingItem(
            icon: BootstrapIcons.box_arrow_right,
            label: 'Keluar Akun',
            color: TuruColors.pink,
            onTap:
                () => _showConfirmationDialog(
                  context: context,
                  title: "Yakin Log Out Akun?",
                  description:
                      "Kamu akan keluar dari akun ini. Pastikan data kamu sudah tersimpan.",
                  onConfirm: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
