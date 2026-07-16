import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/greetings.dart';
import '../core/genres.dart';
import '../core/strings.dart';
import '../widgets/net_image.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/song_tile.dart';
import '../widgets/ui_kit.dart';
import '../core/theme.dart';
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
    ref.watch(tProvider); // sync language
    final newReleases = ref.watch(newReleasesProvider);
    final popular = ref.watch(popularProvider);
    final user = _userName();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(newReleasesProvider);
          ref.invalidate(popularProvider);
          ref.invalidate(bannersProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Spotify-style plain header: white text on black, no gradient
            SliverAppBar(
              expandedHeight: 96,
              floating: true,
              pinned: false,
              backgroundColor: AppColors.darkBg,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.isNotEmpty ? '${greetingMessage()} $user' : greetingMessage(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                T.lang == 'en' ? 'Iran Seda Music' : 'آهنگ‌های ایران‌سدا',
                                style: const TextStyle(fontSize: 13, color: AppColors.greyText),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.darkElevated,
                          child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Local promo banner (links to shad.ir/TextStory)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 12, left: 16, right: 16),
                child: LocalBanner(),
              ),
            ),
            // Genre cards (Iranian categories) — rounded, shadowed
            SliverToBoxAdapter(
              child: SectionHeader(title: T.categories),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemCount: genresList.length,
                  itemBuilder: (_, i) {
                    final g = genresList[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GenreScreen(genre: g.name)),
                      ),
                      child: Container(
                        width: 124,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NetImage(g.imageUrl, width: 124, height: 140, radius: 0),
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
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
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
            // New releases
            SliverToBoxAdapter(
              child: SectionHeader(title: '${T.newReleases} 🆕'),
            ),
            SliverToBoxAdapter(
              child: newReleases.when(
                data: (songs) => SizedBox(
                  height: 210,
                  child: songs.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: songs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) => SongCard(
                            song: songs[i],
                            onTap: () {
                              ref.read(playSongProvider).playQueue(songs, i);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                            },
                          ),
                        ),
                ),
                loading: () => const SizedBox(height: 210, child: Center(child: CircularProgressIndicator())),
                error: (e, __) => Padding(padding: const EdgeInsets.all(16), child: Text('${T.errorPrefix}$e')),
              ),
            ),
            // Popular
            SliverToBoxAdapter(
              child: SectionHeader(title: '${T.popular} 🔥'),
            ),
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
              error: (e, __) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text('${T.errorPrefix}$e'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
