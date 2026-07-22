import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../providers/core_providers.dart';
import '../providers/playlist_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

/// A device song kept locally (path-based, not in the cloud DB).
class LocalSong {
  final String path;
  final String name;
  final String? artist;
  final String? coverPath;
  LocalSong({required this.path, required this.name, this.artist, this.coverPath});
  Map<String, dynamic> toJson() => {
    'path': path, 'name': name,
    if (artist != null) 'artist': artist,
    if (coverPath != null) 'coverPath': coverPath,
  };
  factory LocalSong.fromJson(Map<String, dynamic> j) => LocalSong(
    path: j['path'], name: j['name'],
    artist: j['artist'], coverPath: j['coverPath'],
  );
}

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen>
    with SingleTickerProviderStateMixin {
  List<LocalSong> _local = [];
  late Playlist _playlist;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animController.forward();
    _loadLocal();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_songs_${_playlist.id}') ?? '[]';
    final list = (jsonDecode(raw) as List).map((e) => LocalSong.fromJson(e)).toList();
    if (mounted) setState(() => _local = list);
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'local_songs_${_playlist.id}', jsonEncode(_local.map((e) => e.toJson()).toList()));
  }

  void _showRenameDialog() {
    final ctrl = TextEditingController(text: _playlist.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(T.renamePlaylist),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: T.playlistName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(T.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              await ref.read(playlistControllerProvider).rename(_playlist.id, newName);
              if (mounted) {
                setState(() => _playlist = Playlist(
                  id: _playlist.id,
                  userId: _playlist.userId,
                  name: newName,
                  coverUrl: _playlist.coverUrl,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(T.playlistRenamed), backgroundColor: AppColors.primary),
                );
              }
            },
            child: Text(T.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(T.deletePlaylist),
        content: Text(T.deletePlaylistConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(T.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await ref.read(playlistControllerProvider).delete(_playlist.id);
              if (mounted) {
                Navigator.pop(context); // go back from playlist detail
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(T.playlistDeleted), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(T.delete),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: AppColors.primary),
              title: Text(T.playing),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              title: Text(T.removeSong),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(playlistControllerProvider).removeSong(_playlist.id, song.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(T.lang == 'en' ? 'Song removed' : 'آهنگ حذف شد'), backgroundColor: Colors.redAccent),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songs = ref.watch(playlistSongsProvider(_playlist.id));
    ref.watch(tProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_playlist.name,
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
                  child: Icon(Icons.queue_music, size: 72, color: Colors.white70),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showRenameDialog,
                icon: const Icon(Icons.edit),
                tooltip: T.renamePlaylist,
              ),
              IconButton(
                onPressed: () => _sharePlaylist(context),
                icon: const Icon(Icons.share),
                tooltip: T.sharePlaylist,
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _showDeleteConfirm();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'delete', child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(T.deletePlaylist, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  )),
                ],
              ),
            ],
          ),

          // Add buttons
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
                    ...list.asMap().entries.map((e) {
                      final song = e.value;
                      return Dismissible(
                        key: ValueKey('cloud_${song.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await ref.read(playlistControllerProvider).removeSong(_playlist.id, song.id);
                          return true;
                        },
                        child: SongTile(
                          song: song,
                          onTap: () {
                            ref.read(playSongProvider).playQueue(list, e.key);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                          },
                          onLongPress: () => _showSongOptions(song),
                        ),
                      );
                    }),
                    ..._local.asMap().entries.map((e) {
                      final s = e.value;
                      return Container(
                        decoration: UiKit.cardDecoration(context),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            leading: s.coverPath != null && s.coverPath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      fit: BoxFit.cover,
                                      width: 50, height: 50,
                                      errorBuilder: (_, __, ___) => const CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        child: Icon(Icons.audio_file, color: Colors.white),
                                      ),
                                    ),
                                  )
                                : const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.audio_file, color: Colors.white),
                                  ),
                            title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(s.artist ?? T.deviceSong),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () {
                              ref.read(audioHandlerProvider).playLocalFile(
                                s.path, title: s.name, artist: s.artist,
                              );
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
            await ref.read(playlistControllerProvider).addSong(_playlist.id, all[i].id);
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
    // Use the iranseda:// deep link scheme which opens the app directly.
    // Also provide the GitHub Pages redirect URL as fallback.
    final deepLink = 'iranseda://playlist/${_playlist.id}';
    final webLink = 'https://hadiope.github.io/music/playlist/${_playlist.id}';
    Share.share(
      '${T.lang == 'en' ? 'Playlist' : 'پلی‌لیست'} «${_playlist.name}»:\n\n$deepLink\n\n$webLink',
      subject: _playlist.name,
    );
  }
}
