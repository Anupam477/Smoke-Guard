import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (graceful fallback if demo keys are present)
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: SmokeGuardApp(),
    ),
  );
}
