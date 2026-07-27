import 'dart:math';
import 'package:flutter/material.dart';

/// A spinning vinyl record animation for the album art.
class VinylDisk extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final double size;
  final bool isPlaying;

  const VinylDisk({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.size = 280,
    this.isPlaying = true,
  });

  @override
  State<VinylDisk> createState() => _VinylDiskState();
}

class _VinylDiskState extends State<VinylDisk>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylDisk oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vinyl record disk
          AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment.center,
                      colors: [
                        Color(0xFF1A1A1A),
                        Color(0xFF0D0D0D),
                        Color(0xFF1A1A1A),
                        Color(0xFF0A0A0A),
                      ],
                      stops: [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.4,
                      height: size * 0.4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A1A1A),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(size * 0.2),
                          child: widget.localImagePath != null
                              ? Image.file(
                                  File(widget.localImagePath!),
                                  width: size * 0.38,
                                  height: size * 0.38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _defaultArt(size),
                                )
                              : _buildNetworkImage(size),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Center spindle
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade700,
              border: Border.all(color: Colors.grey.shade500, width: 1),
            ),
          ),
          // Groove lines
          ...List.generate(8, (i) {
            final radius = size * 0.3 + (i * size * 0.035);
            return IgnorePointer(
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.03),
                    width: 0.5,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(double size) {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return _defaultArt(size);
    return CachedNetworkImage(
      imageUrl: url,
      width: size * 0.38,
      height: size * 0.38,
      fit: BoxFit.cover,
      placeholder: (_, __) => _defaultArt(size),
      errorWidget: (_, __, ___) => _defaultArt(size),
    );
  }

  Widget _defaultArt(double size) => Container(
        width: size * 0.38,
        height: size * 0.38,
        color: Colors.grey.shade800,
        child: Icon(Icons.music_note, color: Colors.white38, size: size * 0.15),
      );
}

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';