import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// Manages the playback queue with reorder, remove, and crossfade support.
class QueueService {
  List<Song> _songs = [];
  int _currentIndex = 0;
  bool _crossfadeEnabled = false;
  Duration _crossfadeDuration = const Duration(seconds: 3);

  final _queueNotifier = ValueNotifier<List<Song>>([]);
  final _currentIndexNotifier = ValueNotifier<int>(0);
  final _crossfadeNotifier = ValueNotifier<bool>(false);

  List<Song> get songs => List.unmodifiable(_songs);
  int get currentIndex => _currentIndex;
  ValueNotifier<List<Song>> get queueNotifier => _queueNotifier;
  ValueNotifier<int> get currentIndexNotifier => _currentIndexNotifier;
  ValueNotifier<bool> get crossfadeNotifier => _crossfadeNotifier;

  bool get crossfadeEnabled => _crossfadeEnabled;
  Duration get crossfadeDuration => _crossfadeDuration;

  Song? get currentSong {
    if (_songs.isEmpty || _currentIndex < 0 || _currentIndex >= _songs.length) return null;
    return _songs[_currentIndex];
  }

  int get length => _songs.length;

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    _songs = List.from(songs);
    _currentIndex = startIndex.clamp(0, _songs.length - 1);
    _notifyAll();
  }

  void addToQueue(Song song) {
    _songs.add(song);
    _queueNotifier.value = List.from(_songs);
  }

  void addMultipleToQueue(List<Song> songs) {
    _songs.addAll(songs);
    _queueNotifier.value = List.from(_songs);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _songs.length) return;
    _songs.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      _currentIndex = _currentIndex.clamp(0, _songs.length - 1);
    }
    _notifyAll();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _songs.length || newIndex < 0 || newIndex >= _songs.length) return;
    final song = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, song);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else {
      // Adjust current index if it was affected by the move
      if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }
    }
    _notifyAll();
  }

  void moveToNext(int oldIndex) {
    if (oldIndex + 1 >= _songs.length) return;
    reorder(oldIndex, oldIndex + 1);
  }

  void moveToPrevious(int oldIndex) {
    if (oldIndex <= 0) return;
    reorder(oldIndex, oldIndex - 1);
  }

  void clearQueue() {
    _songs.clear();
    _currentIndex = 0;
    _notifyAll();
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _songs.length) {
      _currentIndex = index;
      _currentIndexNotifier.value = index;
    }
  }

  void setCrossfade(bool enabled, {Duration? duration}) {
    _crossfadeEnabled = enabled;
    if (duration != null) _crossfadeDuration = duration;
    _crossfadeNotifier.value = enabled;
  }

  Song? nextSong() {
    if (_songs.isEmpty) return null;
    if (_currentIndex + 1 < _songs.length) {
      _currentIndex++;
      _currentIndexNotifier.value = _currentIndex;
      return _songs[_currentIndex];
    }
    return null;
  }

  Song? previousSong() {
    if (_songs.isEmpty) return null;
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentIndexNotifier.value = _currentIndex;
      return _songs[_currentIndex];
    }
    return null;
  }

  void _notifyAll() {
    _queueNotifier.value = List.from(_songs);
    _currentIndexNotifier.value = _currentIndex;
  }

  void dispose() {
    _queueNotifier.dispose();
    _currentIndexNotifier.dispose();
    _crossfadeNotifier.dispose();
  }
}