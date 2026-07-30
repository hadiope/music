import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/local_song.dart';
import '../core/theme.dart';
import '../core/strings.dart';
import '../providers/local_music_provider.dart';
import '../widgets/glassmorphism.dart';
import '../widgets/blur_up_image.dart';
import '../widgets/song_tile.dart';
import 'player_screen.dart';
import 'local_artist_screen.dart';
import 'local_album_screen.dart';

class LocalMusicScreen extends ConsumerStatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  ConsumerState<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends ConsumerState<LocalMusicScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: '🎵 آهنگ‌ها'),
    Tab(text: '🎤 خوانندگان'),
    Tab(text: '💿 آلبوم‌ها'),
    Tab(text: '📁 پوشه‌ها'),
    Tab(text: '❤️ محبوب‌ها'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSongs = ref.watch(allLocalSongsProvider);
    final artists = ref.watch(localArtistsProvider);
    final albums = ref.watch(localAlbumsProvider);
    final favorites = ref.watch(localFavoritesProvider);
    final stats = ref.watch(localStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          T.myMusic,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? AppColors.darkBg : AppColors.lightBg).withOpacity(0.95),
                Colors.transparent,
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: ColoredBox(
            color: (isDark ? AppColors.darkBg : AppColors.lightBg).withOpacity(0.95),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(localMusicServiceProvider).scanDevice(force: true),
            tooltip: T.reload,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'stats') _showStatsDialog(context, stats);
              if (value == 'rescan') ref.read(localMusicServiceProvider).scanDevice(force: true);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'stats', child: Row(children: [const Icon(Icons.analytics), const SizedBox(width: 8), Text(T.about)])),
              PopupMenuItem(value: 'rescan', child: Row(children: [const Icon(Icons.refresh), const SizedBox(width: 8), Text(T.reload)])),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: All Songs
          _buildSongsTab(allSongs),
          // Tab 1: Artists
          _buildArtistsTab(artists),
          // Tab 2: Albums
          _buildAlbumsTab(albums),
          // Tab 3: Folders (placeholder - needs folder scanning)
          _buildFoldersTab(),
          // Tab 4: Favorites
          _buildFavoritesTab(favorites),
        ],
      ),
    );
  }

  Widget _buildSongsTab(AsyncValue<List<LocalSong>> songsAsync) {
    return songsAsync.when(
      data: (songs) => songs.isEmpty
          ? _emptyState(T.noDeviceSongs, Icons.music_off)
          : RefreshIndicator(
              onRefresh: () async => ref.read(localMusicServiceProvider).scanDevice(force: true),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: songs.length,
                itemBuilder: (_, i) {
                  final song = songs[i];
                  return SongTile(
                    song: Song(
                      id: song.id,
                      title: song.title,
                      artist: song.artist,
                      album: song.album,
                      coverUrl: song.albumArtPath ?? '',
                      audioUrl: song.filePath,
                      durationMs: song.durationMs,
                      genre: song.genre,
                    ),
                    onTap: () => _playSong(context, songs, i),
                    leading: _buildLocalLeading(song),
                  ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.1);
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildArtistsTab(AsyncValue<List<String>> artistsAsync) {
    return artistsAsync.when(
      data: (artists) => artists.isEmpty
          ? _emptyState('هنوز خواننده‌ای پیدا نشد', Icons.person_off)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: artists.length,
              itemBuilder: (_, i) {
                final artist = artists[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      artist.isNotEmpty ? artist[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  title: Text(artist, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: FutureBuilder<int>(
                    future: _getArtistSongCount(artist),
                    builder: (context, snap) => Text(
                      '${snap.data ?? 0} آهنگ',
                      style: const TextStyle(color: AppColors.greyText, fontSize: 13),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.greyText),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LocalArtistScreen(artistName: artist)),
                  ),
                ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.1);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Future<int> _getArtistSongCount(String artist) async {
    final songs = await ref.read(localMusicServiceProvider).getSongsByArtist(artist);
    return songs.length;
  }

  Widget _buildAlbumsTab(AsyncValue<List<MapEntry<String, String>>> albumsAsync) {
    return albumsAsync.when(
      data: (albums) => albums.isEmpty
          ? _emptyState('هنوز آلبومی پیدا نشد', Icons.album_outlined)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: albums.length,
              itemBuilder: (_, i) {
                final album = albums[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<String?>(
                      future: _getAlbumArt(album.key),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data!.isNotEmpty) {
                          return Image.file(File(snap.data!), width: 56, height: 56, fit: BoxFit.cover);
                        }
                        return Container(
                          width: 56,
                          height: 56,
                          color: AppColors.primary.withOpacity(0.3),
                          child: const Icon(Icons.album, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  title: Text(album.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(album.value, style: const TextStyle(color: AppColors.greyText, fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.greyText),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LocalAlbumScreen(albumName: album.key, artistName: album.value)),
                  ),
                ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.1);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Future<String?> _getAlbumArt(String album) async {
    final songs = await ref.read(localMusicServiceProvider).getSongsByAlbum(album);
    for (final song in songs) {
      if (song.albumArtPath != null && song.albumArtPath!.isNotEmpty) {
        return song.albumArtPath;
      }
    }
    return null;
  }

  Widget _buildFoldersTab() {
    return _emptyState('پشتیبانی از پوشه‌ها در نسخه‌های آینده', Icons.folder_open);
  }

  Widget _buildFavoritesTab(AsyncValue<List<LocalSong>> favoritesAsync) {
    return favoritesAsync.when(
      data: (songs) => songs.isEmpty
          ? _emptyState('هنوز آهنگ محبوبی نداری', Icons.favorite_border)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final song = songs[i];
                return SongTile(
                  song: Song(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    album: song.album,
                    coverUrl: song.albumArtPath ?? '',
                    audioUrl: song.filePath,
                    durationMs: song.durationMs,
                    genre: song.genre,
                  ),
                  onTap: () => _playSong(context, songs, i),
                  leading: _buildLocalLeading(song),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.primary, size: 22),
                    onPressed: () => ref.read(localMusicServiceProvider).toggleFavorite(song.id),
                  ),
                ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.1);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildLocalLeading(LocalSong song) {
    if (song.albumArtPath != null && song.albumArtPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(song.albumArtPath!),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultLeading(),
        ),
      );
    }
    return _defaultLeading();
  }

  Widget _defaultLeading() => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.music_note, color: AppColors.primary, size: 24),
      );

  void _playSong(BuildContext context, List<LocalSong> queue, int index) {
    final handler = ref.read(audioHandlerProvider);
    final songs = queue.map((s) => Song(
      id: s.id,
      title: s.title,
      artist: s.artist,
      album: s.album,
      coverUrl: s.albumArtPath ?? '',
      audioUrl: s.filePath,
      durationMs: s.durationMs,
      genre: s.genre,
    )).toList();
    
    handler.setQueueSafe(songs, startIndex: index).then((err) {
      if (err == null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $err'), backgroundColor: Colors.red));
      }
    });
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade500), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ref.read(localMusicServiceProvider).scanDevice(force: true),
            icon: const Icon(Icons.refresh),
            label: Text(T.reload),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('خطا: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(localMusicServiceProvider).scanDevice(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(T.reload),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context, AsyncValue<Map<String, int>> stats) {
    stats.when(
      data: (s) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آمار موسیقی محلی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statRow('🎵 آهنگ‌ها', s['songs']?.toString() ?? '0'),
              _statRow('🎤 خوانندگان', s['artists']?.toString() ?? '0'),
              _statRow('💿 آلبوم‌ها', s['albums']?.toString() ?? '0'),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
        ),
      ),
      loading: () {},
      error: (e, _) => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('خطا'), content: Text(e.toString()))),
    );
  }

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: const TextStyle(fontSize: 16)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))],
        ),
      );
}

