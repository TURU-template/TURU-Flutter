import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AuthService {
  static String get _baseUrl {
    const productionUrl = 'http://192.168.18.36:8080';

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
      
      // Handle kasus username sudah ada (409 Conflict)
      if (response.statusCode == 409) {
        print('Username already exists: $username');
        throw Exception('Username sudah digunakan');
      }
      
      // Handle error lainnya
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
      throw Exception('Gagal menghubungkan ke server. Periksa koneksi internet Anda.');
    } on TimeoutException catch (e) {
      print('Register TimeoutException: $e');
      throw Exception('Permintaan ke server melebihi batas waktu.');
    } on FormatException catch (e) {
      print('Register FormatException: $e');
      throw Exception('Format respons server tidak valid.');
    } catch (e) {
      print('Register general exception: $e');
      final msg = e.toString();
      
      // Prioritaskan error username sudah ada
      if (msg.contains('Username sudah digunakan') || 
          msg.contains('already exists') || 
          msg.contains('409')) {
        throw Exception('Username sudah digunakan');
      }
      
      // Re-throw exception
      rethrow;
    }
  }

  static bool _isUserLoggedIn = false;
  static Map<String, dynamic>? _loggedInUserData;

  Future<void> setLoggedIn(Map<String, dynamic> userData) async {
    _isUserLoggedIn = true;
    final rawUser = userData;

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

  /// Update username pengguna (alias untuk editName)
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

  /// Alias: editName
  Future<void> editName({
    required int userId,
    required String username,
  }) async {
    return updateProfile(userId: userId, username: username);
  }

  /// Ubah password pengguna (alias untuk editPassword)
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

  /// Alias: editPassword
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
