// TURU-Flutter/turu_mobile/lib/services/auth.dart:
import 'dart:convert';
import 'dart:io' show Platform; // Import Platform
import 'package:http/http.dart' as http;

class AuthService {
  // --- PENTING: Sesuaikan Base URL ---
  // Gunakan 10.0.2.2 untuk Android Emulator
  // Gunakan IP Address mesin Anda (misal: 192.168.1.100) jika pakai physical device di jaringan yg sama
  // Gunakan localhost atau 127.0.0.1 jika pakai iOS Simulator
  static final String _baseUrl =
      Platform.isAndroid
          ? 'http://10.0.2.2:8080' // IP khusus Android Emulator ke host localhost
          : 'http://localhost:8080'; // Default untuk iOS Sim/platform lain

  // Fungsi Login (sudah oke, tapi kita tambahkan return data user jika sukses)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    print('Attempting login to $url with username: $username'); // Debug log
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-T'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15)); // Tambahkan timeout

      print('Login response status: ${response.statusCode}'); // Debug log
      // print('Login response body: ${response.body}'); // Debug log (hati-hati data sensitif)

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Login berhasil, kembalikan data user dari response backend
        print('Login successful for $username');
        return body
            as Map<String, dynamic>; // Harusnya berisi 'message' dan 'user'
      } else {
        // Login gagal, lemparkan error dari response backend
        final errorMessage =
            body['error'] ?? 'Login failed with status ${response.statusCode}';
        print('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print(
        'Error during login request: $e',
      ); // Log error jaringan/timeout/parsing
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      ); // Pesan error umum
    }
  }

  // Fungsi Register (perbaiki format tanggal_lahir)
  Future<void> register({
    required String username,
    required String password,
    required String? jk, // Terima L/P atau null
    required String? tanggalLahir, // Terima YYYY-MM-DD atau null
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    print('Attempting register to $url with username: $username'); // Debug log

    // Pastikan jk adalah 'L', 'P', atau null
    String? genderToSend = (jk == 'L' || jk == 'P') ? jk : null;

    // Pastikan tanggalLahir adalah format YYYY-MM-DD atau null
    String? birthDateToSend = tanggalLahir; // Asumsi sudah YYYY-MM-DD

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'jk': genderToSend, // Kirim 'L', 'P', atau null
              'tanggal_lahir': birthDateToSend, // Kirim YYYY-MM-DD atau null
            }),
          )
          .timeout(const Duration(seconds: 15)); // Tambahkan timeout

      print('Register response status: ${response.statusCode}'); // Debug log
      // print('Register response body: ${response.body}'); // Debug log

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Register berhasil
        print('Registration successful for $username');
        return; // Tidak perlu mengembalikan apa pun
      } else {
        // Register gagal
        final errorMessage =
            body['error'] ??
            'Register failed with status ${response.statusCode}';
        print('Registration failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print(
        'Error during register request: $e',
      ); // Log error jaringan/timeout/parsing
      // Beri pesan error spesifik jika mungkin
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server at $_baseUrl. Is the backend running?',
        );
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Connection refused by server at $_baseUrl. Is the backend running and port open?',
        );
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      ); // Pesan error umum
    }
  }

  // Tambahkan fungsi untuk menyimpan status login (contoh sederhana, gunakan shared_preferences di app nyata)
  // Ini hanya contoh, Anda perlu implementasi penyimpanan yang persisten
  bool _isUserLoggedIn = false;
  Map<String, dynamic>? _loggedInUserData;

  Future<void> setLoggedIn(Map<String, dynamic> userData) async {
    _isUserLoggedIn = true;
    _loggedInUserData =
        userData['user']; // Simpan data user dari response login
    // Di aplikasi nyata: simpan token/status ke SharedPreferences
    print("User set as logged in: ${_loggedInUserData?['username']}");
  }

  Future<void> logout() async {
    _isUserLoggedIn = false;
    _loggedInUserData = null;
    // Di aplikasi nyata: hapus token/status dari SharedPreferences
    print("User logged out.");
  }

  Future<bool> isLoggedIn() async {
    // Di aplikasi nyata: baca status dari SharedPreferences
    return _isUserLoggedIn;
  }

  Map<String, dynamic>? getCurrentUser() {
    // Di aplikasi nyata: baca data user dari SharedPreferences jika perlu
    return _loggedInUserData;
  }
}
