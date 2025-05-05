// TURU-Flutter/turu_backend/lib/handlers.dart:
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:mysql_client/exception.dart';
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
      gender: (jk?.isNotEmpty ?? false) ? jk : null,
      birthDate: (tgl?.isNotEmpty ?? false) ? tgl : null,
    );
    return Response.ok(jsonEncode({'message': 'Register successful'}));
  } on MySQLServerException catch (e) {
    print("[Register Error - MySQL]: ${e.message} (Code: ${e.errorCode})");
    if (e.errorCode == 1062) {
      return Response(409,
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
    print("[Login Debug] Raw bodyString: $bodyString");
    if (bodyString.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Request body is empty'}));
    }
    final body = jsonDecode(bodyString);
    print("[Login Debug] Decoded body: $body");

    final username = body['username'] as String?;
    final password = body['password'] as String?;
    print("[Login Debug] username: $username, password: $password");

    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Username and password are required'}));
    }

    // Pastikan tabel ada (akan coba connect jika belum)
    // await dbService.ensureTablesExist(); // Dipanggil di dalam getConnection()

    final result = await dbService.getUserByUsername(username);
    print("[Login Debug] Rows returned count: ${result.rows.length}");

    if (result.rows.isEmpty) {
      print("Login attempt failed: Username '$username' not found.");
      return Response(401, // 401 Unauthorized lebih cocok untuk login gagal
          body: jsonEncode({'error': 'Invalid username or password'}));
    }

    final row = result.rows.first;
    print("[Login Debug] User row: $row");
    final map = row.assoc();
    final storedHashed = map['password'] as String;
    print("[Login Debug] Stored hashed password: $storedHashed");

    // Verifikasi password
    final passwordOk = BCrypt.checkpw(password, storedHashed);
    print("[Login Debug] checkpw result: $passwordOk");
    if (passwordOk) {
      print("Login successful for username: '$username'");
      // Di aplikasi nyata, Anda akan membuat token JWT di sini
      return Response.ok(jsonEncode({
        'message': 'Login successful',
        // Kirim data user lain jika perlu (kecuali password)
        'user': {
          'id': map['id'],
          'username': map['username'],
          'jk': map['jk'],
          'tanggal_lahir': map['tanggal_lahir']
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
  } on MySQLServerException catch (e) {
    print("[Login Error - MySQL]: ${e.message} (Code: ${e.errorCode})");
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

Future<Response> updateProfileHandler(Request req, String id) async {
  try {
    final userId = int.tryParse(id);
    if (userId == null) {
      return Response(400, body: jsonEncode({'error': 'Invalid user ID'}));
    }
    final bodyString = await req.readAsString();
    if (bodyString.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Request body is empty'}));
    }
    final body = jsonDecode(bodyString);
    final newUsername = body['username'] as String?;
    if (newUsername == null || newUsername.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Username is required'}));
    }
    await dbService.updateUser(userId: userId, username: newUsername);
    return Response.ok(jsonEncode({'message': 'Profile updated successfully'}));
  } catch (e) {
    print('[UpdateProfile Error]: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error updating profile'}),
    );
  }
}

Future<Response> updatePasswordHandler(Request req, String id) async {
  try {
    final userId = int.tryParse(id);
    if (userId == null) {
      return Response(400, body: jsonEncode({'error': 'Invalid user ID'}));
    }
    final bodyString = await req.readAsString();
    if (bodyString.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Request body is empty'}));
    }
    final body = jsonDecode(bodyString);
    final oldPassword = body['oldPassword'] as String?;
    final newPassword = body['newPassword'] as String?;
    if (oldPassword == null || newPassword == null || newPassword.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Old and new passwords are required'}));
    }
    // Verify old password
    final result = await dbService.getUserById(userId);
    if (result.rows.isEmpty) {
      return Response(404, body: jsonEncode({'error': 'User not found'}));
    }
    final map = result.rows.first.assoc();
    final storedHashed = map['password'] as String;
    final isMatch = BCrypt.checkpw(oldPassword, storedHashed);
    if (!isMatch) {
      return Response(401, body: jsonEncode({'error': 'Old password is incorrect'}));
    }
    // Hash new password and update
    final hashedNew = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await dbService.updateUser(userId: userId, password: hashedNew);
    return Response.ok(jsonEncode({'message': 'Password updated successfully'}));
  } catch (e) {
    print('[UpdatePassword Error]: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error updating password'}),
    );
  }
}
