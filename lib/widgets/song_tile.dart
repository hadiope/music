import 'package:flutter/material.dart';
import '../models/song.dart';
import 'net_image.dart';

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
      leading: NetImage(song.coverUrl, width: 52, height: 52, radius: 6),
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
            NetImage(song.coverUrl, width: size, height: size, radius: 10),
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
