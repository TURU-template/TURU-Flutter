import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static String get _baseUrl {
    // URL produksi dari tim (192.168.18.36)
    const productionUrl = 'https://turu.azurewebsites.net';
    // URL untuk pengembangan lokal (localhost atau emulator Android)
    const webLocalUrl = 'https://turu.azurewebsites.net';
    const androidEmulatorLocalUrl = 'https://turu.azurewebsites.net';

    if (kIsWeb) {
      // Jika di web, gunakan localhost untuk pengembangan, atau productionUrl untuk deploy
      // Untuk pengembangan lokal, pakai webLocalUrl. Untuk produksi, productionUrl.
      // Anda bisa menambahkan logic jika ingin switch antara dev/prod di web.
      // Untuk saat ini, asumsikan localhost untuk dev web.
      print("Web environment detected, using $webLocalUrl");
      return webLocalUrl;
    } else {
      try {
        if (Platform.isAndroid) {
          // Jika di Android (emulator), gunakan 10.0.2.2 untuk lokal.
          print("Android environment detected, using $androidEmulatorLocalUrl");
          return androidEmulatorLocalUrl;
        } else {
          // Jika di iOS emulator/desktop, gunakan localhost untuk lokal.
          print("Non-Android (iOS/Desktop) environment detected, using $webLocalUrl");
          return webLocalUrl;
        }
      } catch (e) {
        // Fallback jika Platform.isAndroid tidak dapat diakses (misal di test environment)
        print("Error checking platform: $e. Using fallback $webLocalUrl");
        return webLocalUrl; // Fallback umum
      }
    }
  }

  static String getBaseUrl() => _baseUrl;

  Map<String, dynamic>? _loggedInUserData;
  bool _isUserLoggedIn = false;

  Future<void> initAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('loggedInUser');
    if (userDataString != null) {
      try {
        _loggedInUserData = jsonDecode(userDataString) as Map<String, dynamic>;
        _isUserLoggedIn = true;
        print('User data loaded from SharedPreferences: ${_loggedInUserData?['username']}');
      } catch (e) {
        print('Error decoding user data from SharedPreferences: $e');
        await prefs.remove('loggedInUser');
        _loggedInUserData = null;
        _isUserLoggedIn = false;
      }
    } else {
      print('No user data found in SharedPreferences.');
    }
  }

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
        _loggedInUserData = body as Map<String, dynamic>;
        _isUserLoggedIn = true;
        await _saveCurrentUserToPrefs();
        print('Login success for $username. Data: $_loggedInUserData');
        return body as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final errorMessage = body['error'] ?? 'Invalid username or password';
        throw Exception(errorMessage);
      } else {
        final errorMessage = body['error'] ?? 'Unexpected error (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Gagal menghubungkan ke server. Pastikan server berjalan dan alamatnya benar.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melebihi batas waktu.');
    } catch (e) {
      print('Unexpected login error: $e');
      throw Exception('Terjadi kesalahan saat login. Silakan coba lagi.');
    }
  }

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
      ).timeout(const Duration(seconds: 10));

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Register success for $username');
        return;
      }

      if (response.statusCode == 409) {
        print('Username sudah digunakan');
        throw Exception('Username sudah digunakan');
      }

      String errorMessage;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] ?? 'Gagal registrasi (${response.statusCode})';
      } catch (e) {
        errorMessage = 'Gagal registrasi (${response.statusCode}): ${response.body}';
      }

      throw Exception(errorMessage);
    } on SocketException catch (e) {
      print('Register SocketException: $e');
      throw Exception('Gagal menghubungkan ke server. Pastikan server berjalan dan alamatnya benar.');
    } on TimeoutException catch (e) {
      print('Register TimeoutException: $e');
      throw Exception('Permintaan ke server melebihi batas waktu.');
    } on FormatException catch (e) {
      print('Register FormatException: $e');
      throw Exception('Format respons server tidak valid.');
    } catch (e) {
      print('Register general exception: $e');
      final msg = e.toString();

      if (msg.contains('Username sudah digunakan') ||
          msg.contains('already exists') ||
          msg.contains('409')) {
        throw Exception('Username sudah digunakan');
      }

      rethrow;
    }
  }

  void updateCurrentUser(Map<String, dynamic> dataToUpdate) {
    if (_loggedInUserData != null) {
      _loggedInUserData!.addAll(dataToUpdate);
      _saveCurrentUserToPrefs();
      print('Current user data updated: $_loggedInUserData');
    } else {
      print('Cannot update current user data: user is not logged in.');
    }
  }

  Future<void> logout() async {
    _isUserLoggedIn = false;
    _loggedInUserData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUser');
    print('User logged out.');
  }

  Future<bool> isLoggedIn() async {
    if (_loggedInUserData == null) {
      await initAuth();
    }
    return _isUserLoggedIn;
  }

  Map<String, dynamic>? getCurrentUser() {
    if (_loggedInUserData == null) {
      initAuth();
    }
    return _loggedInUserData;
  }

  Future<void> _saveCurrentUserToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_loggedInUserData != null) {
      await prefs.setString('loggedInUser', jsonEncode(_loggedInUserData));
      print('User data saved to SharedPreferences.');
    } else {
      await prefs.remove('loggedInUser');
      print('User data removed from SharedPreferences.');
    }
  }

  Future<void> refreshCurrentUser() async {
    if (!_isUserLoggedIn || _loggedInUserData == null || _loggedInUserData!['id'] == null) {
      return;
    }

    final userId = _loggedInUserData!['id'];
    final url = Uri.parse('$_baseUrl/api/user/$userId');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Pastikan Anda memuat data pengguna dari body['user'] jika API Anda mengembalikan struktur tersebut
        _loggedInUserData = body as Map<String, dynamic>;
        await _saveCurrentUserToPrefs();
      }
    } catch (e) {
      // Handle error, tapi jangan sampai crash
      print('Error refreshing current user: $e');
    }
  }

  Future<void> updateProfile({
    required int userId,
    required String username,
  }) async {
    final url = Uri.parse('$_baseUrl/user/$userId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        updateCurrentUser({'username': username});
        await refreshCurrentUser();
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Gagal memperbarui profil. Periksa koneksi ke server.');
    }
  }

  Future<void> editName({
    required int userId,
    required String username,
  }) async {
    return updateProfile(userId: userId, username: username);
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/user/$userId/password');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? response.body;
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Gagal mengubah password. Periksa koneksi ke server.');
    }
  }

  Future<void> editPassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    return changePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}