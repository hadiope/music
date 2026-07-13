import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/section_header.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newReleases = ref.watch(newReleasesProvider);
    final popular = ref.watch(popularProvider);
    final banners = ref.watch(bannersProvider);
    final genres = ref.watch(genresProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(newReleasesProvider);
          ref.invalidate(popularProvider);
          ref.invalidate(bannersProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: Text('سلام 👋', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Banner
            SliverToBoxAdapter(
              child: banners.when(
                data: (list) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BannerCarousel(banners: list),
                ),
                loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // Genres chips
            SliverToBoxAdapter(
              child: genres.when(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Chip(label: Text(list[i])),
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // New releases
            const SliverToBoxAdapter(child: SectionHeader(title: 'تازه‌ها 🆕')),
            SliverToBoxAdapter(
              child: newReleases.when(
                data: (songs) => SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => SongCard(
                      song: songs[i],
                      onTap: () {
                        ref.read(playSongProvider).playQueue(songs, i);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                      },
                    ),
                  ),
                ),
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (e, __) => Padding(padding: const EdgeInsets.all(16), child: Text('خطا: $e')),
              ),
            ),
            // Popular
            const SliverToBoxAdapter(child: SectionHeader(title: 'محبوب‌ها 🔥')),
            popular.when(
              data: (songs) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => SongTile(
                    song: songs[i],
                    onTap: () {
                      ref.read(playSongProvider).playQueue(songs, i);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
                  ),
                  childCount: songs.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
              error: (e, __) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text('خطا: $e'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
