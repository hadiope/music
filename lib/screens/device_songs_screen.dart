import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';
import 'player_screen.dart';

/// Lets the user pick audio files from the device and play them through the
/// shared audio handler — a lightweight on-device music player that avoids
/// the heavy on_audio_query plugin (incompatible with the current AGP).
class DeviceSongsScreen extends ConsumerStatefulWidget {
  const DeviceSongsScreen({super.key});

  @override
  ConsumerState<DeviceSongsScreen> createState() => _DeviceSongsScreenState();
}

class _DeviceSongsScreenState extends ConsumerState<DeviceSongsScreen> {
  final List<File> _files = [];
  bool _loading = false;
  String? _error;

  Future<void> _pick() async {
    setState(() => _loading = true);
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (r != null && r.files.isNotEmpty) {
        final picked = r.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
        if (mounted) setState(() => _files.addAll(picked));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _name(File f) => f.path.split('/').last;

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
            onPressed: _pick,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _pick,
        tooltip: T.addAudioFile,
        child: _loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${T.errorPrefix}$_error', style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              T.noDeviceSongs,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _pick,
              icon: const Icon(Icons.audio_file),
              label: Text(T.addAudioFile),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (_, i) {
        final f = _files[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.music_note)),
          title: Text(_name(f), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.play_arrow),
          onTap: () async {
            final handler = ref.read(audioHandlerProvider);
            final ok = await handler.playLocalFile(f.path, title: _name(f));
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
