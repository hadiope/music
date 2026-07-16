import 'package:flutter/material.dart';
import '../widgets/net_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/core_providers.dart';
import '../screens/player_screen.dart';

/// The persistent mini-player shown above the bottom nav bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<int>(
      valueListenable: handler.indexNotifier,
      builder: (context, idx, _) {
        final song = handler.currentSong;
        if (song == null) return const SizedBox.shrink();
        return StreamBuilder(
          stream: handler.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              ),
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [AppColors.darkCard, AppColors.darkSurface],
                        )
                      : AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: NetImage(song.coverUrl, width: 46, height: 46, radius: 10),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.white,
                              )),
                          Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.white70,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                          color: isDark ? AppColors.primary : Colors.white),
                      onPressed: () => playing ? handler.pause() : handler.play(),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next,
                          color: isDark ? AppColors.primary : Colors.white),
                      onPressed: () => handler.next(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
