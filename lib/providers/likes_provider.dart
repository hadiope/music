import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'core_providers.dart';

/// Set of liked song IDs for the current user.
class LikesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  LikesNotifier(this.ref) : super({}) {
    load();
  }

  Future<void> load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final ids = await ref.read(databaseProvider).getLikedSongIds(user.id);
    state = ids.toSet();
  }

  bool isLiked(String songId) => state.contains(songId);

  Future<void> toggle(String songId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final db = ref.read(databaseProvider);
    if (state.contains(songId)) {
      await db.unlike(user.id, songId);
      state = {...state}..remove(songId);
    } else {
      await db.like(user.id, songId);
      state = {...state, songId};
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
