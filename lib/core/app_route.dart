import 'package:flutter/material.dart';
import 'screens/player_screen.dart';

/// Smooth, shared page transition used app-wide for navigation into the
/// full player and detail screens. A gentle slide-up + fade keeps the UI
/// feeling fluid and modern (Spotify-like).
class AppRoute extends PageRouteBuilder {
  final Widget page;
  AppRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.08);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: tween.animate(animation), child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
        );
}

/// Navigate to the full PlayerScreen with the shared smooth transition.
void goToPlayer(BuildContext context) {
  Navigator.push(context, AppRoute(page: const PlayerScreen()));
}
