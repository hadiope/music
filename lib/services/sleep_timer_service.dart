import 'dart:async';
import 'package:flutter/foundation.dart';

/// Sleep timer that pauses playback after a set duration or at the end of current track.
class SleepTimerService {
  Timer? _timer;
  DateTime? _endTime;
  SleepTimerMode _mode = SleepTimerMode.off;

  final _modeNotifier = ValueNotifier<SleepTimerMode>(SleepTimerMode.off);
  final _remainingNotifier = ValueNotifier<Duration>(Duration.zero);

  VoidCallback? onTimerEnd;

  ValueNotifier<SleepTimerMode> get modeNotifier => _modeNotifier;
  ValueNotifier<Duration> get remainingNotifier => _remainingNotifier;

  SleepTimerMode get mode => _mode;
  Duration? get remaining {
    if (_endTime == null || _mode == SleepTimerMode.off) return null;
    final remaining = _endTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isActive => _mode != SleepTimerMode.off && _timer != null;

  /// Start sleep timer with a specific duration.
  void startTimer(Duration duration) {
    cancel();
    _mode = SleepTimerMode.duration;
    _endTime = DateTime.now().add(duration);
    _modeNotifier.value = _mode;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _endTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        _endTimer();
        return;
      }
      _remainingNotifier.value = remaining;
    });
  }

  /// Set sleep timer to stop after the current track ends.
  void endOfTrack() {
    cancel();
    _mode = SleepTimerMode.endOfTrack;
    _modeNotifier.value = _mode;
  }

  /// Cancel the sleep timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    _mode = SleepTimerMode.off;
    _modeNotifier.value = SleepTimerMode.off;
    _remainingNotifier.value = Duration.zero;
  }

  void _endTimer() {
    _timer?.cancel();
    _timer = null;
    _mode = SleepTimerMode.off;
    _modeNotifier.value = SleepTimerMode.off;
    _remainingNotifier.value = Duration.zero;
    onTimerEnd?.call();
  }

  /// Format remaining time as readable string.
  String get formattedRemaining {
    final r = remaining;
    if (r == null) return '';
    if (r.inHours > 0) {
      return '${r.inHours}h ${r.inMinutes.remainder(60)}m';
    }
    return '${r.inMinutes}m ${r.inSeconds.remainder(60)}s';
  }

  void dispose() {
    _timer?.cancel();
    _modeNotifier.dispose();
    _remainingNotifier.dispose();
  }
}

enum SleepTimerMode { off, duration, endOfTrack }