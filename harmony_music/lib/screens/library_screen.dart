import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/likes_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedSongsProvider);
    final history = ref.watch(historyProvider);
    final playlists = ref.watch(playlistsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کتابخانه'),
          bottom: const TabBar(tabs: [
            Tab(text: 'علاقه‌مندی‌ها ❤️'),
            Tab(text: 'پلی‌لیست‌ها'),
            Tab(text: 'تاریخچه'),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _createPlaylistDialog(context, ref),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _songList(context, ref, liked),
            playlists.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text('پلی‌لیستی نساختی'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.queue_music),
                        title: Text(list[i].name),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('خطا: $e')),
            ),
            _songList(context, ref, history),
          ],
        ),
      ),
    );
  }

  Widget _songList(BuildContext context, WidgetRef ref, AsyncValue songs) {
    return songs.when(
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('خالیه', style: TextStyle(color: Colors.grey)));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => SongTile(
            song: list[i],
            onTap: () {
              ref.read(playSongProvider).playQueue(List.from(list), i);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('خطا: $e')),
    );
  }

  void _createPlaylistDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پلی‌لیست جدید'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'اسم پلی‌لیست')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(playlistControllerProvider).create(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('بساز'),
          ),
        ],
      ),
    );
  }
}
