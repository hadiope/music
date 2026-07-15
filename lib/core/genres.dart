class GenreItem {
  final String name;
  final String imageUrl;
  const GenreItem(this.name, this.imageUrl);
}

/// Iranian music categories with representative cover images.
/// Images use picsum (royalty-free placeholders) — replace with your own art.
const List<GenreItem> genresList = [
  GenreItem('پاپ', 'https://picsum.photos/seed/pop/400/400'),
  GenreItem('راپ', 'https://picsum.photos/seed/rap/400/400'),
  GenreItem('سنتی', 'https://picsum.photos/seed/traditional/400/400'),
  GenreItem('هیپ‌هاپ', 'https://picsum.photos/seed/hiphop/400/400'),
  GenreItem('الکترونیک', 'https://picsum.photos/seed/electronic/400/400'),
  GenreItem('راک', 'https://picsum.photos/seed/rock/400/400'),
  GenreItem('کلاسیک', 'https://picsum.photos/seed/classical/400/400'),
  GenreItem('فولک', 'https://picsum.photos/seed/folk/400/400'),
  GenreItem('ترنس', 'https://picsum.photos/seed/trance/400/400'),
  GenreItem('جاز', 'https://picsum.photos/seed/jazz/400/400'),
  GenreItem('بلوز', 'https://picsum.photos/seed/blues/400/400'),
  GenreItem('متال', 'https://picsum.photos/seed/metal/400/400'),
];
