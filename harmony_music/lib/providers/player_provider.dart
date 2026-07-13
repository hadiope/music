import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import 'core_providers.dart';

/// Plays a queue starting at a given song and records history + plays.
final playSongProvider = Provider<PlayController>((ref) => PlayController(ref));

class PlayController {
  final Ref ref;
  PlayController(this.ref);

  Future<void> playQueue(List<Song> songs, int index) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.setQueue(songs, startIndex: index);
    final song = songs[index];
    // record history + increment plays (best-effort)
    final user = ref.read(currentUserProvider);
    final db = ref.read(databaseProvider);
    try {
      await db.incrementPlays(song.id);
      if (user != null) await db.addHistory(user.id, song.id);
    } catch (_) {}
  }

  Future<void> playSingle(Song song) async {
    await playQueue([song], 0);
  }
}
