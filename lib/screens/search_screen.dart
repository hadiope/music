import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/genres.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'genre_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('جستجو')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'آهنگ یا خواننده...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (query.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(alignment: Alignment.centerRight, child: Text('دسته‌بندی‌ها', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: genresList.length,
                itemBuilder: (_, i) {
                  final g = genresList[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GenreScreen(genre: g.name))),
                    child: Container(
                      width: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(image: NetworkImage(g.imageUrl), fit: BoxFit.cover),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black45),
                        child: Center(child: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          Expanded(
            child: results.when(
              data: (songs) {
                if (query.isEmpty) return const Center(child: Text('یک دسته‌بندی انتخاب کن یا جستجو کن', style: TextStyle(color: Colors.grey)));
                if (songs.isEmpty) return const Center(child: Text('نتیجه‌ای یافت نشد', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (_, i) => SongTile(
                    song: songs[i],
                    onTap: () {
                      ref.read(playSongProvider).playQueue(songs, i);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('خطا: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
