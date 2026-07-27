import 'song.dart';

/// A song found on the device's local storage.
/// Extends [Song] so it can be used interchangeably with streamed songs.
class LocalSong extends Song {
  final String filePath;
  final int sizeBytes;
  final String? albumArtPath;
  final bool isFavorite;

  LocalSong({
    required super.id,
    required super.title,
    super.artist = 'Unknown',
    super.album,
    super.coverUrl = '',
    required this.filePath,
    this.sizeBytes = 0,
    this.albumArtPath,
    this.isFavorite = false,
    super.durationMs,
    super.genre,
  }) : super(audioUrl: filePath);

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album ?? '',
        'file_path': filePath,
        'size_bytes': sizeBytes,
        'album_art_path': albumArtPath ?? '',
        'duration_ms': durationMs ?? 0,
        'genre': genre ?? '',
        'is_favorite': isFavorite ? 1 : 0,
        'last_played': DateTime.now().millisecondsSinceEpoch,
      };

  factory LocalSong.fromDbMap(Map<String, dynamic> m) => LocalSong(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        artist: m['artist'] as String? ?? 'Unknown',
        album: m['album'] as String?,
        filePath: m['file_path'] as String? ?? '',
        sizeBytes: m['size_bytes'] as int? ?? 0,
        albumArtPath: m['album_art_path'] as String?,
        durationMs: m['duration_ms'] as int?,
        genre: m['genre'] as String?,
        isFavorite: (m['is_favorite'] as int? ?? 0) == 1,
      );

  LocalSong copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    int? sizeBytes,
    String? albumArtPath,
    int? durationMs,
    String? genre,
    bool? isFavorite,
  }) =>
      LocalSong(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        filePath: filePath ?? this.filePath,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        albumArtPath: albumArtPath ?? this.albumArtPath,
        durationMs: durationMs ?? this.durationMs,
        genre: genre ?? this.genre,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}