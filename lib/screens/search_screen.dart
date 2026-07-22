import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/genres.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/net_image.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';
import 'genre_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _query = value.trim();
        ref.read(searchQueryProvider.notifier).state = value.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 90,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: isDark
                        ? [AppColors.primaryDark.withOpacity(0.8), AppColors.darkBg]
                        : [AppColors.primary.withOpacity(0.8), AppColors.lightBg],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Text(
                      T.search,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: T.lang == 'en' ? 'Song or artist...' : 'آهنگ یا خواننده...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: UiKit.sectionHeader(T.categories),
            ),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: genresList.length,
                  itemBuilder: (_, i) {
                    final g = genresList[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GenreScreen(genre: g.localized))),
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NetImage(g.imageUrl, width: 92, height: 104, radius: 0),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    g.localized,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverFillRemaining(
            child: results.when(
              data: (songs) {
                if (_query.isEmpty)
                  return Center(
                    child: Text(
                      T.lang == 'en' ? 'Pick a category or search' : T.pickCategoryOrSearch,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                if (songs.isEmpty)
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 56, color: Theme.of(context).hintColor),
                        const SizedBox(height: 12),
                        Text(T.noResults, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: songs.length,
                  itemBuilder: (_, i) => SongTile(
                    song: songs[i],
                    onTap: () {
                      ref.read(playSongProvider).playQueue(songs, i);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('${T.errorPrefix}$e')),
            ),
          ),
        ],
      ),
    );
  }
}
