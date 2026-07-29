import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism container with blur effect (Spotify-style).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double blurIntensity;
  final Color tintColor;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurIntensity = 20,
    this.tintColor = Colors.black,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: BackdropFilter(
          filter: tintColor == Colors.transparent
              ? ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity)
              : ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: tintColor.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glassmorphism bottom sheet container.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double initialChildSize;
  final double maxChildSize;
  final double minChildSize;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.initialChildSize = 0.75,
    this.maxChildSize = 0.95,
    this.minChildSize = 0.3,
  });

  static void show(BuildContext context, Widget child, {
    double initialChildSize = 0.75,
    double maxChildSize = 0.95,
    double minChildSize = 0.3,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => GlassBottomSheet(
        child: child,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        minChildSize: minChildSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: maxChildSize,
      minChildSize: minChildSize,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}