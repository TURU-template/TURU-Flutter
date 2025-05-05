// TURU-Flutter/turu_backend/lib/db.dart:

import 'dart:io';
import 'package:mysql_client/mysql_client.dart';
import 'env.dart';

class DatabaseService {
  late final MySQLConnectionPool _pool;

  DatabaseService() {
    final host = env['DB_HOST']!;
    final port = int.parse(env['DB_PORT']!);
    final userName = env['DB_USER']!;
    final password = env['DB_PASS']!;
    final dbName = env['DB_NAME']!;
    _pool = MySQLConnectionPool.new(
      host: host,
      port: port,
      userName: userName,
      password: password,
      databaseName: dbName,
      maxConnections: 5,
      secure: true,
    );
  }

  Future<void> ensureTablesExist() async {
    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS pengguna (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        jk CHAR(1) NULL,
        tanggal_lahir DATE NULL,
        state INT DEFAULT 1
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ''');
  }

  Future<IResultSet> getUserByUsername(String username) async {
    return await _pool.execute(
      'SELECT id, username, password, jk, tanggal_lahir FROM pengguna WHERE username = :username',
      {'username': username},
    );
  }

  Future<IResultSet> getUserById(int id) async {
    return await _pool.execute(
      'SELECT id, username, password, jk, tanggal_lahir FROM pengguna WHERE id = :id',
      {'id': id},
    );
  }

  Future<IResultSet> createUser({
    required String username,
    required String password,
    String? gender,
    String? birthDate,
  }) async {
    String? genderCode = (gender?.isNotEmpty ?? false) ? gender![0].toUpperCase() : null;
    if (genderCode != 'L' && genderCode != 'P') genderCode = null;
    final params = <String, dynamic>{
      'username': username,
      'password': password,
      'jk': genderCode,
      'tanggal_lahir': birthDate,
      'state': 1,
    };
    return await _pool.execute(
      'INSERT INTO pengguna (username, password, jk, tanggal_lahir, state) VALUES (:username, :password, :jk, :tanggal_lahir, :state)',
      params,
    );
  }

  Future<IResultSet> updateUser({
    required int userId,
    String? username,
    String? password,
    String? gender,
    String? birthDate,
  }) async {
    final updates = <String>[];
    final params = <String, dynamic>{ 'id': userId };
    if (username != null && username.isNotEmpty) {
      updates.add('username = :username');
      params['username'] = username;
    }
    if (password != null) {
      updates.add('password = :password');
      params['password'] = password;
    }
    if (gender != null && gender.isNotEmpty) {
      var code = gender[0].toUpperCase();
      if (code == 'L' || code == 'P') {
        updates.add('jk = :jk');
        params['jk'] = code;
      }
    }
    if (birthDate != null) {
      updates.add('tanggal_lahir = :tanggal_lahir');
      params['tanggal_lahir'] = birthDate;
    }
    if (updates.isEmpty) {
      throw ArgumentError('No fields to update');
    }
    final sql = 'UPDATE pengguna SET ${updates.join(', ')} WHERE id = :id';
    return await _pool.execute(sql, params);
  }
}
