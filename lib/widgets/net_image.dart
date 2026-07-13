import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image with a shimmering placeholder — feels instant while the real cover
/// loads, and caches it so repeat visits are instant.
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  const NetImage(this.url,
      {this.width, this.height, this.fit = BoxFit.cover, this.radius = 8, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final hi = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, hi, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: const Center(child: Icon(Icons.music_note, color: Colors.white38)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: base,
          child: const Center(child: Icon(Icons.music_note, color: Colors.white38)),
        ),
      ),
    );
  }
}
