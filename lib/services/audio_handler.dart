import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import 'package:flutter/foundation.dart';

/// Wraps just_audio + background playback (notification / lock screen controls).
class AudioPlayerHandler {
  final AudioPlayer player = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _shuffle = false;
  LoopMode _loop = LoopMode.off;

  // Notifier so UI (player + mini player) updates instantly on track change.
  final _indexNotifier = ValueNotifier<int>(0);
  final _shuffleNotifier = ValueNotifier<bool>(false);
  final _loopNotifier = ValueNotifier<LoopMode>(LoopMode.off);

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  ValueNotifier<int> get indexNotifier => _indexNotifier;
  ValueNotifier<bool> get shuffleNotifier => _shuffleNotifier;
  ValueNotifier<LoopMode> get loopNotifier => _loopNotifier;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<int> get currentIndexStream => player.currentIndexStream;

  Song? get currentSong {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  AudioPlayerHandler() {
    // Keep _currentIndex in sync with the player (covers auto-advance,
    // shuffle, and manual seeks so the UI always shows the right song).
    player.currentIndexStream.listen((i) {
      if (i != null && i != _currentIndex) {
        _currentIndex = i;
        _indexNotifier.value = i;
      }
    });
    player.loopModeStream.listen((m) {
      _loop = m;
      _loopNotifier.value = m;
    });
    player.shuffleModeEnabledStream.listen((on) {
      _shuffle = on;
      _shuffleNotifier.value = on;
    });
  }

  /// Load a list of songs and start playing at [startIndex].
  Future<bool> setQueue(List<Song> songs, {int startIndex = 0}) async {
    // Only keep songs that actually have a playable URL.
    final playable = songs.where((s) => s.audioUrl.isNotEmpty).toList();
    if (playable.isEmpty) {
      debugPrint('No playable songs in queue (all audioUrl empty)');
      return false;
    }
    _queue = playable;
    _currentIndex = startIndex.clamp(0, playable.length - 1);
    _indexNotifier.value = _currentIndex;
    final sources = playable
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
    try {
      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      if (_shuffle) {
        await player.setShuffleModeEnabled(true);
      }
      await player.play();
      return true;
    } catch (e) {
      debugPrint('playback error: $e');
      return false;
    }
  }

  /// Play a single local file (file:// or content:// URI picked by the user).
  Future<bool> playLocalFile(String path,
      {String title = 'آهنگ محلی', String artist = 'دستگاه'}) async {
    final uri = (path.startsWith('http') ||
            path.startsWith('file://') ||
            path.startsWith('content://'))
        ? path
        : 'file://$path';
    final song = Song(
      id: 'local_${path.hashCode}',
      title: title,
      artist: artist,
      audioUrl: uri,
      coverUrl: '',
      genre: '',
      album: '',
      plays: 0,
    );
    _queue = [song];
    _currentIndex = 0;
    _indexNotifier.value = 0;
    try {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(uri),
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
          ),
        ),
      );
      await player.play();
      return true;
    } catch (e) {
      debugPrint('local playback error: $e');
      return false;
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration pos) => player.seek(pos);

  Future<void> next() async {
    if (_queue.isEmpty) return;
    try {
      if (_currentIndex < _queue.length - 1 || _loop == LoopMode.all) {
        await player.seekToNext();
      } else {
        // last track, loop off -> stop at end (just pause)
        await player.pause();
      }
    } catch (_) {
      final i = (_currentIndex + 1) % _queue.length;
      _currentIndex = i;
      _indexNotifier.value = i;
      await _playIndex(i);
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    // If more than 3s in, restart current track (like Spotify)
    final pos = player.position;
    if (pos.inSeconds > 3) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    try {
      await player.seekToPrevious();
    } catch (_) {
      final i = (_currentIndex - 1 + _queue.length) % _queue.length;
      _currentIndex = i;
      _indexNotifier.value = i;
      await _playIndex(i);
    }
  }

  Future<void> _playIndex(int i) async {
    if (i < 0 || i >= _queue.length) return;
    _currentIndex = i;
    _indexNotifier.value = i;
    try {
      await player.seek(Duration.zero, index: i);
      await player.play();
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  /// Jump directly to a queue index.
  Future<void> jumpTo(int i) async {
    if (i < 0 || i >= _queue.length) return;
    _currentIndex = i;
    _indexNotifier.value = i;
    try {
      await player.seek(Duration.zero, index: i);
      await player.play();
    } catch (e) {
      debugPrint('jump error: $e');
    }
  }

  Future<void> setShuffle(bool on) async {
    _shuffle = on;
    _shuffleNotifier.value = on;
    await player.setShuffleModeEnabled(on);
  }

  Future<void> cycleRepeat() async {
    final next = _loop == LoopMode.off
        ? LoopMode.all
        : _loop == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    _loop = next;
    _loopNotifier.value = next;
    await player.setLoopMode(next);
  }

  LoopMode get loopMode => _loop;

  void dispose() => player.dispose();
}
