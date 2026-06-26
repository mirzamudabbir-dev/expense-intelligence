import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

import 'dart:developer' as developer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    developer.log(
      'CRITICAL ERROR: Supabase environment variables are missing.',
      name: 'EnvValidation',
      error: 'SUPABASE_URL or SUPABASE_ANON_KEY is not defined. Ensure you are passing them via --dart-define or --dart-define-from-file.',
    );
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Please pass them using --dart-define.');
  }

  if (!supabaseUrl.startsWith('http://') && !supabaseUrl.startsWith('https://')) {
    developer.log(
      'CRITICAL ERROR: Supabase URL must be an absolute URL.',
      name: 'EnvValidation',
      error: 'Invalid URL: "$supabaseUrl". It must start with http:// or https://',
    );
    throw Exception('Invalid SUPABASE_URL: "$supabaseUrl". Must be absolute (starting with http:// or https://).');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: App()));
}
