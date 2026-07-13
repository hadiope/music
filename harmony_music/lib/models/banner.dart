class Banner {
  final String id;
  final String imageUrl;
  final String? link;
  final bool active;

  Banner({
    required this.id,
    required this.imageUrl,
    this.link,
    this.active = true,
  });

  factory Banner.fromMap(Map<String, dynamic> m) => Banner(
        id: m['id'].toString(),
        imageUrl: m['image_url'] ?? '',
        link: m['link'],
        active: m['active'] ?? true,
      );
}
