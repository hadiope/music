import 'strings.dart';

class GenreItem {
  final String name; // Persian (default) display name
  final String nameEn; // English display name
  final String imageUrl;
  const GenreItem(this.name, this.nameEn, this.imageUrl);

  /// Returns the localized name based on current language.
  String get localized => T.lang == 'en' ? nameEn : name;
}

/// Iranian music categories with representative cover images.
/// Using loremflickr (fast CDN) seeded by genre for stable, quick loads.
const List<GenreItem> genresList = [
  GenreItem('پاپ', 'Pop', 'https://loremflickr.com/400/400/music?lock=11'),
  GenreItem('رپ', 'Rap', 'https://loremflickr.com/400/400/rap?lock=12'),
  GenreItem('سنتی', 'Traditional', 'https://loremflickr.com/400/400/persian?lock=13'),
  GenreItem('هیپ‌هاپ', 'Hip-hop', 'https://loremflickr.com/400/400/hiphop?lock=14'),
  GenreItem('راک', 'Rock', 'https://loremflickr.com/400/400/rock?lock=15'),
  GenreItem('کلاسیک', 'Classical', 'https://loremflickr.com/400/400/classical?lock=16'),
];
