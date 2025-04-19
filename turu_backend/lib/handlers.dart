// TURU-Flutter/turu_backend/lib/handlers.dart:
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mysql1/mysql1.dart'; // Import untuk MySqlException
import 'db.dart';

final dbService = DatabaseService();

Future<Response> registerHandler(Request req) async {
  try {
    final bodyString = await req.readAsString();
    if (bodyString.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Request body is empty'}));
    }
    final body = jsonDecode(bodyString);

    // Validasi input dasar
    final username = body['username'] as String?;
    final pwd = body['password'] as String?;
    final jk =
        body['jk'] as String?; // Terima 'L' atau 'P', atau null/string kosong
    final tgl = body['tanggal_lahir']
        as String?; // Terima YYYY-MM-DD, atau null/string kosong

    if (username == null || username.isEmpty || pwd == null || pwd.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Username and password are required'}));
    }

    // Pastikan tabel ada (akan coba connect jika belum)
    // await dbService.ensureTablesExist(); // Dipanggil di dalam getConnection()

    // Hash password
    final hashed = BCrypt.hashpw(pwd, BCrypt.gensalt());

    // Coba buat user
    await dbService.createUser(
      username: username,
      password: hashed,
      // Kirim null jika jk atau tgl kosong/null
      gender: (jk?.isNotEmpty ?? false) ? jk : null,
      birthDate: (tgl?.isNotEmpty ?? false)
          ? tgl
          : null, // Pastikan format YYYY-MM-DD dari frontend
    );
    return Response.ok(jsonEncode({'message': 'Register successful'}));
  } on MySqlException catch (e) {
    print("[Register Error - MySQL]: ${e.message} (Code: ${e.errorNumber})");
    // Kirim pesan error yang lebih spesifik jika username duplikat
    if (e.errorNumber == 1062) {
      // Error code for duplicate entry
      return Response(409, // 409 Conflict cocok untuk resource yang sudah ada
          body: jsonEncode({'error': 'Username already exists'}));
    }
    return Response.internalServerError(
        body: jsonEncode({'error': 'Database error during registration'}));
  } on FormatException catch (e) {
    print("[Register Error - Format]: ${e.message}");
    return Response(400,
        body: jsonEncode({'error': 'Invalid request format: ${e.message}'}));
  } catch (e) {
    print("[Register Error - General]: ${e.toString()}");
    // Kirim pesan error yang lebih umum ke client
    String errorMessage = 'Registration failed due to an unexpected error.';
    if (e is Exception && e.toString().contains('Username already exists')) {
      return Response(409,
          body: jsonEncode({'error': 'Username already exists'}));
    } else if (e is Exception) {
      // Jangan ekspos detail error internal secara langsung ke client
      // errorMessage = e.toString(); // Hindari ini di production
    }
    return Response.internalServerError(
        body: jsonEncode({'error': errorMessage}));
  } finally {
    // Pertimbangkan untuk menutup koneksi jika tidak digunakan lagi secara aktif
    // await dbService.closeConnection(); // Atau kelola pool koneksi jika traffic tinggi
  }
}

Future<Response> loginHandler(Request req) async {
  try {
    final bodyString = await req.readAsString();
    if (bodyString.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Request body is empty'}));
    }
    final body = jsonDecode(bodyString);

    final username = body['username'] as String?;
    final password = body['password'] as String?;

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Username and password are required'}));
    }

    // Pastikan tabel ada (akan coba connect jika belum)
    // await dbService.ensureTablesExist(); // Dipanggil di dalam getConnection()

    final users = await dbService.getUserByUsername(username);

    if (users.isEmpty) {
      print("Login attempt failed: Username '$username' not found.");
      return Response(401, // 401 Unauthorized lebih cocok untuk login gagal
          body: jsonEncode({'error': 'Invalid username or password'}));
    }

    final user = users.first;
    final storedHashed = user['password'] as String; // Ambil hash dari DB

    // Verifikasi password
    if (BCrypt.checkpw(password, storedHashed)) {
      print("Login successful for username: '$username'");
      // Di aplikasi nyata, Anda akan membuat token JWT di sini
      return Response.ok(jsonEncode({
        'message': 'Login successful',
        // Kirim data user lain jika perlu (kecuali password)
        'user': {
          'id': user['id'],
          'username': user['username'],
          'jk': user['jk'],
          'tanggal_lahir': user['tanggal_lahir']
              ?.toString()
              .split(' ')[0], // Format YYYY-MM-DD
        }
      }));
    } else {
      print(
          "Login attempt failed: Incorrect password for username '$username'.");
      return Response(401,
          body: jsonEncode({'error': 'Invalid username or password'}));
    }
  } on MySqlException catch (e) {
    print("[Login Error - MySQL]: ${e.message} (Code: ${e.errorNumber})");
    return Response.internalServerError(
        body: jsonEncode({'error': 'Database error during login'}));
  } on FormatException catch (e) {
    print("[Login Error - Format]: ${e.message}");
    return Response(400,
        body: jsonEncode({'error': 'Invalid request format: ${e.message}'}));
  } catch (e) {
    print("[Login Error - General]: ${e.toString()}");
    return Response.internalServerError(
        body: jsonEncode({'error': 'Login failed due to an unexpected error'}));
  } finally {
    // Pertimbangkan untuk menutup koneksi jika tidak digunakan lagi secara aktif
    // await dbService.closeConnection();
  }
}
