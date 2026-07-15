import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import '../widgets/net_image.dart';
import 'player_screen.dart';

/// Lists all audio tracks stored on the device (with permission) and plays
/// them through the shared audio handler — a real on-device music player.
class DeviceSongsScreen extends ConsumerStatefulWidget {
  const DeviceSongsScreen({super.key});

  @override
  ConsumerState<DeviceSongsScreen> createState() => _DeviceSongsScreenState();
}

class _DeviceSongsScreenState extends ConsumerState<DeviceSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = true;
  bool _hasPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _hasPermission = await _audioQuery.permissionsStatus();
      if (!_hasPermission) {
        _hasPermission = await _audioQuery.permissionsRequest();
      }
      if (_hasPermission) {
        final list = await _audioQuery.querySongs(
          sortType: SongSortType.TITLE,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
        );
        if (mounted) setState(() => _songs = list);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider); // sync language
    return Scaffold(
      appBar: AppBar(
        title: Text(T.deviceSongsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: T.reload,
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${T.errorPrefix}$_error', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              T.storagePermissionRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.security),
              label: Text(T.grantPermission),
            ),
          ],
        ),
      );
    }
    if (_songs.isEmpty) {
      return Center(
        child: Text(
          T.noDeviceSongs,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (_, i) {
        final s = _songs[i];
        return ListTile(
          leading: QueryArtworkWidget(
            id: s.id,
            type: ArtworkType.AUDIO,
            artworkHeight: 48,
            artworkWidth: 48,
            borderRadius: 8,
            nullArtworkWidget: const CircleAvatar(child: Icon(Icons.music_note)),
          ),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            s.artist ?? T.unknownArtist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.play_arrow),
          onTap: () async {
            final handler = ref.read(audioHandlerProvider);
            final ok = await handler.playLocalFile(
              s.uri,
              title: s.title,
              artist: s.artist ?? '',
            );
            if (ok && mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(T.couldNotPlay)),
              );
            }
          },
        );
      },
    );
  }
}
