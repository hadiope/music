import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_song.dart';
import '../providers/local_music_provider.dart';
import '../providers/core_providers.dart';
import '../services/audio_handler.dart';
import '../widgets/song_tile.dart';
import '../core/theme.dart';
import '../core/strings.dart';
import 'player_screen.dart';

class LocalArtistScreen extends ConsumerWidget {
  final String artistName;

  const LocalArtistScreen({required this.artistName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(_localSongsByArtistProvider(artistName));
    final handler = ref.watch(audioHandlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName),
        centerTitle: false,
      ),
      body: songsAsync.when(
        data: (songs) => songs.isEmpty
            ? Center(
                child: Text(
                  'هنوز آهنگی برای این خواننده یافت نشد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (_, i) {
                  final song = songs[i];
                  return SongTile(
                    song: song.toSong(),
                    onTap: () => _playSong(context, handler, songs, i),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
      ),
    );
  }

  void _playSong(BuildContext context, AudioPlayerHandler handler, List<LocalSong> queue, int index) {
    final songs = queue.map((s) => s.toSong()).toList();
    handler.setQueueSafe(songs, startIndex: index).then((err) {
      if (err == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $err'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _playSong(BuildContext context, List<LocalSong> queue, int index) {
    final handler = ref.read(audioHandlerProvider);
    final songs = queue.map((s) => s.toSong()).toList();
    handler.setQueueSafe(songs, startIndex: index).then((err) {
      if (err == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $err'), backgroundColor: Colors.red),
        );
      }
    });
  }
}

// Provider to fetch songs by artist
final _localSongsByArtistProvider = FutureProvider.family<List<LocalSong>, String>
    ((ref, artist) {
  return ref.read(localMusicServiceProvider).getSongsByArtist(artist);
});