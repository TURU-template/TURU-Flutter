// TURU-Flutter/turu_backend/lib/env.dart:

import 'package:dotenv/dotenv.dart';

/// load .env sekali saja, sekaligus merge Platform.environment
final env = DotEnv(includePlatformEnvironment: true)..load();

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
