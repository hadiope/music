import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/greetings.dart';
import '../core/genres.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/section_header.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'genre_screen.dart';
import '../widgets/local_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _userName() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return '';
    final meta = u.userMetadata;
    if (meta != null && meta['name'] != null) return firstName(meta['name'].toString());
    if (meta != null && meta['full_name'] != null) return firstName(meta['full_name'].toString());
    if (u.email != null) return firstName(u.email);
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newReleases = ref.watch(newReleasesProvider);
    final popular = ref.watch(popularProvider);
    final banners = ref.watch(bannersProvider);
    final user = _userName();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(newReleasesProvider);
          ref.invalidate(popularProvider);
          ref.invalidate(bannersProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                user.isNotEmpty ? '${greetingMessage()} $user' : greetingMessage(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Local promo banner (links to shad://l.shad.ir/TextStory)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: LocalBanner(),
              ),
            ),
            // Genre cards (Iranian categories)
            SliverToBoxAdapter(
              child: const SectionHeader(title: 'دسته‌بندی‌ها 🎭'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: genresList.length,
                  itemBuilder: (_, i) {
                    final g = genresList[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GenreScreen(genre: g.name)),
                      ),
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(g.imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          alignment: Alignment.bottomRight,
                          child: Text(g.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
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
