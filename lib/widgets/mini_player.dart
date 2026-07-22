import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../widgets/net_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/core_providers.dart';
import '../screens/player_screen.dart';

/// The persistent mini-player shown above the bottom nav bar (Spotify style:
/// dark elevated bar, tight, single green control).
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<PlayerState>(
      stream: handler.playerStateStream,
      builder: (context, snap) {
        final song = handler.currentSong;
        if (song == null) return const SizedBox.shrink();
        final playing = snap.data?.playing ?? false;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          ),
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            }
          },
          child: AnimatedSlide(
            offset: Offset.zero,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightCard,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'cover_${song.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: NetImage(song.coverUrl, width: 44, height: 44, radius: 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87)),
                        Text(song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.greyText : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: IconButton(
                      key: ValueKey<bool>(playing),
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                          color: isDark ? Colors.white : Colors.black87, size: 30),
                      onPressed: () => playing ? handler.pause() : handler.play(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next,
                        color: isDark ? Colors.white : Colors.black87, size: 26),
                    onPressed: () => handler.next(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
