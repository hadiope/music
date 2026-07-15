import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/net_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import '../providers/likes_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final likes = ref.watch(likesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
        title: Text(T.nowPlayingTitle),
      ),
      body: StreamBuilder<int?>(
        stream: handler.currentIndexStream,
        builder: (context, idxSnap) {
          final song = handler.currentSong;
          if (song == null) {
            return Center(child: Text(T.noSongPlaying));
          }
          return StreamBuilder<PlayerState>(
            stream: handler.playerStateStream,
            builder: (context, snap) {
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
                            T.shareText
                                .replaceAll('{title}', song.title)
                                .replaceAll('{artist}', song.artist)
                                .replaceAll('{channel}', AppConstants.telegramChannel),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.lyrics_outlined),
                          tooltip: T.lyricsTooltip,
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              maxChildSize: 0.9,
                              builder: (_, ctrl) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(song.artist, style: const TextStyle(color: Colors.grey)),
                                    const Divider(height: 20),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: ctrl,
                                        child: Text(
                                          (song.lyrics != null && song.lyrics!.isNotEmpty)
                                              ? song.lyrics!
                                              : T.noLyrics,
                                          style: const TextStyle(fontSize: 16, height: 1.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                        ValueListenableBuilder<LoopMode>(
                          valueListenable: handler.loopNotifier,
                          builder: (_, loop, __) => IconButton(
                            iconSize: 28,
                            icon: Icon(loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                                color: loop != LoopMode.off ? const Color(0xFF1DB954) : null),
                            onPressed: () async {
                              await handler.cycleRepeat();
                            },
                          ),
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
                        ValueListenableBuilder<bool>(
                          valueListenable: handler.shuffleNotifier,
                          builder: (_, shuf, __) => IconButton(
                            iconSize: 28,
                            icon: Icon(Icons.shuffle,
                                color: shuf ? const Color(0xFF1DB954) : null),
                            onPressed: () async {
                              await handler.setShuffle(!shuf);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
