import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  final _pages = const [HomeScreen(), SearchScreen(), LibraryScreen(), ProfileScreen()];

  final _icons = const [
    [Icons.home_outlined, Icons.home],
    [Icons.search_outlined, Icons.search],
    [Icons.library_music_outlined, Icons.library_music],
    [Icons.person_outline, Icons.person],
  ];
  final _labels = [T.home, T.search, T.library, T.profile];

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider); // keep T in sync with locale
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_icons.length, (i) {
                    final active = _index == i;
                    return GestureDetector(
                      onTap: () => setState(() => _index = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: active ? AppTheme.brandGradient : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active ? _icons[i][1] : _icons[i][0],
                              color: active
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _labels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                color: active
                                    ? Colors.white
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
