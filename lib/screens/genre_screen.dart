import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class GenreScreen extends ConsumerWidget {
  final String genre;
  const GenreScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tProvider); // sync language
    final songsAsync = ref.watch(genreSongsProvider(genre));
    return Scaffold(
      appBar: AppBar(title: Text('${T.lang == 'en' ? 'Songs of' : 'آهنگ‌های'} $genre')),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Text(T.lang == 'en' ? 'No songs in this category yet 🎵' : 'هنوز آهنگی در این دسته نیست 🎵'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const Divider(),
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
    );
  }
}
