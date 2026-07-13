import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class GenreScreen extends ConsumerWidget {
  final String genre;
  const GenreScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(genreSongsProvider(genre));
    return Scaffold(
      appBar: AppBar(title: Text('آهنگ‌های $genre')),
      body: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('هنوز آهنگی در این دسته نیست 🎵'));
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
