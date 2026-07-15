import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/genres.dart';
import '../core/strings.dart';
import '../core/theme.dart';

/// Admin panel: upload a song (audio + cover) to Supabase Storage and add a row to `songs`.
class AdminUploadScreen extends ConsumerStatefulWidget {
  const AdminUploadScreen({super.key});
  @override
  ConsumerState<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends ConsumerState<AdminUploadScreen> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  String? _audioPath;
  String? _coverPath;
  String _genre = genresList.first.name;
  bool _uploading = false;
  String? _message;
  bool _msgOk = true;

  Future<void> _pickAudio() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (r != null) setState(() => _audioPath = r.files.single.path);
  }

  Future<void> _pickCover() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r != null) setState(() => _coverPath = r.files.single.path);
  }

  Future<void> _upload() async {
    if (_audioPath == null) {
      setState(() => _message = T.pickAudioRequired);
      return;
    }
    if (_title.text.trim().isEmpty || _artist.text.trim().isEmpty) {
      setState(() => _message = T.titleArtistRequired);
      return;
    }
    setState(() => _uploading = true);
    try {
      final supa = Supabase.instance.client;
      final songId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload audio
      final audioExt = _audioPath!.split('.').last;
      final audioFile = File(_audioPath!);
      await supa.storage.from('music').upload('$songId.$audioExt', audioFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
      final audioUrl = supa.storage.from('music').getPublicUrl('$songId.$audioExt');

      // Upload cover (optional)
      String coverUrl = 'https://picsum.photos/seed/$songId/400/400';
      if (_coverPath != null) {
        final coverExt = _coverPath!.split('.').last;
        final coverFile = File(_coverPath!);
        await supa.storage.from('covers').upload('$songId.$coverExt', coverFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
        coverUrl = supa.storage.from('covers').getPublicUrl('$songId.$coverExt');
      }

      // Insert song row
      await supa.from('songs').insert({
        'title': _title.text.trim(),
        'artist': _artist.text.trim(),
        'genre': _genre,
        'audio_url': audioUrl,
        'cover_url': coverUrl,
        'plays': 0,
      });

      setState(() {
        _message = T.songAdded;
        _msgOk = true;
        _title.clear();
        _artist.clear();
        _audioPath = null;
        _coverPath = null;
      });
    } catch (e) {
      setState(() => _message = T.errGeneric.replaceAll('{e}', e.toString()));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(T.addSongTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _title, decoration: InputDecoration(labelText: T.songTitleLabel, border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _artist, decoration: InputDecoration(labelText: T.artistNameLabel, border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _genre,
              decoration: InputDecoration(labelText: T.categoryLabel, border: const OutlineInputBorder()),
              items: genresList.map((g) => DropdownMenuItem(value: g.name, child: Text(g.name))).toList(),
              onChanged: (v) => setState(() => _genre = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(_audioPath == null ? T.addAudioFile : T.audioSelected),
              trailing: const Icon(Icons.upload_file),
              onTap: _pickAudio,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(_coverPath == null ? T.addCover : T.coverSelected),
              trailing: const Icon(Icons.upload_file),
              onTap: _pickCover,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _msgOk ? AppColors.primary.withOpacity(0.12) : Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_message!, style: TextStyle(color: _msgOk ? AppColors.primary : Colors.redAccent)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _uploading ? null : _upload,
              icon: _uploading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload),
              label: Text(_uploading ? T.uploading : T.publishSong),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 10),
            Text(T.uploadedNote,
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
