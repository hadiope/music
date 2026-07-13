import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../services/audio_handler.dart';

/// Supabase client provider.
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Database service.
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// Single global audio handler.
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  final h = AudioPlayerHandler();
  ref.onDispose(() => h.dispose());
  return h;
});

/// Auth state stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current user (null if signed out).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});
