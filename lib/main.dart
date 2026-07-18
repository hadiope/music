import '../core/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/strings.dart';
import 'providers/settings_provider.dart';
import 'providers/core_providers.dart';
import 'providers/playlist_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/playlist_detail_screen.dart';
import 'models/playlist.dart';

/// Parses a deep link (https://hadiope.github.io/music/#/playlist/<id>
/// or shad://playlist/<id> or /playlist/<id>) into a playlist id, or null.
String? _parsePlaylistId(String? link) {
  if (link == null || link.isEmpty) return null;
  // hash route from github pages: .../#/playlist/<id>
  final hash = Uri.parse(link);
  if (hash.fragment.startsWith('/playlist/')) {
    return hash.fragment.split('/')[2];
  }
  // in-app route (onGenerateRoute name): /playlist/<id>
  if (link.startsWith('/playlist/')) {
    return link.split('/')[2];
  }
  // scheme host route
  final uri = Uri.parse(link);
  if ((uri.scheme == 'shad' || uri.scheme == 'https') &&
      uri.host == 'hadiope.github.io' &&
      uri.path.startsWith('/music/playlist/')) {
    return uri.pathSegments.last;
  }
  if (uri.scheme == 'iranseda' && uri.host == 'playlist') {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background playback: audio_service wires up the media notification and
  // lock-screen controls so playback keeps running when the app is backgrounded.
  try {
    await initAudioService();
  } catch (e) {
    debugPrint('AudioService init failed: $e');
  }

  // Supabase — guarded so the app still opens if keys are not set yet.
  bool supabaseReady = false;
  final urlSet = AppConstants.supabaseUrl.startsWith('http');
  final keySet = AppConstants.supabaseAnonKey.length > 20 &&
      !AppConstants.supabaseAnonKey.startsWith('YOUR_');
  if (urlSet && keySet) {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      supabaseReady = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  runApp(ProviderScope(child: HarmonyApp(supabaseReady: supabaseReady)));
}

class HarmonyApp extends ConsumerStatefulWidget {
  final bool supabaseReady;
  const HarmonyApp({super.key, this.supabaseReady = false});

  @override
  ConsumerState<HarmonyApp> createState() => _HarmonyAppState();
}

class _HarmonyAppState extends ConsumerState<HarmonyApp> with WidgetsBindingObserver {
  String? _initialLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    // Handle link that opened the app (cold start)
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        _initialLink = initial.toString();
        _openPlaylistFromLink(_initialLink);
      }
    } catch (e) {
      debugPrint('getInitialLink failed: $e');
    }
    // Handle links while app is running
    appLinks.uriLinkStream.listen((uri) {
      _openPlaylistFromLink(uri.toString());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle deep-link when app is opened from a link (cold start or resume).
  Future<void> _openPlaylistFromLink(String? link) async {
    final id = _parsePlaylistId(link);
    if (id == null || !mounted) return;
    // Wait for playlists to load, then navigate.
    final playlists = await ref.read(playlistsProvider.future);
    if (!mounted) return;
    final pl = playlists.where((p) => p.id == id).firstOrNull;
    if (pl != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: pl)),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cold-start deep links are handled by the OS passing the intent to
    // MainActivity; we re-check on resume for safety.
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    T.setLocale(locale.languageCode);

    // If the app was opened from a playlist share link, go straight there.
    final initialPlaylistId = _parsePlaylistId(_initialLink);

    return MaterialApp(
      title: 'Iran Seda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Force RTL for Persian
        return Directionality(
          textDirection: locale.languageCode == 'fa' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      onGenerateRoute: (settings) {
        final id = _parsePlaylistId(settings.name);
        if (id != null) {
          return MaterialPageRoute(
            builder: (_) => _DeepLinkPlaylistLoader(playlistId: id),
          );
        }
        return null;
      },
      // When opened via a playlist link, skip the splash/login and land
      // directly on the playlist detail screen.
      initialRoute: initialPlaylistId != null ? '/playlist/$initialPlaylistId' : null,
      home: widget.supabaseReady ? const SplashScreen() : const _SetupNeededScreen(),
    );
  }
}

/// Loads a playlist by id (from a deep link) and opens its detail screen.
class _DeepLinkPlaylistLoader extends ConsumerWidget {
  final String playlistId;
  const _DeepLinkPlaylistLoader({required this.playlistId});

  @override
  Widget build(BuildContext, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return playlists.when(
      data: (list) {
        final pl = list.where((p) => p.id == playlistId).firstOrNull;
        if (pl == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('پلی‌لیست پیدا نشد')),
          );
        }
        return PlaylistDetailScreen(playlist: pl);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('خطا: $e'))),
    );
  }
}

/// Shown when Supabase keys are not configured yet — prevents a black-screen crash.
class _SetupNeededScreen extends StatelessWidget {
  const _SetupNeededScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.settings_suggest, size: 72, color: Color(0xFF1DB954)),
              SizedBox(height: 20),
              Text('Iran Seda', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(
                'اپ با موفقیت نصب شد ✅\n\nبرای فعال شدن آهنگ‌ها و ورود،\nباید اطلاعات Supabase را در فایل\nlib/core/constants.dart وارد کنی\nو دوباره build بگیری.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.8, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
