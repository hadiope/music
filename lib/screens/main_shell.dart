import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'device_library_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  final _pages = const [HomeScreen(), SearchScreen(), LibraryScreen(), DeviceLibraryScreen()];

  final _icons = const [
    [Icons.home_outlined, Icons.home],
    [Icons.search_outlined, Icons.search],
    [Icons.library_music_outlined, Icons.library_music],
    [Icons.folder_music_outlined, Icons.folder_music],
  ];
  final _labels = [T.home, T.search, T.library, T.myMusic];

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
              color: AppColors.darkSurface,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_icons.length, (i) {
                    final active = _index == i;
                    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
                    return GestureDetector(
                      onTap: () => setState(() => _index = i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active ? _icons[i][1] : _icons[i][0],
                              color: active ? AppColors.primary : inactiveColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _labels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                color: active ? AppColors.primary : inactiveColor,
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
