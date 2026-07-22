import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'core_providers.dart';

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(databaseProvider).getPlaylists(user.id);
});

final playlistSongsProvider = FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  return ref.watch(databaseProvider).getPlaylistSongs(playlistId);
});

/// Controller for creating / renaming / deleting playlists and adding songs.
final playlistControllerProvider = Provider<PlaylistController>((ref) => PlaylistController(ref));

class PlaylistController {
  final Ref ref;
  PlaylistController(this.ref);

  Future<void> create(String name) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(databaseProvider).createPlaylist(user.id, name);
    ref.invalidate(playlistsProvider);
  }

  Future<void> rename(String playlistId, String newName) async {
    await ref.read(databaseProvider).renamePlaylist(playlistId, newName);
    ref.invalidate(playlistsProvider);
    ref.invalidate(playlistSongsProvider(playlistId));
  }

  Future<void> delete(String playlistId) async {
    await ref.read(databaseProvider).deletePlaylist(playlistId);
    ref.invalidate(playlistsProvider);
  }

  Future<void> addSong(String playlistId, String songId) async {
    await ref.read(databaseProvider).addToPlaylist(playlistId, songId);
    ref.invalidate(playlistSongsProvider(playlistId));
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await ref.read(databaseProvider).removeFromPlaylist(playlistId, songId);
    ref.invalidate(playlistSongsProvider(playlistId));
  }

  /// Fetch a playlist by ID (for deep-link: anyone can view a shared playlist).
  Future<Playlist?> getPlaylistById(String id) async {
    return ref.read(databaseProvider).getPlaylistById(id);
  }
}
