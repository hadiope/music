import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';

/// Wraps just_audio + background playback (notification / lock screen controls).
class AudioPlayerHandler {
  final AudioPlayer player = AudioPlayer();
  List<Song> _queue = [];

  List<Song> get queue => _queue;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  Song? get currentSong {
    final i = player.currentIndex;
    if (i == null || i < 0 || i >= _queue.length) return null;
    return _queue[i];
  }

  /// Load a list of songs and start at [startIndex].
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = songs;
    final sources = songs
        .map((s) => AudioSource.uri(
              Uri.parse(s.audioUrl),
              tag: MediaItem(
                id: s.id,
                title: s.title,
                artist: s.artist,
                album: s.album ?? '',
                artUri: s.coverUrl.isNotEmpty ? Uri.parse(s.coverUrl) : null,
              ),
            ))
        .toList();
    await player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: startIndex,
    );
    play();
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration pos) => player.seek(pos);
  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();

  Future<void> setShuffle(bool on) async {
    await player.setShuffleModeEnabled(on);
  }

  Future<void> cycleRepeat() async {
    final mode = player.loopMode;
    final next = mode == LoopMode.off
        ? LoopMode.all
        : mode == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    await player.setLoopMode(next);
  }

  LoopMode get loopMode => player.loopMode;

  void dispose() => player.dispose();
}
