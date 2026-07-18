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
import '../core/app_route.dart';
import 'genre_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tProvider); // sync language
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = ref.watch(searchQueryProvider);
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
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: T.lang == 'en' ? 'Song or artist...' : 'آهنگ یا خواننده...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          if (query.isEmpty)
            SliverToBoxAdapter(
              child: UiKit.sectionHeader(T.categories),
            ),
          if (query.isEmpty)
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
                if (query.isEmpty)
                  return Center(
                    child: Text(
                      T.lang == 'en' ? 'Pick a category or search' : T.pickCategoryOrSearch,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                if (songs.isEmpty)
                  return Center(child: Text(T.noResults, style: const TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: songs.length,
                  itemBuilder: (_, i) => SongTile(
                    song: songs[i],
                    onTap: () {
                      ref.read(playSongProvider).playQueue(songs, i);
                      goToPlayer(context);
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
