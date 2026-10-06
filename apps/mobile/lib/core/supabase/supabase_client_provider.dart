import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

@Deprecated('Supabase removed; kept for compatibility.')
Future<void> initializeSupabaseIfConfigured() async {}

@Deprecated('Supabase removed; kept for compatibility.')
final supabaseClientProvider = Provider<Object?>((ref) => null);

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAccountEmailProvider).value;
});

@Deprecated('Supabase removed; kept for compatibility.')
final supabaseAuthStateChangesProvider = Provider<Stream<Object?>?>((ref) => null);
