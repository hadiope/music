import 'package:flutter/material.dart';
import '../widgets/net_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../core/theme.dart';
import '../providers/core_providers.dart';
import '../core/app_route.dart';

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
        // Rebuild on any player state change (playing/paused/stopped) so the
        // mini-player appears immediately on the first tap — indexNotifier
        // alone doesn't fire when the first song loads at index 0.
        final song = handler.currentSong;
        if (song == null) return const SizedBox.shrink();
        final playing = snap.data?.playing ?? false;
        return GestureDetector(
                onTap: () => goToPlayer(context),
                // Swipe up to open the full player (Spotify-style).
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    goToPlayer(context);
                  }
                },
              child: Container(
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Hero(
                        tag: 'cover_${song.id}',
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
                    IconButton(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                          color: isDark ? Colors.white : Colors.black87, size: 30),
                      onPressed: () => playing ? handler.pause() : handler.play(),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next,
                          color: isDark ? Colors.white : Colors.black87, size: 26),
                      onPressed: () => handler.next(),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }
}