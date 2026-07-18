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
import '../core/app_route.dart';

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
      // On Android 13+ use Permission.audio; on older versions use storage.
      PermissionStatus status = await Permission.audio.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        // Last resort: try manage external storage (Android 11+)
        try {
          status = await Permission.manageExternalStorage.request();
        } catch (_) {}
      }
      if (!status.isGranted) {
        setState(() {
          _loading = false;
          _error = T.lang == 'en'
              ? 'Storage permission not granted'
              : 'دسترسی به حافظه داده نشد';
        });
        return;
      }

      // Expanded list of common music folders (internal + external SD).
      // Each path is checked individually so a missing/unmounted SD card
      // (e.g. /mnt/sdcard/ext_sd) does NOT crash the whole scan with a
      // Permission denied error.
      final roots = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Audio',
        '/storage/emulated/0/Sounds',
        '/storage/emulated/0/Recordings',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Podcasts',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
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
              if (name == 'emulated' || name == 'self') continue;
              // UUID-style mounts (e.g. 1234-5678) are external SD cards
              if (RegExp(r'^\w{4}-\w{4}$').hasMatch(name)) {
                roots.add('${e.path}/Music');
                roots.add('${e.path}/Download');
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
        try {
          final dir = Directory(root);
          // Skip paths we cannot even stat (unmounted SD, permission denied).
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
        } catch (e) {
          // A single inaccessible folder (e.g. /mnt/sdcard/ext_sd without
          // permission) must not abort the whole scan.
          debugPrint('skipping $root: $e');
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
                                    goToPlayer(context);
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
