class GenreItem {
  final String name;
  final String imageUrl;
  const GenreItem(this.name, this.imageUrl);
}

/// Iranian music categories with representative cover images.
/// Images use picsum (royalty-free placeholders) — replace with your own art.
/// Cleaned per request: removed فولک، الکترونیک، ترنس، جاز، بلوز، متال; راپ→رپ.
const List<GenreItem> genresList = [
  GenreItem('پاپ', 'https://picsum.photos/seed/pop/400/400'),
  GenreItem('رپ', 'https://picsum.photos/seed/rap/400/400'),
  GenreItem('سنتی', 'https://picsum.photos/seed/traditional/400/400'),
  GenreItem('هیپ‌هاپ', 'https://picsum.photos/seed/hiphop/400/400'),
  GenreItem('راک', 'https://picsum.photos/seed/rock/400/400'),
  GenreItem('کلاسیک', 'https://picsum.photos/seed/classical/400/400'),
];
