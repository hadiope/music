import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import '../providers/playlist_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/ui_kit.dart';
import '../core/theme.dart';
import '../core/app_route.dart';
import 'local_songs_screen.dart';

/// A device song kept locally (path-based, not in the cloud DB).
class LocalSong {
  final String path;
  final String name;
  LocalSong({required this.path, required this.name});
  Map<String, dynamic> toJson() => {'path': path, 'name': name};
  factory LocalSong.fromJson(Map<String, dynamic> j) =>
      LocalSong(path: j['path'], name: j['name']);
}

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  // Local (device) songs persisted to shared_preferences keyed by playlist id.
  List<LocalSong> _local = [];

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_songs_${widget.playlist.id}') ?? '[]';
    final list = (jsonDecode(raw) as List).map((e) => LocalSong.fromJson(e)).toList();
    if (mounted) setState(() => _local = list);
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'local_songs_${widget.playlist.id}', jsonEncode(_local.map((e) => e.toJson()).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songs = ref.watch(playlistSongsProvider(widget.playlist.id));
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.playlist.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppColors.primary, isDark ? AppColors.darkBg : AppColors.lightBg],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.queue_music, size: 64, color: Colors.white70),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _sharePlaylist(context),
                icon: const Icon(Icons.share),
                tooltip: T.sharePlaylist,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addFromApp(context, ref),
                      icon: const Icon(Icons.music_note),
                      label: Text(T.addFromApp),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addFromDevice(context, ref),
                      icon: const Icon(Icons.folder_open),
                      label: Text(T.addFromDevice),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: songs.when(
              data: (list) {
                final hasItems = list.isNotEmpty || _local.isNotEmpty;
                if (!hasItems) {
                  return Center(child: Text(T.noPlaylist));
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  children: [
                    ...list.asMap().entries.map((e) => SongTile(
                          song: e.value,
                          onTap: () {
                            ref.read(playSongProvider).playQueue(list, e.key);
                            goToPlayer(context);
                          },
                        )),
                    ..._local.asMap().entries.map((e) {
                      final s = e.value;
                      return Container(
                        decoration: UiKit.cardDecoration(context),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.audio_file, color: Colors.white),
                            ),
                            title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(T.deviceSong),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () {
                              ref.read(audioHandlerProvider).playLocalFile(s.path, title: s.name);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(T.playingPrefix + s.name)),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('${T.errorPrefix}$e')),
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
      final picked = res.files.where((f) => f.path != null).map((f) {
        final name = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        return LocalSong(path: f.path!, name: name);
      }).toList();
      setState(() => _local.addAll(picked));
      await _saveLocal();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(T.lang == 'en'
              ? '${picked.length} device songs added'
              : T.addedFromDevice.replaceAll('{n}', picked.length.toString()))),
        );
      }
    }
  }

  void _sharePlaylist(BuildContext context) {
    // Web link hosted on GitHub Pages redirects to the app via deep link.
    // Hash routing so no per-id file is needed on the static host.
    final link = 'https://hadiope.github.io/music/#/playlist/${widget.playlist.id}?name=${Uri.encodeComponent(widget.playlist.name)}';
    Share.share(
      '${T.lang == 'en' ? 'Playlist' : 'پلی‌لیست'} «${widget.playlist.name}»:\n$link',
      subject: widget.playlist.name,
    );
  }
}
