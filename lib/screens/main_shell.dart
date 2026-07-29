import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/strings.dart';
import '../providers/settings_provider.dart';
import '../providers/local_music_provider.dart';
import '../widgets/mini_player.dart';
import '../widgets/glassmorphism.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'local_music_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with TickerProviderStateMixin {
  int _index = 0;
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

  final _pages = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    LocalMusicScreen(),
    ProfileScreen(),
  ];

  final _icons = const [
    [Icons.home_outlined, Icons.home],
    [Icons.search_outlined, Icons.search],
    [Icons.library_music_outlined, Icons.library_music],
    [Icons.folder_open, Icons.folder],
    [Icons.person_outline, Icons.person],
  ];

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimation = CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeOutCubic,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index != _index) {
      setState(() => _index = index);
      _navAnimationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [T.home, T.search, T.library, T.myMusic, T.settings];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          // Glassmorphism bottom nav
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withOpacity(0.85),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.06 : 0.12),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_icons.length, (i) {
                        final active = _index == i;
                        final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

                        return GestureDetector(
                          onTap: () => _onTabTap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: active
                                ? BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  )
                                : null,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, anim) => ScaleTransition(
                                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
                                    child: FadeTransition(opacity: anim, child: child),
                                  ),
                                  child: Icon(
                                    active ? _icons[i][1] : _icons[i][0],
                                    key: ValueKey<bool>(active),
                                    color: active ? AppColors.primary : inactiveColor,
                                    size: active ? 27 : 24,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                                    color: active ? AppColors.primary : inactiveColor,
                                  ),
                                  child: Text(labels[i]),
                                ),
                              ],
                            ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.2),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}