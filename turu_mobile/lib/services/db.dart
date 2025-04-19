import 'package:mysql1/mysql1.dart';

class DatabaseService {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  MySqlConnection? _connection;

  DatabaseService({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  Future<MySqlConnection> getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    final settings = ConnectionSettings(
      host: host,
      port: port,
      user: username,
      password: password,
      db: database,
      useSSL: false, // Changed to false for local development
    );

    try {
      _connection = await MySqlConnection.connect(settings);
      return _connection!;
    } catch (e) {
      throw Exception('Failed to connect to database: ${e.toString()}');
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  // Metode untuk memastikan koneksi bisa terbentuk
  Future<void> ensureTablesExist() async {
    final conn = await getConnection();

    // Create tables if they don't exist
    await conn.query('''
      CREATE TABLE IF NOT EXISTS pengguna (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        jk CHAR(1),
        tangga_lahir VARCHAR(20),
        state INT DEFAULT 0
      )
    ''');
  }

  // Metode untuk mencari user berdasarkan username
  Future<Results> getUserByUsername(String username) async {
    final conn = await getConnection();
    return await conn.query('SELECT * FROM pengguna WHERE username = ?', [
      username,
    ]);
  }

  // Metode untuk menambah user baru
  Future<Results> createUser({
    required String username,
    required String password,
    String? gender,
    String? birthDate,
  }) async {
    final conn = await getConnection();
    return await conn.query(
      'INSERT INTO pengguna (username, password, jk, tangga_lahir, state) VALUES (?, ?, ?, ?, 0)',
      [username, password, gender, birthDate],
    );
  }

  // Metode untuk memperbarui data user
  Future<Results> updateUser({
    required int userId,
    String? password,
    String? gender,
    String? birthDate,
  }) async {
    final conn = await getConnection();

    String query = 'UPDATE pengguna SET';
    List<Object> params = [];

    if (password != null) {
      query += ' password = ?';
      params.add(password);
    }

    if (gender != null) {
      if (params.isNotEmpty) query += ',';
      query += ' jk = ?';
      params.add(gender);
    }

    if (birthDate != null) {
      if (params.isNotEmpty) query += ',';
      query += ' tangga_lahir = ?';
      params.add(birthDate);
    }

    query += ' WHERE id = ?';
    params.add(userId);

    return await conn.query(query, params);
  }
}
