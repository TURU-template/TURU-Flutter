// TURU-Flutter/turu_backend/lib/db.dart:

import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'env.dart';

class DatabaseService {
  MySqlConnection? _connection;
  ConnectionSettings? _settings;

  // Method untuk mendapatkan settings koneksi
  Future<ConnectionSettings> _getConnectionSettings() async {
    // Path ke sertifikat CA (tetap diperlukan jika useSSL true dan server mewajibkannya)
    final caCertPath = 'cert/ca.pem';
    bool caFileExists = await File(caCertPath).exists();

    if (caFileExists) {
      print(
          "Info: CA Certificate file found at $caCertPath. SSL connection will attempt validation.");
    } else {
      print("Warning: CA Certificate file not found at $caCertPath.");
      print(
          "Warning: If Aiven requires a specific CA for SSL, connection might fail or be insecure.");
    }

    // --- MODIFIKASI DIMULAI DI BAWAH INI ---
    return ConnectionSettings(
      host: env['DB_HOST']!,
      port: int.parse(env['DB_PORT']!),
      user: env['DB_USER']!,
      password: env['DB_PASS']!,
      db: env['DB_NAME']!,
      useSSL: true, // Tetap true karena Aiven mewajibkan

      // --- TAMBAHAN: Nonaktifkan kompresi ---
      useCompression: false,

      // --- TAMBAHAN: Opsi untuk skip verifikasi SSL (Hanya untuk Debug!) ---
      // Jika error 'packets out of order' masih ada, coba HAPUS tanda komentar '//'
      // pada baris di bawah ini untuk tes. JANGAN gunakan di produksi!
      // skipServerVerification: true,

      // --- PERUBAHAN: Naikkan timeout ---
      timeout: const Duration(seconds: 45), // Naikkan dari 30 ke 45 detik
    );
    // --- MODIFIKASI SELESAI DI ATAS INI ---
  }

  Future<MySqlConnection> getConnection() async {
    // Jika sudah ada koneksi, coba ping atau query sederhana untuk cek validitas
    if (_connection != null) {
      try {
        // Coba query sederhana untuk memastikan koneksi masih hidup
        await _connection!.query('SELECT 1');
        // Jika berhasil, kembalikan koneksi yang ada
        return _connection!;
      } catch (e) {
        print("Existing connection check failed: $e. Reconnecting...");
        // Jika gagal, tutup koneksi lama (jika bisa) dan buat baru
        await closeConnection();
      }
    }

    // Jika belum ada settings, buat dulu
    _settings ??= await _getConnectionSettings();

    print("Attempting to connect to database...");
    try {
      _connection = await MySqlConnection.connect(_settings!);
      print("Database connection successful!");
      // Langsung panggil ensureTablesExist setelah koneksi berhasil dibuat
      // Pastikan ensureTablesExist tidak memanggil getConnection lagi untuk hindari loop
      await _ensureTablesExistInternal();
      return _connection!;
    } catch (e) {
      print("Error connecting to database: $e");
      _connection = null; // Set koneksi ke null jika gagal
      rethrow; // Lemparkan kembali error
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null) {
      try {
        // Tidak ada cara langsung cek 'connected', langsung coba close
        await _connection!.close();
        print("Database connection closed.");
      } catch (e) {
        print("Error closing connection (might already be closed): $e");
      } finally {
        _connection = null;
      }
    }
  }

  // Fungsi internal untuk memastikan tabel ada, dipanggil setelah koneksi dipastikan ada
  Future<void> _ensureTablesExistInternal() async {
    if (_connection == null) {
      print("Cannot ensure tables exist: Connection is null.");
      throw Exception(
          "Database connection is not available to ensure tables exist.");
    }
    print("Ensuring 'pengguna' table exists...");
    try {
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS pengguna (
          id INT AUTO_INCREMENT PRIMARY KEY,
          username VARCHAR(50) UNIQUE NOT NULL,
          password VARCHAR(255) NOT NULL,
          jk CHAR(1) NULL,
          tanggal_lahir DATE NULL,
          state INT DEFAULT 1
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
      ''');
      print("'pengguna' table ensured.");
    } catch (e) {
      print("Error ensuring 'pengguna' table: $e");
      // Jika error terjadi di sini, koneksi mungkin bermasalah
      // Pertimbangkan untuk menutup koneksi atau menandainya sebagai tidak valid
      await closeConnection();
      rethrow;
    }
  }

  // Wrapper publik jika diperlukan, tapi lebih aman dipanggil internal setelah connect
  Future<void> ensureTablesExist() async {
    // Panggil getConnection untuk memastikan koneksi ada dan valid
    await getConnection();
    // Jika getConnection berhasil, _ensureTablesExistInternal sudah dipanggil
  }

  Future<Results> getUserByUsername(String username) async {
    // Selalu dapatkan koneksi yang valid sebelum query
    final conn = await getConnection();
    try {
      return await conn.query(
          'SELECT id, username, password, jk, tanggal_lahir FROM pengguna WHERE username = ?',
          [username]);
    } catch (e) {
      print("Error getting user by username '$username': $e");
      // Pertimbangkan menutup koneksi jika error query terjadi
      await closeConnection();
      rethrow;
    }
  }

  Future<Results> createUser({
    required String username,
    required String password, // hash
    String? gender,
    String? birthDate, // YYYY-MM-DD
  }) async {
    // Selalu dapatkan koneksi yang valid sebelum query
    final conn = await getConnection();
    String? formattedBirthDate = birthDate;
    String? genderCode =
        gender?.isNotEmpty == true ? gender![0].toUpperCase() : null;
    if (genderCode != 'L' && genderCode != 'P') genderCode = null;

    try {
      return await conn.query(
        'INSERT INTO pengguna (username, password, jk, tanggal_lahir, state) VALUES (?, ?, ?, ?, DEFAULT)',
        [username, password, genderCode, formattedBirthDate],
      );
    } catch (e) {
      print("Error creating user '$username': $e");
      // Jika error duplicate entry (kode 1062), lempar exception spesifik
      if (e is MySqlException && e.errorNumber == 1062) {
        throw Exception('Username already exists');
      }
      // Pertimbangkan menutup koneksi jika error query terjadi
      await closeConnection();
      rethrow;
    }
  }

  // Fungsi updateUser tidak diubah secara signifikan, tapi tambahkan getConnection()
  Future<Results> updateUser({
    required int userId,
    String? password, // hash
    String? gender,
    String? birthDate,
  }) async {
    // Selalu dapatkan koneksi yang valid sebelum query
    final conn = await getConnection();
    var sql = StringBuffer('UPDATE pengguna SET ');
    var params = <Object>[];
    String? genderCode =
        gender?.isNotEmpty == true ? gender![0].toUpperCase() : null;
    if (genderCode != 'L' && genderCode != 'P') genderCode = null;

    if (password != null) {
      sql.write('password = ?');
      params.add(password);
    }
    if (genderCode != null) {
      if (params.isNotEmpty) sql.write(', ');
      sql.write('jk = ?');
      params.add(genderCode);
    }
    if (birthDate != null) {
      if (params.isNotEmpty) sql.write(', ');
      sql.write('tanggal_lahir = ?');
      params.add(birthDate);
    }

    if (params.isEmpty) {
      print(
          "Warning: updateUser called for user ID $userId with no fields to update.");
      // Mungkin return hasil kosong atau throw error?
      // return Results([], 0, []); // Contoh return kosong
      throw ArgumentError("No fields provided to update.");
    }

    sql.write(' WHERE id = ?');
    params.add(userId);

    try {
      return await conn.query(sql.toString(), params);
    } catch (e) {
      print("Error updating user ID $userId: $e");
      // Pertimbangkan menutup koneksi jika error query terjadi
      await closeConnection();
      rethrow;
    }
  }
}
