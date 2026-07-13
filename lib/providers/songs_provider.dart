import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/banner.dart' as m;
import 'core_providers.dart';

/// New releases.
final newReleasesProvider = FutureProvider<List<Song>>((ref) async {
  return ref.watch(databaseProvider).getNewReleases();
});

/// Popular songs.
final popularProvider = FutureProvider<List<Song>>((ref) async {
  return ref.watch(databaseProvider).getPopular();
});

/// All songs.
final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  return ref.watch(databaseProvider).getSongs();
});

/// Genres list.
final genresProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(databaseProvider).getGenres();
});

/// Active banners.
final bannersProvider = FutureProvider<List<m.Banner>>((ref) async {
  return ref.watch(databaseProvider).getBanners();
});

/// Songs by genre.
final genreSongsProvider = FutureProvider.family<List<Song>, String>((ref, genre) async {
  return ref.watch(databaseProvider).getByGenre(genre);
});

/// Search query + results.
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final q = ref.watch(searchQueryProvider).trim();
  if (q.isEmpty) return [];
  return ref.watch(databaseProvider).search(q);
});
