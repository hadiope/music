import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../providers/playlist_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'local_songs_screen.dart';

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
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addFromApp(context, ref),
                    icon: const Icon(Icons.music_note),
                    label: const Text('از برنامه'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addFromDevice(context, ref),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('از گوشی'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: songs.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('آهنگی ندارد، از بالا اضافه کن'),
                  );
                }
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

  void _addFromApp(BuildContext context, WidgetRef ref) async {
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

  void _addFromDevice(BuildContext context, WidgetRef ref) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );
    if (res != null && res.files.firstOrNull?.path != null) {
      final path = res.files.first.path!;
      // Play locally (no upload) — added to this playlist's local queue
      ref.read(audioHandlerProvider).playLocalFile(path, title: res.files.first.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('در حال پخش: ${res.files.first.name}')),
        );
      }
    }
  }
}
