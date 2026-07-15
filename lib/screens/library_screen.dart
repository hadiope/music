import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/genres.dart';
import '../core/theme.dart';
import '../providers/likes_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'playlist_detail_screen.dart';
import 'local_songs_screen.dart';
import 'genre_screen.dart';
import 'device_songs_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tProvider); // sync language
    final liked = ref.watch(likedSongsProvider);
    final history = ref.watch(historyProvider);
    final playlists = ref.watch(playlistsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(T.library),
          bottom: TabBar(tabs: [
            Tab(text: '❤️ ${T.liked}'),
            Tab(text: T.playlists),
            Tab(text: T.nowPlaying),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.audiotrack),
              tooltip: T.lang == 'en' ? 'Device songs' : 'آهنگ‌های گوشی',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceSongsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: T.addFromDevice,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalSongsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: T.playlists,
              onPressed: () => _createPlaylistDialog(context, ref),
            ),
          ],
        ),
        body: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _songList(context, ref, liked),
                  playlists.when(
                    data: (list) => list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(T.noPlaylists),
                                TextButton.icon(
                                  onPressed: () => _createPlaylistDialog(context, ref),
                                  icon: const Icon(Icons.add),
                                  label: Text(T.createFirstPlaylist),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) => ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.queue_music)),
                              title: Text(list[i].name),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: list[i])),
                              ),
                            ),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Center(child: Text(T.errGeneric.replaceAll('{e}', e.toString()))),
                  ),
                  _songList(context, ref, history),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _songList(BuildContext context, WidgetRef ref, AsyncValue songs) {
    return songs.when(
      data: (list) {
        if (list.isEmpty) return Center(child: Text(T.noResults, style: const TextStyle(color: Colors.grey)));
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
      error: (e, __) => Center(child: Text(T.errGeneric.replaceAll('{e}', e.toString()))),
    );
  }

  void _createPlaylistDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(T.newPlaylist),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: T.playlistName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(T.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(playlistControllerProvider).create(ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text(T.create),
          ),
        ],
      ),
    );
  }
}
