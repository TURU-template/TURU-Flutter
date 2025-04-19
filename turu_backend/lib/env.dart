// lib/env.dart
import 'package:dotenv/dotenv.dart';

/// load .env sekali saja, sekaligus merge Platform.environment
final env = DotEnv(includePlatformEnvironment: true)..load();
