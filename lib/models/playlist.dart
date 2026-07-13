class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? coverUrl;

  Playlist({
    required this.id,
    required this.userId,
    required this.name,
    this.coverUrl,
  });

  factory Playlist.fromMap(Map<String, dynamic> m) => Playlist(
        id: m['id'].toString(),
        userId: m['user_id'].toString(),
        name: m['name'] ?? '',
        coverUrl: m['cover_url'],
      );
}
