import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_service/audio_service.dart';
import '../services/database_service.dart';
import '../services/audio_handler.dart';

/// Supabase client provider.
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Database service.
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// Single global audio handler — created once via AudioService.init in main(),
/// then exposed through the provider tree. Using a module-level singleton
/// avoids disposal so music keeps playing across the app lifetime.
AudioPlayerHandler get _sharedHandler {
  _handlerInstance ??= AudioPlayerHandler();
  return _handlerInstance!;
}

AudioPlayerHandler? _handlerInstance;

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  ref.onDispose(() {}); // keep alive for the app lifetime (music keeps playing)
  return _sharedHandler;
});

/// Initialises audio_service with our handler. Call once in main() before
/// runApp. This wires up the background notification + lock-screen controls.
Future<AudioPlayerHandler> initAudioService() async {
  final handler = await AudioService.init(
    builder: () => _sharedHandler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'ir.iranseda.hadi.channel.audio',
      androidNotificationChannelName: 'Iran Seda Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF1DB954),
      artDownscaleSize: 200,
    ),
  );
  return handler as AudioPlayerHandler;
}

/// Auth state stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current user (null if signed out).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});
