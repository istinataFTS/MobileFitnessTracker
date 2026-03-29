import 'dart:async';
import 'dart:io';

import 'package:fitness_tracker/core/errors/sync_exceptions.dart';
import 'package:fitness_tracker/data/datasources/remote/remote_datasource_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('RemoteDatasourceGuard', () {
    group('happy path', () { ... }
    group('pass-through for already-typed sync exceptions', () { ... }
    group('Supabase AuthException mapping', () { ... }
    group('Supabase PostgrestException mapping', () { ... }
    group('SocketException mapping', () { ... }
    group('TimeoutException mapping', () { ... }
    group('unhandled exception propagation', () { ... }
  });
}
