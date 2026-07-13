import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(playlistSongsProvider(playlist.id));
    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _addSongs(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('اضافه کردن آهنگ از برنامه'),
            ),
          ),
          Expanded(
            child: songs.when(
              data: (list) {
                if (list.isEmpty) return const Center(child: Text('آهنگی ندارد، از بالا اضافه کن'));
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => SongTile(
                    song: list[i],
                    onTap: () {
                      ref.read(playSongProvider).playQueue(list, i);
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

  void _addSongs(BuildContext context, WidgetRef ref) async {
    final all = await ref.read(allSongsProvider.future);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: all.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(all[i].title),
          subtitle: Text(all[i].artist),
          onTap: () async {
            await ref.read(playlistControllerProvider).addSong(playlist.id, all[i].id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
