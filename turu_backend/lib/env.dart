// TURU-Flutter/turu_backend/lib/env.dart:

import 'package:dotenv/dotenv.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// load .env sekali saja, sekaligus merge Platform.environment
String _findEnvFile() {
  var dir = Directory.current;
  while (true) {
    final candidate = File(p.join(dir.path, '.env'));
    if (candidate.existsSync()) {
      return candidate.path;
    }
    if (dir.parent.path == dir.path) {
      break;
    }
    dir = dir.parent;
  }
  throw Exception('.env file not found in any parent directories');
}

final env = DotEnv(includePlatformEnvironment: true)
  ..load([_findEnvFile()]);

// --- TAMBAHKAN DEBUG PRINT DI SINI ---
void printEnvVariables() {
  print("DATABASE_URL from env: ${env['DATABASE_URL']}");
  print("--- Reading .env variables ---");
  print("DB_HOST from env: ${env['DB_HOST']}");
  print("DB_PORT from env: ${env['DB_PORT']}");
  print("DB_USER from env: ${env['DB_USER']}");
  // Jangan print password di log produksi, tapi boleh untuk debug sementara
  // print("DB_PASS from env: ${env['DB_PASS']}");
  print("DB_NAME from env: ${env['DB_NAME']}");
  print("--- Finished reading .env ---");
}
// --- AKHIR TAMBAHAN DEBUG PRINT ---
