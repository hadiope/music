class GenreItem {
  final String name;
  final String imageUrl;
  const GenreItem(this.name, this.imageUrl);
}

/// Iranian music categories with representative cover images.
/// Using loremflickr (fast CDN) seeded by genre for stable, quick loads.
const List<GenreItem> genresList = [
  GenreItem('پاپ', 'https://loremflickr.com/400/400/music?lock=11'),
  GenreItem('رپ', 'https://loremflickr.com/400/400/rap?lock=12'),
  GenreItem('سنتی', 'https://loremflickr.com/400/400/persian?lock=13'),
  GenreItem('هیپ‌هاپ', 'https://loremflickr.com/400/400/hiphop?lock=14'),
  GenreItem('راک', 'https://loremflickr.com/400/400/rock?lock=15'),
  GenreItem('کلاسیک', 'https://loremflickr.com/400/400/classical?lock=16'),
];
