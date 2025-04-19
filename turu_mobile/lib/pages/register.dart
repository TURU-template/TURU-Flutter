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
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    final indigoColor = TuruColors.indigo; // Contoh ambil warna

    return Scaffold(
      // backgroundColor: TuruColors.primaryBackground, // Sesuaikan
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Input Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Username tidak boleh kosong'
                                : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Password tidak boleh kosong';
                      if (val.length < 6)
                        return 'Password minimal 6 karakter'; // Contoh validasi panjang
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Input Konfirmasi Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return 'Konfirmasi password tidak boleh kosong';
                      if (val != _passwordController.text)
                        return 'Password tidak cocok';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Input Tanggal Lahir (Read Only, Trigger Date Picker)
                  TextFormField(
                    controller: _tglController,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Lahir (Opsional)',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: const OutlineInputBorder(),
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: IconButton(
                        // Tombol untuk membuka picker
                        icon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true, // Buat read only agar keyboard tidak muncul
                    onTap:
                        () => _selectDate(context), // Buka picker saat diklik
                    // Tidak perlu validator wajib karena opsional
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Jenis Kelamin (Opsional)
                  const Text(
                    "Jenis Kelamin (Opsional):",
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Laki-laki'),
                          value: 'L',
                          groupValue: _selectedGender,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedGender = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Perempuan'),
                          value: 'P',
                          groupValue: _selectedGender,
                          onChanged:
                              (value) =>
                                  setState(() => _selectedGender = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  // Tombol untuk clear pilihan gender
                  if (_selectedGender != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedGender = null),
                      child: const Text(
                        "Hapus Pilihan Gender",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Tampilkan Pesan Error
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Tombol Register
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: indigoColor,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                'Register',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol kembali ke Login
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Sudah punya akun? Login'),
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
