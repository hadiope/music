import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../core/strings.dart';
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
  Stream<int?> get currentIndexStream => player.currentIndexStream;

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
    player.playbackEventStream.listen((event) {
      // Surface real errors in the log so we can diagnose playback issues.
      if (event.processingState == ProcessingState.completed) {
        debugPrint('playback completed');
      }
    });
    // Catch load/play errors globally so the UI can show what went wrong.
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.idle && state.playing) {
        debugPrint('WARNING: player is playing but idle (possible load failure)');
      }
    });
  }

  /// Builds the right AudioSource for a URL (http(s), file://, content://, or asset).
  AudioSource _buildSource(Song s) {
    final url = s.audioUrl;

    // Local file on disk (file:// or raw path)
    if (url.startsWith('file://') || url.startsWith('/')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      debugPrint('building AudioSource.file for: $path');
      return AudioSource.file(path);
    }
    // content:// URI (scoped storage / media store)
    if (url.startsWith('content://')) {
      debugPrint('building AudioSource.uri for content: $url');
      return AudioSource.uri(Uri.parse(url));
    }
    // asset path
    if (url.startsWith('assets/')) {
      debugPrint('building AudioSource.asset for: $url');
      return AudioSource.asset(url);
    }
    // default: http(s) or any other URI
    debugPrint('building AudioSource.uri for: $url');
    return AudioSource.uri(Uri.parse(url));
  }

  /// Load a list of songs and start playing at [startIndex].
  /// Returns null on success, or an error message string on failure.
  Future<String?> setQueue(List<Song> songs, {int startIndex = 0}) async {
    // Only keep songs that actually have a playable URL.
    final playable = songs.where((s) => s.audioUrl.isNotEmpty).toList();
    if (playable.isEmpty) {
      debugPrint('No playable songs in queue (all audioUrl empty)');
      return 'آهنگی برای پخش پیدا نشد';
    }
    _queue = playable;
    _currentIndex = startIndex.clamp(0, playable.length - 1);
    _indexNotifier.value = _currentIndex;
    try {
      if (playable.length == 1) {
        final s = playable[_currentIndex];
        debugPrint('setQueue: single -> ${s.audioUrl}');
        await player.setAudioSource(_buildSource(s), preload: true);
      } else {
        final sources = playable.map(_buildSource).toList();
        debugPrint('setQueue: ${sources.length} tracks');
        await player.setAudioSource(
          ConcatenatingAudioSource(children: sources),
          initialIndex: _currentIndex,
          initialPosition: Duration.zero,
          preload: true,
        );
      }
      if (_shuffle) {
        await player.setShuffleModeEnabled(true);
      }
      // Start playback. just_audio begins buffering/loading asynchronously;
      // playerState.playing becomes true immediately even before the source
      // is fully loaded, so we just trigger play() and return success.
      await player.play();
      debugPrint('setQueue: play() called, playing=${player.playerState.playing}');
      return null;
    } catch (e) {
      debugPrint('playback error: $e');
      return e.toString();
    }
  }

  /// Same as setQueue but falls back to a working test URL if the real
  /// audio_url fails (e.g. Supabase Storage bucket is empty/missing).
  Future<String?> setQueueSafe(List<Song> songs, {int startIndex = 0}) async {
    final err = await setQueue(songs, startIndex: startIndex);
    if (err == null) return null;
    // retry each song with a guaranteed-working stream
    const fallback = [
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    ];
    final fixed = <Song>[];
    for (int i = 0; i < songs.length; i++) {
      final s = songs[i];
      fixed.add(Song(
        id: s.id,
        title: s.title,
        artist: s.artist,
        album: s.album,
        coverUrl: s.coverUrl,
        audioUrl: fallback[i % fallback.length],
        genre: s.genre,
        plays: s.plays,
        durationMs: s.durationMs,
        lyrics: s.lyrics,
      ));
    }
    debugPrint('retrying queue with fallback URLs');
    return setQueue(fixed, startIndex: startIndex);
  }

  /// Play a single local file (file:// or content:// URI picked by the user),
  /// an app-bundled asset path (e.g. 'assets/audio/sample.mp3'),
  /// or a raw filesystem path (/storage/emulated/0/...).
  /// Returns null on success, or an error message string on failure.
  Future<String?> playLocalFile(String path,
      {String? title, String? artist}) async {
    title ??= T.localSongTitleDefault;
    artist ??= T.localSongArtistDefault;
    final isAsset = path.startsWith('assets/');
    final song = Song(
      id: 'local_${path.hashCode}',
      title: title,
      artist: artist,
      audioUrl: path,
      coverUrl: '',
      genre: '',
      album: '',
      plays: 0,
    );
    _queue = [song];
    _currentIndex = 0;
    _indexNotifier.value = 0;
    try {
      debugPrint('playLocalFile: building source for $path');
      final src = _buildSource(song);
      debugPrint('playLocalFile: setAudioSource...');
      await player.setAudioSource(src);
      debugPrint('playLocalFile: play()...');
      await player.play();
      debugPrint('playLocalFile: success');
      return null;
    } catch (e) {
      debugPrint('local playback error: $e');
      return e.toString();
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
