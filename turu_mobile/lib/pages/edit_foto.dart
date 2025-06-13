import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../main.dart';

class EditFotoPage extends StatefulWidget {
  const EditFotoPage({super.key});

  @override
  State<EditFotoPage> createState() => _EditFotoPageState();
}

class _EditFotoPageState extends State<EditFotoPage> {
  XFile? _pickedXFile;
  Uint8List? _imageBytes;

  String? _profileImageUrl;
  bool _isLoading = false;

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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      _pickedXFile = pickedFile;
      _imageBytes = await pickedFile.readAsBytes();

      setState(() {
        // rebuild
      });
    }
  }

  Future<void> _uploadFoto() async {
    if (_pickedXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada foto yang dipilih untuk diupload')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = AuthService().getCurrentUser();
    if (user == null || user['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID tidak ditemukan. Harap login kembali.')),
      );
      setState(() { _isLoading = false; });
      return;
    }
    final userId = user['id'];
    final baseUrl = AuthService.getBaseUrl();

    final uri = Uri.parse('$baseUrl/api/user/$userId/profile-picture');
    var request = http.MultipartRequest('POST', uri);

    try {
      List<int> imageBytes = await _pickedXFile!.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: _pickedXFile!.name,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(responseBody);
        final String newProfileImageUrl = responseData['profilePictureUrl'];

        AuthService().updateCurrentUser({'profilePictureUrl': newProfileImageUrl});
        await AuthService().refreshCurrentUser(); // Panggil ini setelah update berhasil

        setState(() {
          _profileImageUrl = newProfileImageUrl;
          _pickedXFile = null;
          _imageBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diupload!')),
        );
        Navigator.pop(context);
      } else {
        String errorMessage = 'Gagal mengupload foto profil. Status: ${response.statusCode}';
        try {
          final errorData = jsonDecode(responseBody);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (e) {
          //
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat mengupload foto: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: TuruColors.navbarBackground,
        elevation: 0,
        title: const Text('Edit Foto Profil', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              backgroundImage: _imageBytes != null
                  ? MemoryImage(_imageBytes!) as ImageProvider<Object>
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage('${AuthService.getBaseUrl()}$_profileImageUrl') as ImageProvider<Object>
                      : const AssetImage('assets/images/LOGO_Turu.png') as ImageProvider<Object>),
              child: (_imageBytes == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                  ? const Icon(Icons.person, color: Colors.white38, size: 50)
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Kamera"),
                  style: ElevatedButton.styleFrom(backgroundColor: TuruColors.indigo),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Galeri"),
                  style: ElevatedButton.styleFrom(backgroundColor: TuruColors.indigo),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadFoto,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuruColors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}