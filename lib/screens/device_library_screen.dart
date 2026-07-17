import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../widgets/net_image.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';
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
      final status = await Permission.audio.request();
      if (!status.isGranted) {
        final legacy = await Permission.storage.request();
        if (!legacy.isGranted) {
          setState(() {
            _loading = false;
            _error = T.lang == 'en'
                ? 'Storage permission not granted'
                : 'دسترسی به حافظه داده نشد';
          });
          return;
        }
      }

      final roots = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Sounds',
        '/storage/emulated/0/Recordings',
        // Common SD card mount points (external volumes)
        '/storage/sdcard1',
        '/mnt/sdcard/ext_sd',
        '/mnt/extsd',
        '/storage/extSdCard',
      ];

      // Auto-detect mounted SD cards under /storage/<uuid>/
      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          await for (final e in storageDir.list()) {
            if (e is Directory) {
              final name = e.path.split('/').last;
              // skip the emulated (internal) volume
              if (name == 'emulated' || name == 'self') continue;
              // UUID-style mounts (e.g. 1234-5678) are external SD cards
              if (RegExp(r'^\w{4}-\w{4}$').hasMatch(name)) {
                roots.add('${e.path}/Music');
                roots.add(e.path);
              }
            }
          }
        }
      } catch (_) {
        // ignore — we still scan the fixed roots above
      }

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
    ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(T.myMusic),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Offline test song (always works — bundled in the app)
          ListTile(
            leading: const Icon(Icons.audiotrack, color: Color(0xFF1DB954)),
            title: Text(T.lang == 'en' ? 'Offline test playback' : 'پخش تست (آفلاین)'),
            subtitle: Text(T.lang == 'en'
                ? 'If this plays, the issue is the songs being filtered'
                : 'اگه این پخش شد، مشکل از فیلتر بودن آهنگ‌هاست'),
            onTap: () async {
              final handler = ref.read(audioHandlerProvider);
              final err = await handler.playLocalFile(
                'assets/audio/sample.mp3',
                title: T.lang == 'en' ? 'Offline test' : 'تست آفلاین',
                artist: 'Iran Seda',
              );
              final ok = err == null;
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? (T.lang == 'en' ? 'Playing offline test ✓' : 'در حال پخش تست آفلاین ✓')
                        : (T.lang == 'en' ? 'Offline test FAILED: $err' : 'تست آفلاین شکست خورد: $err')),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
                if (ok) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                }
              }
            },
          ),
          // Online test (SoundHelix) — checks if network streaming works at all
          ListTile(
            leading: const Icon(Icons.cloud, color: Color(0xFF1DB954)),
            title: Text(T.lang == 'en' ? 'Online test playback' : 'پخش تست (آنلاین)'),
            subtitle: Text(T.lang == 'en'
                ? 'Streams a public test MP3 to isolate network issues'
                : 'یه MP3 عمومی پخش می‌کنه تا مشکل شبکه مشخص شه'),
            onTap: () async {
              final handler = ref.read(audioHandlerProvider);
              final err = await handler.setQueueSafe([
                Song(
                  id: 'test_online',
                  title: 'SoundHelix Test',
                  artist: 'Test',
                  audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                  coverUrl: '',
                )
              ], startIndex: 0);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err == null
                        ? (T.lang == 'en' ? 'Playing online test ✓' : 'در حال پخش تست آنلاین ✓')
                        : (T.lang == 'en' ? 'Online test FAILED: $err' : 'تست آنلاین شکست خورد: $err')),
                    backgroundColor: err == null ? Colors.green : Colors.red,
                  ),
                );
                if (err == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _songs.isEmpty
                        ? Center(child: Text(T.noDeviceSongs))
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
                                  final err = await handler.playLocalFile(s.audioUrl,
                                      title: s.title, artist: s.artist);
                                  if (err == null && context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطا: $err'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
