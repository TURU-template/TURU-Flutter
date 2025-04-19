// TURU-Flutter/turu_mobile/lib/pages/login.dart:
import 'package:flutter/material.dart';
import '../services/auth.dart'; // <-- Impor AuthService yang benar
import 'register.dart'; // <-- Impor halaman register
import '../main.dart'; // <-- Impor MainScreen dan TuruColors (jika perlu)

class LoginPage extends StatefulWidget {
  // Ganti nama agar konsisten (sebelumnya LoginPage)
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // <-- Gunakan AuthService
  bool _isLoading = false;
  String _errorMessage = ''; // Untuk menampilkan error di UI

  @override
  void initState() {
    super.initState();
    // Cek status login saat halaman dimuat (opsional, tergantung flow app)
    // _checkLoginStatus();
  }

  // Hapus fungsi _checkLoginStatus jika tidak diperlukan di sini
  /*
   Future<void> _checkLoginStatus() async {
     final isLoggedIn = await _authService.isLoggedIn();
     if (isLoggedIn && mounted) { // Cek mounted
       _navigateToMainScreen();
     }
   }
   */

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    // Validasi form
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = ''); // Hapus error lama jika ada
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Hapus pesan error sebelum mencoba login
    });

    try {
      // Panggil login dari AuthService
      final loginResult = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // Jika login berhasil (tidak melempar exception)
      // Simpan status login (AuthService perlu dimodifikasi untuk ini)
      await _authService.setLoggedIn(loginResult); // Tandai user sudah login

      // Navigasi ke halaman utama jika masih dalam context widget
      if (mounted) {
        _navigateToMainScreen();
      }
    } catch (e) {
      // Tangkap error dari AuthService
      if (mounted) {
        // Tambahkan cek mounted di sini juga
        setState(() {
          // Tampilkan pesan error yang didapat dari backend/AuthService
          _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          ); // Hapus prefix "Exception: "
        });
      } else {
        print("Login error caught after widget disposed: $e");
      }
    } finally {
      // Pastikan loading indicator berhenti meskipun error, jika widget masih mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Login sebagai tamu (jika fitur ini masih relevan)
  void _loginAsGuest() {
    print("Logging in as guest..."); // Tambahkan log untuk debugging
    // Langsung navigasi ke MainScreen tanpa autentikasi
    _navigateToMainScreen();
  }

  void _navigateToMainScreen() {
    // Ganti '/home' dengan '/main' sesuai definisi di main.dart
    // Pastikan '/main' terdaftar di MaterialApp routes
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ), // Pastikan nama class RegisterPage benar
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan warna dari TuruColors jika didefinisikan di main.dart
    final primaryBg = TuruColors.primaryBackground; // Contoh ambil warna
    final indigoColor = TuruColors.indigo; // Contoh ambil warna

    return Scaffold(
      // backgroundColor: primaryBg, // Gunakan warna tema
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent, // Atau sesuaikan
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            // Batasi lebar form di layar besar
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Lebarkan tombol/input
                children: [
                  // Tambahkan Judul atau Logo jika perlu
                  const Text(
                    'Selamat Datang!', // Contoh judul
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
                    textInputAction: TextInputAction.next, // Pindah ke password
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
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Password tidak boleh kosong'
                                : null,
                    textInputAction:
                        TextInputAction.done, // Selesai, trigger submit
                    onFieldSubmitted:
                        (_) => _submitLogin(), // Submit saat tekan done
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

                  // Tombol Login
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitLogin,
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
                                'Login',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol ke Register
                  TextButton(
                    onPressed: _isLoading ? null : _navigateToRegister,
                    child: const Text('Belum punya akun? Register di sini'),
                  ),

                  // --- TOMBOL LOGIN TAMU SEKARANG AKTIF ---
                  const SizedBox(height: 10), // Beri sedikit jarak
                  TextButton(
                    // Panggil fungsi _loginAsGuest saat ditekan
                    onPressed: _isLoading ? null : _loginAsGuest,
                    child: const Text('Masuk sebagai Tamu'),
                    // Anda bisa tambahkan style jika perlu
                    // style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),

                  // --- AKHIR TOMBOL LOGIN TAMU ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
