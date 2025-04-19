import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db.dart';

class AuthService {
  final DatabaseService _dbService;
  final String _userIdKey = 'userId';
  final String _usernameKey = 'username';

  AuthService(this._dbService);

  // Fungsi untuk hashing password menggunakan SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login dengan username dan password
  Future<bool> login(String username, String password) async {
    try {
      // Pastikan tabel ada
      await _dbService.ensureTablesExist();

      // Cari user berdasarkan username
      final results = await _dbService.getUserByUsername(username);

      if (results.isEmpty) {
        return false; // User tidak ditemukan
      }

      final user = results.first;
      final storedPassword = user['password'] as String;
      final hashedInputPassword = _hashPassword(password);

      if (storedPassword == hashedInputPassword) {
        // Jika password cocok, simpan info login di SharedPreferences
        await _saveUserSession(user['id'] as int, username);
        return true;
      } else {
        return false; // Password salah
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      return false;
    }
  }

  // Register user baru
  Future<bool> register({
    required String username,
    required String password,
    String? gender,
    String? birthDate,
  }) async {
    try {
      // Pastikan tabel ada
      await _dbService.ensureTablesExist();

      // Cek apakah username sudah ada
      final existingUser = await _dbService.getUserByUsername(username);
      if (existingUser.isNotEmpty) {
        return false; // Username sudah digunakan
      }

      // Hash password sebelum disimpan
      final hashedPassword = _hashPassword(password);

      // Simpan user baru ke database
      final result = await _dbService.createUser(
        username: username,
        password: hashedPassword,
        gender: gender,
        birthDate: birthDate,
      );

      return result.affectedRows! > 0;
    } catch (e) {
      print('Registration error: ${e.toString()}');
      return false;
    }
  }

  // Menyimpan informasi sesi user ke SharedPreferences
  Future<void> _saveUserSession(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
  }

  // Memeriksa apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userIdKey);
  }

  // Mendapatkan user ID saat ini
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Mendapatkan username saat ini
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }

  // Memperbarui password user
  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final userId = await getCurrentUserId();
      final username = await getCurrentUsername();

      if (userId == null || username == null) {
        return false; // User tidak login
      }

      // Verifikasi password saat ini
      final results = await _dbService.getUserByUsername(username);
      if (results.isEmpty) {
        return false;
      }

      final user = results.first;
      final storedPassword = user['password'] as String;
      final hashedCurrentPassword = _hashPassword(currentPassword);

      if (storedPassword != hashedCurrentPassword) {
        return false; // Password saat ini salah
      }

      // Update password dengan yang baru
      final hashedNewPassword = _hashPassword(newPassword);
      final updateResult = await _dbService.updateUser(
        userId: userId,
        password: hashedNewPassword,
      );

      return updateResult.affectedRows! > 0;
    } catch (e) {
      print('Update password error: ${e.toString()}');
      return false;
    }
  }

  // Memperbarui data profil user
  Future<bool> updateProfile({String? gender, String? birthDate}) async {
    try {
      final userId = await getCurrentUserId();

      if (userId == null) {
        return false; // User tidak login
      }

      final updateResult = await _dbService.updateUser(
        userId: userId,
        gender: gender,
        birthDate: birthDate,
      );

      return updateResult.affectedRows! > 0;
    } catch (e) {
      print('Update profile error: ${e.toString()}');
      return false;
    }
  }
}
