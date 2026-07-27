import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_music_service.dart';
import '../models/local_song.dart';

/// LocalMusicService provider - singleton
final localMusicServiceProvider = Provider<LocalMusicService>((ref) {
  final service = LocalMusicService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// All local songs
final allLocalSongsProvider = FutureProvider<List<LocalSong>>((ref) async {
  return ref.watch(localMusicServiceProvider).getAllSongs();
});

/// Local artists
final localArtistsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(localMusicServiceProvider).getArtists();
});

/// Local albums (album name -> artist name)
final localAlbumsProvider = FutureProvider<List<MapEntry<String, String>>>((ref) async {
  return ref.watch(localMusicServiceProvider).getAlbums();
});

/// Local favorites
final localFavoritesProvider = FutureProvider<List<LocalSong>>((ref) async {
  return ref.watch(localMusicServiceProvider).getFavorites();
});

/// Local stats
final localStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(localMusicServiceProvider).getStats();
});

/// Recently played local songs
final localRecentProvider = FutureProvider<List<LocalSong>>((ref) async {
  return ref.watch(localMusicServiceProvider).getRecentlyPlayed(limit: 20);
});

/// Search local songs
final localSearchQueryProvider = StateProvider<String>((ref) => '');

final localSearchResultsProvider = FutureProvider<List<LocalSong>>((ref) async {
  final query = ref.watch(localSearchQueryProvider).trim();
  if (query.isEmpty) return [];
  return ref.watch(localMusicServiceProvider).searchSongs(query);
});

/// Controller for local music actions
final localMusicControllerProvider = Provider<LocalMusicController>((ref) => LocalMusicController(ref));

class LocalMusicController {
  final Ref ref;

  LocalMusicController(this.ref);

  /// Trigger a full device scan
  Future<int> scanDevice({bool force = false}) async {
    return ref.read(localMusicServiceProvider).scanDevice(force: force);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String songId) async {
    await ref.read(localMusicServiceProvider).toggleFavorite(songId);
    ref.invalidate(localFavoritesProvider);
    ref.invalidate(allLocalSongsProvider);
  }

  /// Play a local song
  Future<void> playSong(LocalSong song, {List<LocalSong>? queue, int index = 0}) async {
    final handler = ref.read(audioHandlerProvider);
    final songs = (queue ?? [song]).map((s) => s.toSong()).toList();
    await handler.setQueueSafe(songs, startIndex: index);
  }

  /// Delete a song from local database
  Future<void> deleteSong(String songId) async {
    await ref.read(localMusicServiceProvider).deleteSong(songId);
    ref.invalidate(allLocalSongsProvider);
    ref.invalidate(localArtistsProvider);
    ref.invalidate(localAlbumsProvider);
    ref.invalidate(localFavoritesProvider);
    ref.invalidate(localStatsProvider);
  }

  /// Create a local playlist
  Future<int> createPlaylist(String name) async {
    return ref.read(localMusicServiceProvider).createPlaylist(name);
  }

  /// Get local playlists
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    return ref.read(localMusicServiceProvider).getPlaylists();
  }

  /// Add song to local playlist
  Future<void> addToPlaylist(int playlistId, String songId) async {
    await ref.read(localMusicServiceProvider).addToPlaylist(playlistId, songId);
  }

  /// Remove song from local playlist
  Future<void> removeFromPlaylist(int playlistId, String songId) async {
    await ref.read(localMusicServiceProvider).removeFromPlaylist(playlistId, songId);
  }

  /// Get local playlist songs
  Future<List<LocalSong>> getPlaylistSongs(int playlistId) async {
    return ref.read(localMusicServiceProvider).getPlaylistSongs(playlistId);
  }

  /// Delete local playlist
  Future<void> deletePlaylist(int playlistId) async {
    await ref.read(localMusicServiceProvider).deletePlaylist(playlistId);
  }
}

extension LocalSongToSong on LocalSong {
  Song toSong() => Song(
        id: id,
        title: title,
        artist: artist,
        album: album,
        coverUrl: albumArtPath ?? '',
        audioUrl: filePath,
        durationMs: durationMs,
        genre: genre,
        plays: 0,
      );
}