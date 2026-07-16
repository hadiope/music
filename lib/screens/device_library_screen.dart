import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../widgets/net_image.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import 'player_screen.dart';

/// Lists all audio files on the device (Samsung Music style).
class DeviceLibraryScreen extends ConsumerStatefulWidget {
  const DeviceLibraryScreen({super.key});

  @override
  ConsumerState<DeviceLibraryScreen> createState() => _DeviceLibraryScreenState();
}

class _DeviceLibraryScreenState extends ConsumerState<DeviceLibraryScreen> {
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Request storage permission (scoped to audio on modern Android)
      final status = await Permission.audio.request();
      if (!status.isGranted) {
        // Fallback for older Android
        final legacy = await Permission.storage.request();
        if (!legacy.isGranted) {
          setState(() {
            _loading = false;
            _error = 'دسترسی به حافظه داده نشد';
          });
          return;
        }
      }

      final roots = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Audio',
      ];

      final found = <Song>[];
      for (final root in roots) {
        final dir = Directory(root);
        if (!await dir.exists()) continue;
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final ext = entity.path.toLowerCase();
            if (ext.endsWith('.mp3') ||
                ext.endsWith('.m4a') ||
                ext.endsWith('.aac') ||
                ext.endsWith('.flac') ||
                ext.endsWith('.wav') ||
                ext.endsWith('.ogg')) {
              final name = entity.path.split('/').last;
              found.add(Song(
                id: 'device_${entity.path.hashCode}',
                title: name.replaceAll(RegExp(r'\.(mp3|m4a|aac|flac|wav|ogg)$'), ''),
                artist: 'دستگاه',
                audioUrl: entity.path,
                coverUrl: '',
                genre: '',
                album: '',
                plays: 0,
              ));
            }
          }
        }
      }

      setState(() {
        _songs = found;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('آهنگ‌های دستگاه'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _songs.isEmpty
                  ? const Center(child: Text('آهنگی در حافظه پیدا نشد'))
                  : ListView.separated(
                      itemCount: _songs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = _songs[i];
                        return ListTile(
                          leading: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(s.artist),
                          onTap: () async {
                            final handler = ref.read(audioHandlerProvider);
                            final ok = await handler.playLocalFile(s.audioUrl,
                                title: s.title, artist: s.artist);
                            if (ok && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PlayerScreen()),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
