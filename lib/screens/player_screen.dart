import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/net_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import '../providers/likes_provider.dart';
import '../core/theme.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final likes = ref.watch(likesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
        title: Text(T.nowPlayingTitle),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: handler.indexNotifier,
        builder: (context, idx, _) {
          final song = handler.currentSong;
          if (song == null) {
            return Center(child: Text(T.noSongPlaying));
          }
          return StreamBuilder<PlayerState>(
            stream: handler.playerStateStream,
            builder: (context, snap) {
              final playing = snap.data?.playing ?? false;
              final liked = likes.contains(song.id);
              final queueLen = handler.queue.length;
              final isRtl = Directionality.of(context) == TextDirection.rtl;

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    // Cover art with swipe-to-change-track + smooth transition
                    Dismissible(
                      key: ValueKey(song.id),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          isRtl ? handler.previous() : handler.next();
                        } else {
                          isRtl ? handler.next() : handler.previous();
                        }
                      },
                      background: const Icon(Icons.skip_previous, size: 48, color: Color(0xFF1DB954)),
                      secondaryBackground: const Icon(Icons.skip_next, size: 48, color: Color(0xFF1DB954)),
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity == null) return;
                          final v = details.primaryVelocity!;
                          if (isRtl) {
                            if (v > 0) handler.previous();
                            else if (v < 0) handler.next();
                          } else {
                            if (v < 0) handler.previous();
                            else if (v > 0) handler.next();
                          }
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.25, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Stack(
                            key: ValueKey(song.id),
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Hero(
                                  tag: 'cover_${song.id}',
                                  child: NetImage(song.coverUrl, width: 320, height: 320, radius: 0),
                                ),
                              ),
                              if (queueLen > 1)
                                Positioned(
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${idx + 1} / $queueLen',
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title + artist + like
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(song.title,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(song.artist, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                            ],
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: Tween<double>(begin: 0.5, end: 1.0).animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: IconButton(
                            key: ValueKey<bool>(liked),
                            icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? const Color(0xFF1DB954) : null),
                            onPressed: () => ref.read(likesProvider.notifier).toggle(song.id),
                          ),
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
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DraggableScrollableSheet(
                              initialChildSize: 0.75,
                              maxChildSize: 0.95,
                              minChildSize: 0.5,
                              builder: (_, ctrl) => Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Container(
                                      width: 40, height: 4,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(song.title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                    Text(song.artist,
                                        style: TextStyle(color: isDark ? AppColors.greyText : Colors.grey.shade600, fontSize: 14)),
                                    const Divider(height: 20),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: ctrl,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                        child: Text(
                                          (song.lyrics != null && song.lyrics!.isNotEmpty)
                                              ? song.lyrics!
                                              : T.noLyrics,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 17,
                                            height: 1.9,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
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
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                              child: child,
                            ),
                            child: IconButton(
                              key: ValueKey<bool>(playing),
                              iconSize: 44,
                              icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.black),
                              onPressed: () => playing ? handler.pause() : handler.play(),
                            ),
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
