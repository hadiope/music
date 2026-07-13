import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/banner.dart' as m;

/// All database reads/writes against Supabase.
class DatabaseService {
  final SupabaseClient _db = Supabase.instance.client;

  // ---------- Songs ----------
  Future<List<Song>> getSongs({int limit = 50}) async {
    final res = await _db.from('songs').select().order('created_at', ascending: false).limit(limit);
    return (res as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<List<Song>> getNewReleases({int limit = 10}) async {
    final res = await _db.from('songs').select().order('created_at', ascending: false).limit(limit);
    return (res as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<List<Song>> getPopular({int limit = 10}) async {
    final res = await _db.from('songs').select().order('plays', ascending: false).limit(limit);
    return (res as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<List<Song>> getByGenre(String genre) async {
    final res = await _db.from('songs').select().eq('genre', genre).order('plays', ascending: false);
    return (res as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<List<String>> getGenres() async {
    final res = await _db.from('songs').select('genre');
    final set = <String>{};
    for (final row in (res as List)) {
      if (row['genre'] != null && (row['genre'] as String).isNotEmpty) set.add(row['genre']);
    }
    return set.toList();
  }

  Future<List<Song>> search(String q) async {
    final res = await _db
        .from('songs')
        .select()
        .or('title.ilike.%$q%,artist.ilike.%$q%')
        .limit(50);
    return (res as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<void> incrementPlays(String songId) async {
    await _db.rpc('increment_plays', params: {'song_id': songId});
  }

  // ---------- Albums ----------
  Future<List<Album>> getAlbums({int limit = 20}) async {
    final res = await _db.from('albums').select().limit(limit);
    return (res as List).map((e) => Album.fromMap(e)).toList();
  }

  // ---------- Banners ----------
  Future<List<m.Banner>> getBanners() async {
    final res = await _db.from('banners').select().eq('active', true);
    return (res as List).map((e) => m.Banner.fromMap(e)).toList();
  }

  // ---------- Likes ----------
  Future<List<String>> getLikedSongIds(String userId) async {
    final res = await _db.from('likes').select('song_id').eq('user_id', userId);
    return (res as List).map((e) => e['song_id'].toString()).toList();
  }

  Future<List<Song>> getLikedSongs(String userId) async {
    final res = await _db.from('likes').select('songs(*)').eq('user_id', userId);
    return (res as List).where((e) => e['songs'] != null).map((e) => Song.fromMap(e['songs'])).toList();
  }

  Future<void> like(String userId, String songId) async {
    await _db.from('likes').insert({'user_id': userId, 'song_id': songId});
  }

  Future<void> unlike(String userId, String songId) async {
    await _db.from('likes').delete().match({'user_id': userId, 'song_id': songId});
  }

  // ---------- Playlists ----------
  Future<List<Playlist>> getPlaylists(String userId) async {
    final res = await _db.from('playlists').select().eq('user_id', userId);
    return (res as List).map((e) => Playlist.fromMap(e)).toList();
  }

  Future<Playlist> createPlaylist(String userId, String name) async {
    final res = await _db.from('playlists').insert({'user_id': userId, 'name': name}).select().single();
    return Playlist.fromMap(res);
  }

  Future<void> addToPlaylist(String playlistId, String songId) async {
    await _db.from('playlist_songs').insert({'playlist_id': playlistId, 'song_id': songId});
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final res = await _db.from('playlist_songs').select('songs(*)').eq('playlist_id', playlistId);
    return (res as List).where((e) => e['songs'] != null).map((e) => Song.fromMap(e['songs'])).toList();
  }

  // ---------- History ----------
  Future<void> addHistory(String userId, String songId) async {
    await _db.from('play_history').upsert(
      {'user_id': userId, 'song_id': songId, 'played_at': DateTime.now().toIso8601String()},
      onConflict: 'user_id,song_id',
    );
  }

  Future<List<Song>> getHistory(String userId) async {
    final res = await _db
        .from('play_history')
        .select('songs(*)')
        .eq('user_id', userId)
        .order('played_at', ascending: false)
        .limit(30);
    return (res as List).where((e) => e['songs'] != null).map((e) => Song.fromMap(e['songs'])).toList();
  }
}
