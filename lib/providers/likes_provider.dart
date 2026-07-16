import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import 'core_providers.dart';

/// Set of liked song IDs for the current user (or local guest storage).
class LikesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  LikesNotifier(this.ref) : super({}) {
    load();
  }

  Future<void> load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      // guest: read from local prefs
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('guest_likes') ?? [];
      state = list.toSet();
      return;
    }
    final ids = await ref.read(databaseProvider).getLikedSongIds(user.id);
    state = ids.toSet();
  }

  bool isLiked(String songId) => state.contains(songId);

  Future<void> toggle(String songId) async {
    final user = ref.read(currentUserProvider);
    final db = ref.read(databaseProvider);
    final liked = state.contains(songId);
    if (liked) {
      state = {...state}..remove(songId);
    } else {
      state = {...state, songId};
    }
    // Persist
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_likes', state.toList());
    } else {
      try {
        if (liked) {
          await db.unlike(user.id, songId);
        } else {
          await db.like(user.id, songId);
        }
      } catch (_) {
        // ignore DB errors (e.g. RLS) — local state already updated
      }
    }
  }
}

final likesProvider = StateNotifierProvider<LikesNotifier, Set<String>>((ref) => LikesNotifier(ref));

/// Liked songs (full objects).
final likedSongsProvider = FutureProvider<List<Song>>((ref) async {
  ref.watch(likesProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(databaseProvider).getLikedSongs(user.id);
});

/// Play history.
final historyProvider = FutureProvider<List<Song>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(databaseProvider).getHistory(user.id);
});
