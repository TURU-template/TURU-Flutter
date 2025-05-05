// TURU-Flutter/turu_mobile/lib/services/auth.dart:
import 'dart:convert';
// Import kIsWeb untuk memeriksa apakah berjalan di web
import 'package:flutter/foundation.dart' show kIsWeb;
// Import dart:io hanya jika tidak di web, atau guard penggunaannya
import 'dart:io' show Platform; // Tetap import, tapi hati-hati penggunaannya

import 'package:http/http.dart' as http;

class AuthService {
  // --- PENTING: Ubah _baseUrl menjadi getter untuk logika dinamis ---
  static String get _baseUrl {
    if (kIsWeb) {
      // --- JIKA BERJALAN DI WEB ---
      // Gunakan localhost:8080 (asumsi backend jalan di mesin yang sama & handle CORS)
      // atau URL backend yang sudah di-deploy jika ada.
      // Pastikan backend Anda mengizinkan request dari origin web Anda (CORS).
      print("Running on Web, using http://localhost:8080 for backend.");
      return 'http://localhost:8080';
    } else {
      // --- JIKA BERJALAN DI NON-WEB (Mobile/Desktop) ---
      // Kode ini aman dijalankan karena kita sudah tahu BUKAN web
      try {
        if (Platform.isAndroid) {
          print("Running on Android, using http://10.0.2.2:8080 for backend.");
          return 'http://10.0.2.2:8080'; // IP khusus Android Emulator
        } else {
          // Asumsikan iOS Simulator atau platform mobile/desktop lainnya
          print(
            "Running on non-Android (iOS/Desktop?), using http://localhost:8080 for backend.",
          );
          return 'http://localhost:8080';
        }
      } catch (e) {
        // Fallback jika ada error tak terduga saat cek Platform (jarang terjadi jika !kIsWeb)
        print(
          "Error detecting mobile platform: $e. Falling back to http://localhost:8080",
        );
        return 'http://localhost:8080';
      }
    }
  }

  // Fungsi Login (tidak perlu diubah, akan otomatis menggunakan getter _baseUrl)
  Future<Map<String, dynamic>> login(String username, String password) async {
    // _baseUrl di sini akan memanggil getter di atas
    final url = Uri.parse('$_baseUrl/login');
    print('Attempting login to $url with username: $username');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            }, // Perbaiki typo UTF-T -> UTF-8
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      print('Login response status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Login successful for $username');
        return body as Map<String, dynamic>;
      } else {
        final errorMessage =
            body['error'] ?? 'Login failed with status ${response.statusCode}';
        print('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error during login request: $e');
      // Beri pesan error spesifik jika mungkin
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Is the backend running at the correct address ($_baseUrl)?',
        );
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Connection refused by server. Is the backend running and port open at $_baseUrl?',
        );
      } else if (e is Exception && e.toString().contains('TimeoutException')) {
        throw Exception(
          'Connection timed out trying to reach the server at $_baseUrl.',
        );
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection and backend status.',
      );
    }
  }

  // Fungsi Register (tidak perlu diubah, akan otomatis menggunakan getter _baseUrl)
  Future<void> register({
    required String username,
    required String password,
    required String? jk,
    required String? tanggalLahir,
  }) async {
    // _baseUrl di sini akan memanggil getter di atas
    final url = Uri.parse('$_baseUrl/register');
    print('Attempting register to $url with username: $username');

    String? genderToSend = (jk == 'L' || jk == 'P') ? jk : null;
    String? birthDateToSend = tanggalLahir;

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'jk': genderToSend,
              'tanggal_lahir': birthDateToSend,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Register response status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Registration successful for $username');
        return;
      } else {
        final errorMessage =
            body['error'] ??
            'Register failed with status ${response.statusCode}';
        print('Registration failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error during register request: $e');
      // Beri pesan error spesifik jika mungkin
      if (e is Exception && e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Is the backend running at the correct address ($_baseUrl)?',
        );
      } else if (e is Exception &&
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Connection refused by server. Is the backend running and port open at $_baseUrl?',
        );
      } else if (e is Exception && e.toString().contains('TimeoutException')) {
        throw Exception(
          'Connection timed out trying to reach the server at $_baseUrl.',
        );
      }
      throw Exception(
        'Failed to connect to the server. Please check your connection and backend status.',
      );
    }
  }

  // --- Sisa AuthService (isLoggedIn, setLoggedIn, dll) tidak perlu diubah ---
  static bool _isUserLoggedIn = false;
  static Map<String, dynamic>? _loggedInUserData;

  Future<void> setLoggedIn(Map<String, dynamic> userData) async {
    _isUserLoggedIn = true;
    // Ensure user ID is stored as int
    final rawUser = userData['user'];
    if (rawUser is Map<String, dynamic>) {
      final userMap = Map<String, dynamic>.from(rawUser);
      final idVal = userMap['id'];
      // Parse id if it's a string
      if (idVal is String) {
        userMap['id'] = int.tryParse(idVal) ?? idVal;
      }
      _loggedInUserData = userMap;
      print("User set as logged in: \\${_loggedInUserData?['username']}");
    } else {
      _loggedInUserData = null;
      print('Failed to set user: invalid user data');
    }
  }

  Future<void> logout() async {
    _isUserLoggedIn = false;
    _loggedInUserData = null;
    print("User logged out.");
  }

  Future<bool> isLoggedIn() async {
    return _isUserLoggedIn;
  }

  Map<String, dynamic>? getCurrentUser() {
    return _loggedInUserData;
  }

  // Fungsi Update Profil
  Future<void> updateProfile({required int userId, required String username}) async {
    final url = Uri.parse('$_baseUrl/user/$userId');
    print('Attempting updateProfile to $url with username: $username');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username}),
      ).timeout(const Duration(seconds: 15));
      print('updateProfile response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Update local user data
        _loggedInUserData?['username'] = username;
        return;
      } else {
        String errorMessage;
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        print('updateProfile failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error during updateProfile request: $e');
      throw Exception('Gagal terhubung ke server: ${e.toString()}');
    }
  }

  // Fungsi Ubah Password
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/user/$userId/password');
    print('Attempting changePassword to $url for userId: $userId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      ).timeout(const Duration(seconds: 15));
      print('changePassword response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return;
      } else {
        String errorMessage;
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['error'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        print('changePassword failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error during changePassword request: $e');
      throw Exception('Gagal terhubung ke server: ${e.toString()}');
    }
  }
}
