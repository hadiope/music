import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/strings.dart';
import '../providers/core_providers.dart';

/// Pick audio files from the device and play them locally (no upload).
/// Perfect for building a personal offline playlist.
class LocalSongsScreen extends ConsumerStatefulWidget {
  const LocalSongsScreen({super.key});
  @override
  ConsumerState<LocalSongsScreen> createState() => _LocalSongsScreenState();
}

class _LocalSongsScreenState extends ConsumerState<LocalSongsScreen> {
  final List<PlatformFile> _files = [];
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: false,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() => _files.addAll(res.files.where((f) => f.path != null)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${T.errorPrefix}$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _name(PlatformFile f) => f.name.replaceAll(RegExp(r'\.[^.]+$'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(T.localFiles)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _pick,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.folder_open),
                label: Text(T.lang == 'en' ? 'Add from device' : T.addFromDevice),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.audio_file_outlined, size: 64, color: Theme.of(context).hintColor),
                        const SizedBox(height: 12),
                        Text(T.noResults, style: TextStyle(color: Theme.of(context).hintColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (_, i) {
                      final f = _files[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.music_note)),
                        title: Text(_name(f), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${(f.size / 1048576).toStringAsFixed(1)} MB'),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () {
                          ref.read(audioHandlerProvider).playLocalFile(f.path!, title: _name(f));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(T.playingPrefix + _name(f))),
                          );
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
