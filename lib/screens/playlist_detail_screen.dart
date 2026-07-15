import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/playlist.dart';
import '../providers/core_providers.dart';
import '../providers/playlist_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'local_songs_screen.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  // Local (device) songs added to this playlist session
  final List<PlatformFile> _local = [];

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(playlistSongsProvider(widget.playlist.id));
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
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
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _sharePlaylist(context),
                  icon: const Icon(Icons.share),
                  tooltip: 'اشتراک‌گذاری',
                ),
              ],
            ),
          ),
          Expanded(
            child: songs.when(
              data: (list) {
                final hasItems = list.isNotEmpty || _local.isNotEmpty;
                if (!hasItems) {
                  return const Center(
                    child: Text('آهنگی ندارد، از بالا اضافه کن'),
                  );
                }
                return ListView(
                  children: [
                    ...list.asMap().entries.map((e) => SongTile(
                          song: e.value,
                          onTap: () {
                            ref.read(playSongProvider).playQueue(list, e.key);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                          },
                        )),
                    ..._local.asMap().entries.map((e) {
                      final f = e.value;
                      final name = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.audio_file)),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: const Text('آهنگ گوشی'),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () {
                          ref.read(audioHandlerProvider).playLocalFile(f.path!, title: name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('در حال پخش: $name')),
                          );
                        },
                      );
                    }),
                  ],
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
            await ref.read(playlistControllerProvider).addSong(widget.playlist.id, all[i].id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _addFromDevice(BuildContext context, WidgetRef ref) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      withData: false,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _local.addAll(res.files.where((f) => f.path != null)));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res.files.length} آهنگ از گوشی اضافه شد')),
        );
      }
    }
  }

  void _sharePlaylist(BuildContext context) {
    final link = 'https://thetextstory.com/playlist/${widget.playlist.id}';
    // Share via the OS sheet so the deep link works when tapped from Telegram.
    Share.share(
      'پلی‌لیست «${widget.playlist.name}»:\n$link',
      subject: widget.playlist.name,
    );
  }
}


