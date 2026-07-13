class Album {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final int? year;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.year,
  });

  factory Album.fromMap(Map<String, dynamic> m) => Album(
        id: m['id'].toString(),
        title: m['title'] ?? '',
        artist: m['artist'] ?? '',
        coverUrl: m['cover_url'] ?? '',
        year: m['year'],
      );
}
