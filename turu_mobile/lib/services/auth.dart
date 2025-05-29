import 'dart:async'; // Untuk TimeoutException
import 'dart:convert';
import 'dart:io' show Platform, SocketException; // SocketException hanya untuk non-web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthService {
  // Getter untuk URL backend tergantung platform
  static String get _baseUrl {
    const productionUrl = 'http://10.0.2.2:8080';

    if (kIsWeb) {
      print("Web environment detected, using $productionUrl");
      return productionUrl;
    } else {
      try {
        if (Platform.isAndroid) {
          print("Android environment detected, using $productionUrl");
          return productionUrl;
        } else {
          print("Non-Android (iOS/Desktop) environment detected, using $productionUrl");
          return productionUrl;
        }
      } catch (e) {
        print("Error checking platform: $e. Using fallback $productionUrl");
        return productionUrl;
      }
    }
  }

  static String getBaseUrl() => _baseUrl;

  /// Fungsi login pengguna
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');
    print('Sending login request to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      print('Login response status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Login success for $username');
        return body as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final errorMessage = body['error'] ?? 'Invalid username or password';
        throw Exception(errorMessage);
      } else {
        final errorMessage = body['error'] ?? 'Unexpected error (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Gagal menghubungkan ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melebihi batas waktu.');
    } catch (e) {
      print('Unexpected login error: $e');
      throw Exception('Terjadi kesalahan saat login. Silakan coba lagi.');
    }
  }

  /// Fungsi register pengguna baru
  Future<void> register({
    required String username,
    required String password,
    required String? jk,
    required String? tanggalLahir,
  }) async {
    final url = Uri.parse('$_baseUrl/api/register');
    print('Sending register request to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'jk': (jk == 'L' || jk == 'P') ? jk : null,
          'tanggal_lahir': tanggalLahir,
        }),
      ).timeout(const Duration(seconds: 5));

      print('Register response status: ${response.statusCode}');
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Register success for $username');
        return;
      } else if (response.statusCode == 409) {
        throw Exception('Username sudah digunakan.');
      } else {
        final errorMessage = body['error'] ?? 'Gagal registrasi (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Username already exists')) {
        throw Exception('Username sudah digunakan.');
      } else if (msg.contains('Failed host lookup')) {
        throw Exception('Tidak dapat terhubung ke server di $_baseUrl. Periksa koneksi.');
      } else if (msg.contains('Connection refused')) {
        throw Exception('Server menolak koneksi. Pastikan backend berjalan di $_baseUrl.');
      } else if (msg.contains('TimeoutException')) {
        throw Exception('Permintaan ke server timeout ($_baseUrl).');
      }

      throw Exception('Gagal terhubung ke server. Periksa koneksi dan status backend.');
    }
  }

  /// Status login pengguna
  static bool _isUserLoggedIn = false;
  static Map<String, dynamic>? _loggedInUserData;

  Future<void> setLoggedIn(Map<String, dynamic> userData) async {
    _isUserLoggedIn = true;
    final rawUser = userData['user'];

    if (rawUser is Map<String, dynamic>) {
      final userMap = Map<String, dynamic>.from(rawUser);
      final id = userMap['id'];

      if (id is String) {
        userMap['id'] = int.tryParse(id) ?? id;
      }

      _loggedInUserData = userMap;
      print('User logged in: ${_loggedInUserData?['username']}');
    } else {
      print('Invalid user data received.');
      _loggedInUserData = null;
    }
  }

  Future<void> logout() async {
    _isUserLoggedIn = false;
    _loggedInUserData = null;
    print('User logged out.');
  }

  Future<bool> isLoggedIn() async => _isUserLoggedIn;

  Map<String, dynamic>? getCurrentUser() => _loggedInUserData;

  /// Update username pengguna
  Future<void> updateProfile({
    required int userId,
    required String username,
  }) async {
    final url = Uri.parse('$_baseUrl/user/$userId');
    print('Updating profile at $url');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username}),
      ).timeout(const Duration(seconds: 15));

      print('updateProfile status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _loggedInUserData?['username'] = username;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('updateProfile error: $e');
      throw Exception('Gagal memperbarui profil. Periksa koneksi ke server.');
    }
  }

  /// Ubah password pengguna
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/user/$userId/password');
    print('Changing password at $url');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      print('changePassword status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('changePassword error: $e');
      throw Exception('Gagal mengubah password. Periksa koneksi ke server.');
    }
  }
}
