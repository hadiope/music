import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../services/audio_handler.dart';

/// Supabase client provider.
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Database service.
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// Single global audio handler — lazy singleton so it is created on first
/// access (after JustAudioBackground.init has run in main()) and never throws
/// LateInitializationError when a screen reads it before playback starts.
AudioPlayerHandler get _sharedHandler {
  _handlerInstance ??= AudioPlayerHandler();
  return _handlerInstance!;
}

AudioPlayerHandler? _handlerInstance;

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
