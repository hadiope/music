import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';

/// Wraps just_audio + background playback (notification / lock screen controls).
class AudioPlayerHandler {
  final AudioPlayer player = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = 0;
  bool _shuffle = false;
  LoopMode _loop = LoopMode.off;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<int> get currentIndexStream =>
      player.currentIndexStream.map((i) => i ?? 0);

  Song? get currentSong {
    if (_queue.isEmpty || _currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  /// Load a list of songs and start at [startIndex].
  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);
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
    try {
      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await player.play();
    } catch (e) {
      // If playback fails (e.g. bad URL), still keep the queue so UI shows it.
      debugPrint('playback error: $e');
    }
  }

  /// Play a single local file (file:// or content:// URI picked by the user).
  Future<void> playLocalFile(String path,
      {String title = 'آهنگ محلی', String artist = 'دستگاه'}) async {
    final song = Song(
      id: 'local_${path.hashCode}',
      title: title,
      artist: artist,
      audioUrl: path.startsWith('http') ? path : 'file://$path',
      coverUrl: '',
      genre: '',
      album: '',
      plays: 0,
    );
    _queue = [song];
    _currentIndex = 0;
    try {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.audioUrl),
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
          ),
        ),
      );
      await player.play();
    } catch (e) {
      debugPrint('local playback error: $e');
    }
  }

  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> seek(Duration pos) => player.seek(pos);

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_shuffle) {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    }
    await _playIndex(_currentIndex);
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
    if (_shuffle) {
      _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    } else {
      _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    }
    await _playIndex(_currentIndex);
  }

  Future<void> _playIndex(int i) async {
    if (i < 0 || i >= _queue.length) return;
    _currentIndex = i;
    try {
      await player.seek(Duration.zero, index: i);
      await player.play();
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  Future<void> setShuffle(bool on) async {
    _shuffle = on;
    await player.setShuffleModeEnabled(on);
  }

  Future<void> cycleRepeat() async {
    final next = _loop == LoopMode.off
        ? LoopMode.all
        : _loop == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    _loop = next;
    await player.setLoopMode(next);
  }

  LoopMode get loopMode => _loop;

  void dispose() => player.dispose();
}
