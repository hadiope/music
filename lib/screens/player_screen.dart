import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/net_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../providers/core_providers.dart';
import '../providers/likes_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final likes = ref.watch(likesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
        title: const Text('در حال پخش'),
      ),
      body: StreamBuilder<PlayerState>(
        stream: handler.playerStateStream,
        builder: (context, snap) {
          final song = handler.currentSong;
          if (song == null) {
            return const Center(child: Text('آهنگی پخش نمی‌شود'));
          }
          final playing = snap.data?.playing ?? false;
          final liked = likes.contains(song.id);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // Cover art
                NetImage(song.coverUrl, width: 300, height: 300, radius: 16),
                const SizedBox(height: 32),
                // Title + artist + like
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(song.artist, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? const Color(0xFF1DB954) : null),
                      onPressed: () => ref.read(likesProvider.notifier).toggle(song.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => Share.share(
                        'به این آهنگ گوش بده: ${song.title} - ${song.artist}\n'
                        'از اپ Iranian Spotify 🎧\nکانال ما: ${AppConstants.telegramChannel}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: handler.durationStream,
                      builder: (context, durSnap) {
                        final dur = durSnap.data ?? Duration.zero;
                        final max = dur.inMilliseconds.toDouble();
                        final value = pos.inMilliseconds.clamp(0, max == 0 ? 1 : max).toDouble();
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                min: 0,
                                max: max == 0 ? 1 : max,
                                value: value,
                                activeColor: const Color(0xFF1DB954),
                                onChanged: (v) => handler.seek(Duration(milliseconds: v.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [Text(_fmt(pos)), Text(_fmt(dur))],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 28,
                      icon: Icon(handler.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                          color: handler.loopMode != LoopMode.off ? const Color(0xFF1DB954) : null),
                      onPressed: () async { await handler.cycleRepeat(); (context as Element).markNeedsBuild(); },
                    ),
                    IconButton(iconSize: 40, icon: const Icon(Icons.skip_previous), onPressed: () => handler.previous()),
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                      child: IconButton(
                        iconSize: 44,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.black),
                        onPressed: () => playing ? handler.pause() : handler.play(),
                      ),
                    ),
                    IconButton(iconSize: 40, icon: const Icon(Icons.skip_next), onPressed: () => handler.next()),
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.shuffle),
                      onPressed: () async { await handler.setShuffle(!handler.player.shuffleModeEnabled); (context as Element).markNeedsBuild(); },
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
