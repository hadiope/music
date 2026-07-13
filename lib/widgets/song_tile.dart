import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';

/// A single song row (used in lists).
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;
  const SongTile({super.key, required this.song, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: song.coverUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(width: 52, height: 52, color: Colors.grey.shade800),
          errorWidget: (_, __, ___) => Container(
            width: 52,
            height: 52,
            color: Colors.grey.shade800,
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
    );
  }
}

/// A square album/song card for horizontal sliders & grids.
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
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: song.coverUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: size, height: size, color: Colors.grey.shade800),
                errorWidget: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
