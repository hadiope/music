import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../core/theme.dart';

/// Audio visualizer with waveform/progress bar.
class AudioVisualizer extends StatelessWidget {
  final Stream<Duration> positionStream;
  final Stream<Duration?> durationStream;
  final ValueChanged<Duration>? onSeek;
  final Duration? currentPosition;
  final Duration? totalDuration;

  const AudioVisualizer({
    super.key,
    required this.positionStream,
    required this.durationStream,
    this.onSeek,
    this.currentPosition,
    this.totalDuration,
  });

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inMinutes}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: positionStream,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? currentPosition ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: durationStream,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? totalDuration ?? Duration.zero;
            final max = dur.inMilliseconds.toDouble();
            final value = pos.inMilliseconds.clamp(0, max == 0 ? 1 : max).toDouble();

            return ProgressBar(
              progress: pos,
              barHeight: 4,
              thumbRadius: 6,
              progressBarColor: AppColors.primary,
              baseBarColor: Colors.grey.shade700,
              thumbColor: AppColors.primary,
              timeLabelTextStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              total: dur == Duration.zero ? null : dur,
              onSeek: onSeek,
              timeLabelLocation: TimeLabelLocation.sides,
            );
          },
        );
      },
    );
  }
}