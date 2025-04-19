// lib/handlers.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:mysql1/mysql1.dart';
import 'package:bcrypt/bcrypt.dart';

import 'env.dart'; // ← ambil env dari lib/env.dart

Future<MySqlConnection> _getConnection() async {
  final settings = ConnectionSettings(
    host: env['DB_HOST']!, // tambahkan !
    port: int.parse(env['DB_PORT']!),
    user: env['DB_USER']!,
    password: env['DB_PASS']!,
    db: env['DB_NAME']!,
    useSSL: false,
    useCompression: false,
  );

  return await MySqlConnection.connect(settings);
}

Future<Response> registerHandler(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final conn = await _getConnection();

  final username = body['username'];
  final pwd = body['password'];
  final jk = body['jk'];
  final tgl = body['tanggal_lahir'];

  final hashed = BCrypt.hashpw(pwd, BCrypt.gensalt());

  try {
    await conn.query(
      'INSERT INTO pengguna (username, password, jk, tanggal_lahir, state) VALUES (?, ?, ?, ?, ?)',
      [username, hashed, jk, tgl, 1],
    );
    return Response.ok(jsonEncode({'message': 'Register sukses'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  } finally {
    await conn.close();
  }
}

Future<Response> loginHandler(Request req) async {
  final body = jsonDecode(await req.readAsString());
  final conn = await _getConnection();

  try {
    final res = await conn.query(
      'SELECT password FROM pengguna WHERE username = ?',
      [body['username']],
    );
    if (res.isEmpty) {
      return Response.forbidden(
          jsonEncode({'error': 'Username tidak ditemukan'}));
    }
    final hashed = res.first[0] as String;
    if (BCrypt.checkpw(body['password'], hashed)) {
      return Response.ok(jsonEncode({'message': 'Login berhasil'}));
    } else {
      return Response.forbidden(jsonEncode({'error': 'Password salah'}));
    }
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  } finally {
    await conn.close();
  }
}
