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
      useSSL: true, // Karena SSL-mode=REQUIRED di connection string Anda
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

  // Metode untuk cek apakah tabel users ada, jika tidak buat tabel
  Future<void> ensureTablesExist() async {
    final conn = await getConnection();

    // Cek dan buat tabel users jika belum ada
    await conn.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        gender VARCHAR(20),
        birth_date VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // Metode untuk mencari user berdasarkan username
  Future<Results> getUserByUsername(String username) async {
    final conn = await getConnection();
    return await conn.query('SELECT * FROM users WHERE username = ?', [
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
      'INSERT INTO users (username, password, gender, birth_date) VALUES (?, ?, ?, ?)',
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

    String query = 'UPDATE users SET';
    List<Object> params = [];

    if (password != null) {
      query += ' password = ?';
      params.add(password);
    }

    if (gender != null) {
      if (params.isNotEmpty) query += ',';
      query += ' gender = ?';
      params.add(gender);
    }

    if (birthDate != null) {
      if (params.isNotEmpty) query += ',';
      query += ' birth_date = ?';
      params.add(birthDate);
    }

    query += ' WHERE id = ?';
    params.add(userId);

    return await conn.query(query, params);
  }
}
