import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/song.dart';
import 'net_image.dart';

/// A single song row (Spotify-style: compact, grey subtitle, no dividers).
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;
  const SongTile({super.key, required this.song, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: NetImage(song.coverUrl, width: 50, height: 50, radius: 0),
      ),
      title: Text(song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.greyText)),
      trailing: trailing ??
          const Icon(Icons.more_vert, color: AppColors.greyText, size: 20),
    );
  }
}

/// A square album/song card for horizontal sliders & grids (Spotify style:
/// image-forward, no shadow/border, tight rounded corners).
class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final double size;
  const SongCard({super.key, required this.song, required this.onTap, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Hero(
                tag: 'cover_${song.id}',
                child: NetImage(song.coverUrl, width: size, height: size, radius: 0),
              ),
            ),
            const SizedBox(height: 8),
            Text(song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.greyText)),
          ],
        ),
      ),
    );
  }
}
