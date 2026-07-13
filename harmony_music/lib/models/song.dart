class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String coverUrl;
  final String audioUrl;
  final String? genre;
  final int plays;
  final int? durationMs;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.coverUrl,
    required this.audioUrl,
    this.genre,
    this.plays = 0,
    this.durationMs,
  });

  factory Song.fromMap(Map<String, dynamic> m) => Song(
        id: m['id'].toString(),
        title: m['title'] ?? '',
        artist: m['artist'] ?? '',
        album: m['album'],
        coverUrl: m['cover_url'] ?? '',
        audioUrl: m['audio_url'] ?? '',
        genre: m['genre'],
        plays: m['plays'] ?? 0,
        durationMs: m['duration_ms'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'cover_url': coverUrl,
        'audio_url': audioUrl,
        'genre': genre,
        'plays': plays,
        'duration_ms': durationMs,
      };
}
