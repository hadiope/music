import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/local_song.dart';

/// Scans device storage for audio files, extracts metadata, and caches
/// results in a local SQLite database for fast access.
class LocalMusicService {
  static final LocalMusicService _instance = LocalMusicService._();
  factory LocalMusicService() => _instance;
  LocalMusicService._();

  Database? _db;
  bool _isScanning = false;

  // Callbacks for real-time scan progress
  VoidCallback? onScanStart;
  VoidCallback? onScanComplete;
  ValueChanged<int>? onSongFound;

  /// Initialize the database (call once at app startup).
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'local_music.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT DEFAULT 'Unknown',
            album TEXT DEFAULT '',
            file_path TEXT NOT NULL,
            size_bytes INTEGER DEFAULT 0,
            album_art_path TEXT DEFAULT '',
            duration_ms INTEGER DEFAULT 0,
            genre TEXT DEFAULT '',
            is_favorite INTEGER DEFAULT 0,
            last_played INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_songs_local (
            playlist_id INTEGER NOT NULL,
            song_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, song_id)
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_songs_artist ON songs(artist)
        ''');
        await db.execute('''
          CREATE INDEX idx_songs_album ON songs(album)
        ''');
        await db.execute('''
          CREATE INDEX idx_songs_fav ON songs(is_favorite)
        ''');
      },
    );
  }

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'local_music.db');
    return openDatabase(dbPath, version: 1);
  }

  /// Request storage permissions (Android).
  Future<bool> requestPermission() async {
    PermissionStatus status = await Permission.audio.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      try {
        status = await Permission.manageExternalStorage.request();
      } catch (_) {}
    }
    return status.isGranted;
  }

  /// Scan directories for audio files and store in SQLite.
  /// Returns the number of new songs found.
  Future<int> scanDevice({bool force = false}) async {
    if (_isScanning) return 0;
    _isScanning = true;
    onScanStart?.call();

    try {
      final granted = await requestPermission();
      if (!granted) {
        _isScanning = false;
        return 0;
      }

      // Common music directories on Android
      final roots = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Sounds',
        '/storage/emulated/0/Recordings',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/',
      ];

      // Also try to find SD card paths
      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          await for (final e in storageDir.list()) {
            if (e is Directory) {
              final name = p.basename(e.path);
              if (name == 'emulated' || name == 'self') continue;
              if (RegExp(r'^[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}$').hasMatch(name)) {
                roots.addAll([
                  '${e.path}/Music',
                  '${e.path}/Download',
                  e.path,
                ]);
              }
            }
          }
        }
      } catch (_) {}

      // Extensions to scan
      const extensions = {'.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg', '.wma', '.opus'};

      final database = await db;
      int newSongs = 0;

      // Get existing file paths to avoid re-processing
      final existingPaths = (await database.query('songs'))
          .map((r) => r['file_path'] as String)
          .toSet();

      for (final root in roots) {
        final dir = Directory(root);
        try {
          if (!await dir.exists()) continue;
        } catch (_) {
          continue;
        }

        try {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is! File) continue;
            final ext = p.extension(entity.path).toLowerCase();
            if (!extensions.contains(ext)) continue;

            if (force || !existingPaths.contains(entity.path)) {
              final song = await _extractMetadata(entity);
              if (song != null) {
                await database.insert(
                  'songs',
                  song.toDbMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                newSongs++;
                onSongFound?.call(newSongs);
              }
            }
          }
        } catch (_) {
          // Permission denied on this directory, skip silently
        }
      }

      _isScanning = false;
      onScanComplete?.call();
      return newSongs;
    } catch (e) {
      _isScanning = false;
      debugPrint('Scan error: $e');
      return 0;
    }
  }

  /// Extract metadata from an audio file using basic tag parsing.
  Future<LocalSong?> _extractMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 10) return null;

      final fileName = p.basenameWithoutExtension(file.path);
      final fileSize = await file.length();

      String title = fileName;
      String artist = 'Unknown';
      String album = '';
      String? albumArtPath;
      int? durationMs;

      // ID3v2 tags (MP3)
      if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
        final meta = _parseID3v2(bytes);
        if (meta['title']?.isNotEmpty == true) title = meta['title']!;
        if (meta['artist']?.isNotEmpty == true) artist = meta['artist']!;
        if (meta['album']?.isNotEmpty == true) album = meta['album']!;
        albumArtPath = meta['coverPath'];
      }
      // M4A/MP4 atoms
      else if (bytes.length > 8 &&
          bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
        final meta = _parseMP4(bytes);
        if (meta['title']?.isNotEmpty == true) title = meta['title']!;
        if (meta['artist']?.isNotEmpty == true) artist = meta['artist']!;
        if (meta['album']?.isNotEmpty == true) album = meta['album']!;
      }
      // FLAC
      else if (bytes.length > 4 &&
          bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43) {
        final meta = _parseFlac(bytes);
        if (meta['title']?.isNotEmpty == true) title = meta['title']!;
        if (meta['artist']?.isNotEmpty == true) artist = meta['artist']!;
        if (meta['album']?.isNotEmpty == true) album = meta['album']!;
      }

      // Estimate duration from file size (rough: ~1MB/min for mp3 128kbps)
      if (durationMs == null) {
        if (p.extension(file.path).toLowerCase() == '.mp3') {
          durationMs = (fileSize / 16000 * 1000).toInt(); // ~128kbps
        } else {
          durationMs = (fileSize / 50000 * 1000).toInt(); // ~400kbps
        }
      }

      final id = 'local_${file.path.hashCode}';

      // Save album art to cache
      if (albumArtPath != null) {
        final cacheDir = await getApplicationDocumentsDirectory();
        final artCacheDir = Directory(p.join(cacheDir.path, '.album_art'));
        if (!await artCacheDir.exists()) {
          await artCacheDir.create(recursive: true);
        }
        final destPath = p.join(artCacheDir.path, '$id.jpg');
        try {
          await File(albumArtPath).copy(destPath);
          albumArtPath = destPath;
        } catch (_) {
          albumArtPath = null;
        }
      }

      return LocalSong(
        id: id,
        title: title,
        artist: artist,
        album: album.isNotEmpty ? album : null,
        filePath: file.path,
        sizeBytes: fileSize,
        albumArtPath: albumArtPath,
        durationMs: durationMs,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- ID3v2 Parsing ----
  Map<String, String?> _parseID3v2(List<int> bytes) {
    final result = <String, String?>{'title': null, 'artist': null, 'album': null, 'coverPath': null};
    try {
      final majorVersion = bytes[3];
      final frameSizeBytes = majorVersion == 2 ? 3 : 4;
      final tagSize = _readSyncSafe(bytes, 6, 4);
      var pos = 10;
      final end = (pos + tagSize).clamp(0, bytes.length);

      while (pos + 10 < end) {
        String frameId;
        int frameSize;
        if (majorVersion == 2) {
          frameId = String.fromCharCodes(bytes.sublist(pos, pos + 3));
          frameSize = (bytes[pos + 3] << 16) | (bytes[pos + 4] << 8) | bytes[pos + 5];
          pos += 6;
        } else {
          frameId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
          frameSize = majorVersion == 4
              ? _readSyncSafe(bytes, pos + 4, 4)
              : (bytes[pos + 4] << 24) | (bytes[pos + 5] << 16) | (bytes[pos + 6] << 8) | bytes[pos + 7];
          pos += 10;
        }
        if (frameId == '\x00\x00\x00\x00' || frameSize <= 0 || pos + frameSize > end) break;

        final frameData = bytes.sublist(pos, pos + frameSize);

        if (frameId == 'TIT2' || (majorVersion == 2 && frameId == 'TT2')) {
          result['title'] = _decodeTextFrame(frameData);
        } else if (frameId == 'TPE1' || (majorVersion == 2 && frameId == 'TP1')) {
          result['artist'] = _decodeTextFrame(frameData);
        } else if (frameId == 'TALB' || (majorVersion == 2 && frameId == 'TAL')) {
          result['album'] = _decodeTextFrame(frameData);
        } else if (frameId == 'APIC') {
          // Extract album art
          try {
            // Find the image data start (skip mime type + description)
            int dataStart = 1;
            while (dataStart < frameData.length && frameData[dataStart] != 0) {
              dataStart++;
            }
            dataStart++; // skip null terminator
            // skip picture type byte
            dataStart++;
            // skip description (null-terminated)
            while (dataStart < frameData.length && frameData[dataStart] != 0) {
              dataStart++;
            }
            dataStart++; // skip null terminator

            if (dataStart < frameData.length) {
              final artDir = await getApplicationDocumentsDirectory();
              final artPath = p.join(artDir.path, '.album_art_cache', '${bytes.hashCode}.jpg');
              await Directory(p.dirname(artPath)).create(recursive: true);
              await File(artPath).writeAsBytes(frameData.sublist(dataStart));
              result['coverPath'] = artPath;
            }
          } catch (_) {}
        }

        pos += frameSize;
      }
    } catch (_) {}
    return result;
  }

  // ---- MP4 / M4A Parsing ----
  Map<String, String?> _parseMP4(List<int> bytes) {
    final result = <String, String?>{'title': null, 'artist': null, 'album': null};
    try {
      int pos = 0;
      while (pos + 8 < bytes.length) {
        final atomSize = (bytes[pos] << 24) | (bytes[pos + 1] << 16) | (bytes[pos + 2] << 8) | bytes[pos + 3];
        if (atomSize < 8 || pos + atomSize > bytes.length) break;
        final atomType = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));

        if (atomType == 'moov' || atomType == 'trak' || atomType == 'mdia' || atomType == 'udta' || atomType == 'ilst') {
          pos += 8;
          continue;
        }

        if (atomType == '\xa9nam' || atomType == '\xa9ART' || atomType == '\xa9alb') {
          if (pos + 8 + 16 < bytes.length) {
            final dataAtomStart = pos + 8;
            final dataAtomSize = (bytes[dataAtomStart] << 24) | (bytes[dataAtomStart + 1] << 16) |
                (bytes[dataAtomStart + 2] << 8) | bytes[dataAtomStart + 3];
            if (String.fromCharCodes(bytes.sublist(dataAtomStart + 4, dataAtomStart + 8)) == 'data' &&
                dataAtomSize > 16) {
              final textData = bytes.sublist(dataAtomStart + 16, dataAtomStart + dataAtomSize);
              final text = String.fromCharCodes(textData.where((b) => b != 0)).trim();
              if (atomType == '\xa9nam') result['title'] = text;
              if (atomType == '\xa9ART') result['artist'] = text;
              if (atomType == '\xa9alb') result['album'] = text;
            }
          }
        }
        pos += atomSize;
      }
    } catch (_) {}
    return result;
  }

  // ---- FLAC Parsing ----
  Map<String, String?> _parseFlac(List<int> bytes) {
    final result = <String, String?>{'title': null, 'artist': null, 'album': null};
    try {
      int pos = 4;
      while (pos < bytes.length - 4) {
        final blockType = bytes[pos] & 0x7F;
        final blockSize = (bytes[pos + 1] << 16) | (bytes[pos + 2] << 8) | bytes[pos + 3];
        pos += 4;

        if (blockType == 4) {
          if (pos + 4 > bytes.length) break;
          int vendorLen = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
          pos += 4 + vendorLen;
          if (pos + 4 > bytes.length) break;
          int commentCount = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
          pos += 4;

          for (int i = 0; i < commentCount && pos < bytes.length; i++) {
            if (pos + 4 > bytes.length) break;
            int len = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
            pos += 4;
            if (pos + len > bytes.length) break;
            final comment = String.fromCharCodes(bytes.sublist(pos, pos + len));
            pos += len;
            final eq = comment.indexOf('=');
            if (eq > 0) {
              final key = comment.substring(0, eq).toUpperCase();
              final value = comment.substring(eq + 1);
              if (key == 'TITLE' && result['title'] == null) result['title'] = value;
              if (key == 'ARTIST' && result['artist'] == null) result['artist'] = value;
              if (key == 'ALBUM' && result['album'] == null) result['album'] = value;
            }
          }
        }
        if ((bytes[pos - 4] & 0x80) != 0) break;
      }
    } catch (_) {}
    return result;
  }

  int _readSyncSafe(List<int> bytes, int offset, int count) {
    int result = 0;
    for (int i = 0; i < count; i++) {
      result = (result << 7) | (bytes[offset + i] & 0x7F);
    }
    return result;
  }

  String _decodeTextFrame(List<int> data) {
    if (data.isEmpty) return '';
    int encoding = data[0];
    try {
      if (encoding == 0) {
        return data.sublist(1).where((b) => b != 0).map((b) => String.fromCharCode(b)).join().trim();
      } else if (encoding == 1) {
        return _decodeUtf16(data.sublist(1)).trim();
      } else if (encoding == 2) {
        return _decodeUtf16(data.sublist(1), bigEndian: true).trim();
      } else {
        return String.fromCharCodes(data.sublist(1).where((b) => b != 0)).trim();
      }
    } catch (_) {
      return '';
    }
  }

  String _decodeUtf16(List<int> data, {bool bigEndian = false}) {
    if (data.length < 2) return '';
    if (data[0] == 0xFF && data[1] == 0xFE) bigEndian = false;
    else if (data[0] == 0xFE && data[1] == 0xFF) bigEndian = true;
    final codeUnits = <int>[];
    for (int i = 0; i < data.length - 1; i += 2) {
      int code = bigEndian ? (data[i] << 8) | data[i + 1] : data[i] | (data[i + 1] << 8);
      if (code != 0) codeUnits.add(code);
    }
    return String.fromCharCodes(codeUnits);
  }

  // ---- Query Methods ----

  /// Get all songs from the local database.
  Future<List<LocalSong>> getAllSongs() async {
    final database = await db;
    final rows = await database.query('songs', orderBy: 'title ASC');
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Search local songs by title or artist.
  Future<List<LocalSong>> searchSongs(String query) async {
    final database = await db;
    final q = '%$query%';
    final rows = await database.query(
      'songs',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'title ASC',
    );
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Get distinct artists from local songs.
  Future<List<String>> getArtists() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT DISTINCT artist FROM songs WHERE artist IS NOT NULL AND artist != \'\' ORDER BY artist ASC',
    );
    return rows.map((r) => r['artist'] as String).toList();
  }

  /// Get songs by a specific artist.
  Future<List<LocalSong>> getSongsByArtist(String artist) async {
    final database = await db;
    final rows = await database.query(
      'songs',
      where: 'artist = ?',
      whereArgs: [artist],
      orderBy: 'album ASC, title ASC',
    );
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Get distinct albums from local songs.
  Future<List<MapEntry<String, String>>> getAlbums() async {
    final database = await db;
    final rows = await database.rawQuery(
      'SELECT DISTINCT album, artist FROM songs WHERE album IS NOT NULL AND album != \'\' ORDER BY album ASC',
    );
    return rows.map((r) => MapEntry(r['album'] as String, r['artist'] as String)).toList();
  }

  /// Get songs by album.
  Future<List<LocalSong>> getSongsByAlbum(String album) async {
    final database = await db;
    final rows = await database.query(
      'songs',
      where: 'album = ?',
      whereArgs: [album],
      orderBy: 'title ASC',
    );
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Get favorite songs.
  Future<List<LocalSong>> getFavorites() async {
    final database = await db;
    final rows = await database.query(
      'songs',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Toggle favorite status.
  Future<void> toggleFavorite(String songId) async {
    final database = await db;
    final row = await database.query('songs', where: 'id = ?', whereArgs: [songId]);
    if (row.isNotEmpty) {
      final current = (row.first['is_favorite'] as int?) ?? 0;
      await database.update(
        'songs',
        {'is_favorite': current == 1 ? 0 : 1},
        where: 'id = ?',
        whereArgs: [songId],
      );
    }
  }

  /// Update last played timestamp.
  Future<void> updateLastPlayed(String songId) async {
    final database = await db;
    await database.update(
      'songs',
      {'last_played': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// Get recently played songs.
  Future<List<LocalSong>> getRecentlyPlayed({int limit = 20}) async {
    final database = await db;
    final rows = await database.query(
      'songs',
      where: 'last_played > 0',
      orderBy: 'last_played DESC',
      limit: limit,
    );
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  /// Delete a song from the database.
  Future<void> deleteSong(String songId) async {
    final database = await db;
    await database.delete('songs', where: 'id = ?', whereArgs: [songId]);
  }

  /// Get total song count.
  Future<int> getSongCount() async {
    final database = await db;
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM songs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---- Local Playlists ----

  Future<int> createPlaylist(String name) async {
    final database = await db;
    return database.insert('playlists_local', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final database = await db;
    return database.query('playlists_local', orderBy: 'created_at DESC');
  }

  Future<void> addToPlaylist(int playlistId, String songId) async {
    final database = await db;
    final maxPos = await database.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 as next FROM playlist_songs_local WHERE playlist_id = ?',
      [playlistId],
    );
    final pos = Sqflite.firstIntValue(maxPos) ?? 0;
    await database.insert('playlist_songs_local', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': pos,
    });
  }

  Future<void> removeFromPlaylist(int playlistId, String songId) async {
    final database = await db;
    await database.delete(
      'playlist_songs_local',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<LocalSong>> getPlaylistSongs(int playlistId) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs_local ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.position ASC
    ''', [playlistId]);
    return rows.map((r) => LocalSong.fromDbMap(r)).toList();
  }

  Future<void> deletePlaylist(int playlistId) async {
    final database = await db;
    await database.delete('playlist_songs_local', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await database.delete('playlists_local', where: 'id = ?', whereArgs: [playlistId]);
  }

  /// Clear all cached songs and re-scan.
  Future<void> rescan() async {
    final database = await db;
    await database.delete('songs');
    await scanDevice(force: true);
  }

  /// Get total scan stats.
  Future<Map<String, int>> getStats() async {
    final database = await db;
    final total = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM songs'),
    ) ?? 0;
    final artists = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(DISTINCT artist) FROM songs WHERE artist IS NOT NULL AND artist != \'\''),
    ) ?? 0;
    final albums = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(DISTINCT album) FROM songs WHERE album IS NOT NULL AND album != \'\''),
    ) ?? 0;
    return {'songs': total, 'artists': artists, 'albums': albums};
  }

  void dispose() {
    _db?.close();
    _db = null;
  }
}