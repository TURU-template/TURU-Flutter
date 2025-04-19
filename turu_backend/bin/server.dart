// TURU-Flutter/turu_backend/bin/server.dart:
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';

import '../lib/env.dart'; // ← import env
import '../lib/handlers.dart'; // ← handler login/register

void main() async {
  final router = Router()
    ..post('/register', registerHandler)
    ..post('/login', loginHandler);

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
}
