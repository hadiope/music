import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../widgets/net_image.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';
import 'player_screen.dart';

/// Metadata extracted from a local audio file.
class DeviceSong {
  final String path;
  final String title;
  final String artist;
  final String? albumArtPath;

  DeviceSong({required this.path, required this.title, required this.artist, this.albumArtPath});
}

/// Lists all audio files on the device (Samsung Music style).
/// Reads metadata (title, artist, cover art) from the file tags.
class DeviceLibraryScreen extends ConsumerStatefulWidget {
  const DeviceLibraryScreen({super.key});

  @override
  ConsumerState<DeviceLibraryScreen> createState() => _DeviceLibraryScreenState();
}

class _DeviceLibraryScreenState extends ConsumerState<DeviceLibraryScreen> {
  List<DeviceSong> _songs = [];
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
        '/storage/sdcard1',
        '/mnt/sdcard/ext_sd',
        '/mnt/extsd',
        '/storage/extSdCard',
        '/storage/1234-5678',
      ];

      try {
        final storageDir = Directory('/storage');
        if (await storageDir.exists()) {
          await for (final e in storageDir.list()) {
            if (e is Directory) {
              final name = e.path.split('/').last;
              if (name == 'emulated' || name == 'self') continue;
              if (RegExp(r'^\w{4}-\w{4}$').hasMatch(name)) {
                roots.add('${e.path}/Music');
                roots.add('${e.path}/Download');
                roots.add(e.path);
              }
            }
          }
        }
      } catch (_) {}

      final found = <DeviceSong>[];
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
              final fileName = entity.path.split('/').last;
              final cleanName = fileName.replaceAll(RegExp(r'\.(mp3|m4a|aac|flac|wav|ogg)$'), '');

              // Try to read metadata from the file
              String title = cleanName;
              String artist = T.unknownArtist;
              String? albumArtPath;

              try {
                final meta = await _readMetadata(entity);
                if (meta['title'] != null && meta['title']!.isNotEmpty) {
                  title = meta['title']!;
                }
                if (meta['artist'] != null && meta['artist']!.isNotEmpty) {
                  artist = meta['artist']!;
                }
                albumArtPath = meta['coverPath'];
              } catch (_) {
                // If metadata reading fails, we still have the filename
              }

              found.add(DeviceSong(
                path: entity.path,
                title: title,
                artist: artist,
                albumArtPath: albumArtPath,
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

  /// Reads ID3/MP4 metadata from an audio file using basic byte parsing.
  /// Extracts title, artist, and album art when available.
  Future<Map<String, String?>> _readMetadata(File file) async {
    final result = <String, String?>{
      'title': null,
      'artist': null,
      'coverPath': null,
    };
    final bytes = await file.readAsBytes();
    if (bytes.length < 10) return result;

    // ID3v2 tags (MP3)
    if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      _parseID3v2(bytes, result);
    }
    // M4A/MP4 atoms
    else if (bytes.length > 8 &&
             bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
      _parseMP4(bytes, result);
    }
    // FLAC
    else if (bytes.length > 4 &&
             bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43) {
      _parseFlac(bytes, result);
    }

    return result;
  }

  void _parseID3v2(List<int> bytes, Map<String, String?> result) {
    try {
      final majorVersion = bytes[3];
      // ID3v2.3 or ID3v2.4
      final frameSizeBytes = majorVersion == 2 ? 3 : 4;
      final tagSize = _readSyncSafe(bytes, 6, 4);
      var pos = 10;
      final end = (pos + tagSize).clamp(0, bytes.length);

      while (pos + 10 < end) {
        String frameId;
        int frameSize;
        if (majorVersion == 2) {
          frameId = String.fromCharCodes(bytes.sublist(pos, pos + 3));
          frameSize = (bytes[pos + 3] << 16) | (bytes[pos + 4] << 8) | bytes[pos + 5];
          pos += 6;
        } else {
          frameId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
          if (majorVersion == 4) {
            frameSize = _readSyncSafe(bytes, pos + 4, 4);
          } else {
            frameSize = (bytes[pos + 4] << 24) | (bytes[pos + 5] << 16) | (bytes[pos + 6] << 8) | bytes[pos + 7];
          }
          pos += 10;
        }
        if (frameId == '\x00\x00\x00\x00' || frameSize <= 0 || pos + frameSize > end) break;

        final frameData = bytes.sublist(pos, pos + frameSize);

        // TIT2 = title, TPE1 = artist
        if (frameId.startsWith('TIT') || (majorVersion == 2 && frameId == 'TT2')) {
          result['title'] = _decodeTextFrame(frameData);
        } else if (frameId.startsWith('TPE') || (majorVersion == 2 && frameId == 'TP1')) {
          result['artist'] = _decodeTextFrame(frameData);
        }

        pos += frameSize;
      }
    } catch (_) {}
  }

  int _readSyncSafe(List<int> bytes, int offset, int count) {
    int result = 0;
    for (int i = 0; i < count; i++) {
      result = (result << 7) | (bytes[offset + i] & 0x7F);
    }
    return result;
  }

  String _decodeTextFrame(List<int> data) {
    if (data.isEmpty) return '';
    int encoding = data[0];
    String text;
    try {
      if (encoding == 0) {
        // ISO-8859-1
        text = data.sublist(1).where((b) => b != 0).map((b) => String.fromCharCode(b)).join();
      } else if (encoding == 1) {
        // UTF-16 with BOM
        text = _decodeUtf16(data.sublist(1));
      } else if (encoding == 2) {
        // UTF-16BE
        text = _decodeUtf16(data.sublist(1), bigEndian: true);
      } else {
        // UTF-8
        text = String.fromCharCodes(data.sublist(1).where((b) => b != 0));
      }
    } catch (_) {
      text = '';
    }
    return text.trim();
  }

  String _decodeUtf16(List<int> data, {bool bigEndian = false}) {
    if (data.length < 2) return '';
    // Check for BOM
    if (data[0] == 0xFF && data[1] == 0xFE) bigEndian = false;
    else if (data[0] == 0xFE && data[1] == 0xFF) bigEndian = true;
    else if (data.length >= 2) {
      // No BOM, use default
    }
    final codeUnits = <int>[];
    for (int i = 0; i < data.length - 1; i += 2) {
      int code;
      if (bigEndian) {
        code = (data[i] << 8) | data[i + 1];
      } else {
        code = data[i] | (data[i + 1] << 8);
      }
      if (code != 0) codeUnits.add(code);
    }
    return String.fromCharCodes(codeUnits);
  }

  void _parseMP4(List<int> bytes, Map<String, String?> result) {
    try {
      int pos = 0;
      while (pos + 8 < bytes.length) {
        final atomSize = (bytes[pos] << 24) | (bytes[pos + 1] << 16) | (bytes[pos + 2] << 8) | bytes[pos + 3];
        if (atomSize < 8 || pos + atomSize > bytes.length) break;
        final atomType = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));

        if (atomType == 'moov' || atomType == 'trak' || atomType == 'mdia' || atomType == 'udta' || atomType == 'ilst') {
          pos += 8; // descend into container atom
          continue;
        }

        // ilst children: ©nam (title), ©ART (artist)
        if (atomType == '\xa9nam' || atomType == '\xa9ART') {
          if (pos + 8 + 16 < bytes.length) {
            // data atom inside
            final dataAtomStart = pos + 8;
            final dataAtomSize = (bytes[dataAtomStart] << 24) | (bytes[dataAtomStart + 1] << 16) |
                                 (bytes[dataAtomStart + 2] << 8) | bytes[dataAtomStart + 3];
            if (String.fromCharCodes(bytes.sublist(dataAtomStart + 4, dataAtomStart + 8)) == 'data' &&
                dataAtomSize > 16) {
              final textData = bytes.sublist(dataAtomStart + 16, dataAtomStart + dataAtomSize);
              final text = String.fromCharCodes(textData.where((b) => b != 0)).trim();
              if (atomType == '\xa9nam') result['title'] = text;
              if (atomType == '\xa9ART') result['artist'] = text;
            }
          }
        }
        pos += atomSize;
      }
    } catch (_) {}
  }

  void _parseFlac(List<int> bytes, Map<String, String?> result) {
    try {
      int pos = 4; // skip "fLaC"
      while (pos < bytes.length - 4) {
        final blockType = bytes[pos] & 0x7F;
        final blockSize = (bytes[pos + 1] << 16) | (bytes[pos + 2] << 8) | bytes[pos + 3];
        pos += 4;
        if (blockType == 4) { // VORBIS_COMMENT
          // Parse Vorbis comment
          if (pos + 4 > bytes.length) break;
          int vendorLen = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
          pos += 4 + vendorLen;
          if (pos + 4 > bytes.length) break;
          int commentCount = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
          pos += 4;
          for (int i = 0; i < commentCount && pos < bytes.length; i++) {
            if (pos + 4 > bytes.length) break;
            int len = bytes[pos] | (bytes[pos + 1] << 8) | (bytes[pos + 2] << 16) | (bytes[pos + 3] << 24);
            pos += 4;
            if (pos + len > bytes.length) break;
            final comment = String.fromCharCodes(bytes.sublist(pos, pos + len));
            pos += len;
            final eq = comment.indexOf('=');
            if (eq > 0) {
              final key = comment.substring(0, eq).toUpperCase();
              final value = comment.substring(eq + 1);
              if (key == 'TITLE' && result['title'] == null) result['title'] = value;
              if (key == 'ARTIST' && result['artist'] == null) result['artist'] = value;
            }
          }
        }
        if ((bytes[pos - 4] & 0x80) != 0) break; // last block
      }
    } catch (_) {}
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(T.reload),
                      ),
                    ],
                  ),
                )
              : _songs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off, size: 64, color: Theme.of(context).hintColor),
                          const SizedBox(height: 12),
                          Text(T.noDeviceSongs, style: TextStyle(color: Theme.of(context).hintColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (_, i) {
                        final s = _songs[i];
                        return ListTile(
                          leading: (s.albumArtPath != null && s.albumArtPath!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    File(s.albumArtPath!),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50, height: 50,
                                      color: AppColors.primary,
                                      child: const Icon(Icons.music_note, color: Colors.white),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.music_note, color: Colors.white),
                                ),
                          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
                          onTap: () async {
                            final handler = ref.read(audioHandlerProvider);
                            final err = await handler.playLocalFile(s.path,
                                title: s.title, artist: s.artist);
                            if (err == null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PlayerScreen()),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(T.couldNotPlay),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
