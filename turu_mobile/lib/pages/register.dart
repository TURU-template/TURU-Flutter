// TURU-Flutter/turu_mobile/lib/pages/register.dart:
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl untuk format tanggal
import '../services/auth.dart'; // <-- Impor AuthService
import '../main.dart'; // <-- Impor TuruColors jika perlu

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Tambah konfirmasi password
  final _tglController =
      TextEditingController(); // Controller untuk tanggal lahir
  final AuthService _authService = AuthService(); // <-- Gunakan AuthService
  bool _isLoading = false;
  String _errorMessage = '';
  String? _selectedGender; // Untuk menyimpan L atau P
  DateTime? _selectedDate; // Untuk menyimpan tanggal terpilih

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tglController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Sembunyikan keyboard jika terbuka
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // Tanggal awal di picker
      firstDate: DateTime(1900), // Batas tanggal awal
      lastDate: DateTime.now(), // Batas tanggal akhir (hari ini)
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format tanggal ke YYYY-MM-DD untuk dikirim ke backend
        _tglController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitRegister() async {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    // Validasi form
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = '');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Hapus error lama
    });

    try {
      // Panggil register dari AuthService
      await _authService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        jk: _selectedGender, // Kirim 'L', 'P', atau null
        tanggalLahir:
            _tglController.text.isNotEmpty
                ? _tglController.text
                : null, // Kirim YYYY-MM-DD atau null
      );

      // Jika berhasil (tidak melempar exception)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );
        // Kembali ke halaman login setelah berhasil
        Navigator.pop(context);
      }
    } catch (e) {
      // Tangkap error dari AuthService
      if (mounted) {
        // Ambil pesan asli tanpa prefix "Exception: "
        String rawMsg = e.toString().replaceFirst('Exception: ', '');
        String errorMsg;
        
        // Prioritaskan penanganan error username sudah ada
        if (rawMsg.contains('Username already exists') || 
            rawMsg.contains('sudah terdaftar') ||
            rawMsg.contains('409')) { // Status code 409 = Conflict
          errorMsg = 'Username telah digunakan, gunakan username lain';
        } else if (rawMsg.contains('Username and password are required')) {
          errorMsg = 'Username dan password harus diisi.';
        } else if (rawMsg.contains('Invalid request format')) {
          errorMsg = 'Format input tidak valid.';
        } else if (rawMsg.toLowerCase().contains('timeout') || 
                   rawMsg.contains('connection') ||
                   rawMsg.contains('Failed host lookup')) {
          // Koneksi error tetap ditampilkan sebagai masalah koneksi
          errorMsg = 'Gagal terhubung ke server. Periksa koneksi internet.';
        } else {
          // Fallback dengan pesan generik yang lebih informatif
          errorMsg = 'Terjadi kesalahan. Silakan coba lagi nanti.';
          // Log error asli untuk debugging
          print('Register error: $rawMsg');
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuruColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: TuruColors.backdrop,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF1E214A),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registrasi Pengguna',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.white30,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(Icons.person, color: Colors.black54),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.black),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Username tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(Icons.key, color: Colors.amber),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.black),
                          obscureText: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password tidak boleh kosong';
                            if (val.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Konfirmasi Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            hintText: 'Konfirmasi Password',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(Icons.key, color: Colors.amber),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.black),
                          obscureText: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                            if (val != _passwordController.text) return 'Password dan konfirmasi tidak cocok';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Tanggal Lahir
                        TextFormField(
                          controller: _tglController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            hintText: 'mm/dd/yyyy',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(Icons.calendar_today, color: Colors.blue),
                            ),
                            suffixIcon: Icon(Icons.calendar_month, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                        // Gender Toggle Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 10, // Give more space to the laki-laki button
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => setState(() => _selectedGender = 'L'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedGender == 'L' ? TuruColors.blue : Colors.white,
                                    foregroundColor: _selectedGender == 'L' ? Colors.white : Colors.blue,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(Icons.male, size: 18),
                                  label: Text('Laki-laki', 
                                    style: TextStyle(
                                      color: _selectedGender == 'L' ? Colors.white : Colors.black,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8), // Reduced space between buttons
                            Expanded(
                              flex: 11, // Give more space to the perempuan button
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => setState(() => _selectedGender = 'P'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedGender == 'P' ? TuruColors.pink : Colors.white,
                                    foregroundColor: _selectedGender == 'P' ? Colors.white : Colors.pink,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(Icons.female, size: 18),
                                  label: Text('Perempuan', 
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      color: _selectedGender == 'P' ? Colors.white : Colors.black,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 32),
                        // Register Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TuruColors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, 
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Register', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Sudah Punya Akun
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: TuruColors.indigo),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Sudah Punya Akun', style: TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
