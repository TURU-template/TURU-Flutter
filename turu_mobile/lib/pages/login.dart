// TURU-Flutter/turu_mobile/lib/pages/login.dart:
import 'package:flutter/material.dart';
import '../services/auth.dart'; // <-- Impor AuthService yang benar
import 'register.dart'; // <-- Impor halaman register
import '../main.dart'; // <-- Impor MainScreen dan TuruColors (jika perlu)
import 'package:http/http.dart' as http; // <-- Impor paket http

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
      http.post(
        Uri.parse("http://localhost:8080/login"), // <-- Corrected URL and type
        body: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text.trim(),
        },
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login Pengguna',
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Password tidak boleh kosong'
                          : null,
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TuruColors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _navigateToRegister,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: TuruColors.indigo),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Belum Punya Akun',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    
                    // Guest Login
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white30,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'atau',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white30,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _isLoading ? null : _loginAsGuest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: TuruColors.pink,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Masuk sebagai Tamu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
