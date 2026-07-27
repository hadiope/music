import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../models/local_song.dart';
import '../core/theme.dart';
import 'glassmorphism.dart';

/// Album art with blur-up placeholder and dynamic color extraction.
class BlurUpImage extends StatefulWidget {
  final String? url;
  final String? localPath;
  final double size;
  final BorderRadius? borderRadius;
  final Function(Color)? onColorExtracted;

  const BlurUpImage({
    super.key,
    this.url,
    this.localPath,
    required this.size,
    this.borderRadius,
    this.onColorExtracted,
  });

  @override
  State<BlurUpImage> createState() => _BlurUpImageState();
}

class _BlurUpImageState extends State<BlurUpImage> {
  PaletteColor? _dominantColor;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  @override
  void didUpdateWidget(BlurUpImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.localPath != widget.localPath) {
      setState(() {
        _loaded = false;
      });
      _extractColor();
    }
  }

  Future<void> _extractColor() async {
    try {
      final provider = widget.localPath != null
          ? FileImage(File(widget.localPath!))
          : (widget.url != null && widget.url!.isNotEmpty
              ? CachedNetworkImageProvider(widget.url!)
              : null);

      if (provider != null) {
        final palette = await PaletteGenerator.fromImageProvider(provider);
        if (palette.dominantColor != null && mounted) {
          setState(() => _dominantColor = palette.dominantColor);
          widget.onColorExtracted?.call(palette.dominantColor!.color);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blur placeholder
          AnimatedOpacity(
            opacity: _loaded ? 0 : 1,
            duration: 500.ms,
            curve: Curves.easeOutCubic,
            child: _dominantColor != null
                ? Container(
                    decoration: BoxDecoration(
                      color: _dominantColor!.color,
                      borderRadius: radius,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white38, size: 32),
                    ),
                  ),
          ),
          // Actual image
          widget.localPath != null
              ? Image.file(
                  File(widget.localPath!),
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      Future.microtask(() => setState(() => _loaded = true));
                    }
                    return child.animate().fadeIn(duration: 400.ms).scale();
                  },
                  errorBuilder: (_, __, ___) => _placeholder(radius),
                )
              : (widget.url != null && widget.url!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.url!,
                      fit: BoxFit.cover,
                      placeholderFadeInDuration: 400.ms,
                      fadeInDuration: 400.ms,
                      placeholder: (_, __) => _placeholder(radius),
                      errorWidget: (_, __, ___) => _placeholder(radius),
                    ).animate().fadeIn(duration: 400.ms).scale()
                  : _placeholder(radius)),
        ],
      ),
    );
  }

  Widget _placeholder(BorderRadius radius) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: radius,
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: Colors.white38, size: 32),
        ),
      );
}