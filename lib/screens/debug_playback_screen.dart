import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/core_providers.dart';
import '../core/strings.dart';

/// Diagnostic screen: try to actually play a track and show the result on screen
/// (no need for logcat). Use this to isolate why playback fails on a device.
class DebugPlaybackScreen extends ConsumerStatefulWidget {
  const DebugPlaybackScreen({super.key});

  @override
  ConsumerState<DebugPlaybackScreen> createState() => _DebugPlaybackScreenState();
}

class _DebugPlaybackScreenState extends ConsumerState<DebugPlaybackScreen> {
  String _log = 'Tap a button to start...';
  bool _busy = false;

  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() {
      _busy = true;
      _log = '[$label] running...';
    });
    try {
      await fn();
      setState(() => _log = '[$label] ✅ DONE (no error thrown)');
    } catch (e) {
      setState(() => _log = '[$label] ❌ ERROR:\n$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.read(audioHandlerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Playback Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run('asset', () async {
                        final ok = await handler.playLocalFile(
                          'assets/audio/sample.mp3',
                          title: 'Offline test',
                        );
                        if (!ok) throw Exception('playLocalFile returned false');
                      }),
              child: const Text('Test 1: Play bundled asset (sample.mp3)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run('online', () async {
                        final err = await handler.setQueueSafe([
                          Song(
                            id: 'dbg1',
                            title: 'SoundHelix 1',
                            artist: 'Test',
                            audioUrl:
                                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                            coverUrl: '',
                          )
                        ], startIndex: 0);
                        if (err != null) throw Exception(err);
                      }),
              child: const Text('Test 2: Stream public URL (SoundHelix)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : () => _run('supabase', () async {
                        final err = await handler.setQueueSafe([
                          Song(
                            id: 'dbg2',
                            title: 'Khaar (Piano)',
                            artist: 'Test',
                            audioUrl:
                                'https://xhpglphhbchejhciepcr.supabase.co/storage/v1/object/public/songs/d062cab6-a0bd-4f3a-baa8-e6074893f7aa.mp3',
                            coverUrl: '',
                          )
                        ], startIndex: 0);
                        if (err != null) throw Exception(err);
                      }),
              child: const Text('Test 3: Stream from Supabase Storage'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('Result:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_log, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
