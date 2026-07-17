import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../providers/songs_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';

class GenreScreen extends ConsumerWidget {
  final String genre;
  const GenreScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tProvider); // sync language
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songsAsync = ref.watch(genreSongsProvider(genre));
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                genre,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary,
                      isDark ? AppColors.darkBg : AppColors.lightBg,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Text(
                T.lang == 'en' ? 'Popular in $genre' : 'محبوب‌ترین‌های $genre',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          songsAsync.when(
            data: (songs) => songs.isEmpty
                ? SliverFillRemaining(
                    child: Center(child: Text(T.noSongsInGenre)),
                  )
                : SliverList(
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
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            ),
            error: (e, __) => SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('${T.errorPrefix}$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
