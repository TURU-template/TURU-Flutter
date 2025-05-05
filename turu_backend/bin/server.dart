// TURU-Flutter/turu_backend/bin/server.dart:

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/env.dart'; // Import env.dart
// <-- TAMBAHKAN IMPORT handlers JIKA BELUM ADA -->
import '../lib/handlers.dart';

void main() async {
  // <-- PANGGIL DEBUG PRINT DI SINI -->
  printEnvVariables(); // Cetak variabel env segera setelah dimuat

  // --- Konfigurasi CORS ---
  final Map<String, String> corsDefaultHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
    'Access-Control-Allow-Headers':
        'Origin, Content-Type, X-Requested-With, Accept, Authorization',
  };

  // --- Router ---
  final router = Router()
    ..get('/', (Request req) => Response.ok('TURU Backend is up!'))
    ..post('/register', registerHandler)
    ..post('/login', loginHandler)
    ..put('/user/<id|[0-9]+>', updateProfileHandler)
    ..put('/user/<id|[0-9]+>/password', updatePasswordHandler);

  // --- Pipeline ---
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: corsDefaultHeaders))
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // --- Jalankan Server ---
  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
  print('CORS Middleware enabled with headers:');
  corsDefaultHeaders.forEach((key, value) => print('  $key: $value'));
}
