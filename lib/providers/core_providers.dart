import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../services/audio_handler.dart';

/// Supabase client provider.
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Database service.
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// Single global audio handler — lazy singleton so it is always initialized
/// exactly once and never throws LateInitializationError when a screen reads
/// it before playback has started.
final AudioPlayerHandler _sharedHandler = AudioPlayerHandler();

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  ref.onDispose(() {}); // keep alive for the app lifetime (music keeps playing)
  return _sharedHandler;
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
