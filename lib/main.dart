import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:uni_links/uni_links.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'core/strings.dart';
import 'providers/settings_provider.dart';
import 'providers/core_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/playlist_detail_screen.dart';
import 'models/playlist.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background audio (notification + lock screen controls)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.harmony.music.channel.audio',
      androidNotificationChannelName: 'Iranian Sedà',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init failed: $e');
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

  // Check for in-app update (Android only)
  _checkForUpdate();

  // Deep link handling (open shared playlist)
  _initUniLinks();
}

Future<void> _checkForUpdate() async {
  if (!kIsWeb) {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}

/// Parses a playlist deep link (https://thetextstory.com/playlist/<id>) and
/// navigates into the app directly to that playlist.
void _initUniLinks() {
  try {
    getInitialLink().then(_handleLink);
    linkStream.listen(_handleLink);
  } catch (e) {
    debugPrint('uni_links init failed: $e');
  }
}

void _handleLink(String? link) {
  if (link == null) return;
  final uri = Uri.tryParse(link);
  if (uri == null) return;
  if (uri.host == 'thetextstory.com' && uri.pathSegments.isNotEmpty) {
    // path like /playlist/<id>
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'playlist') {
      final id = uri.pathSegments[1];
      // We can't navigate here without a context; the SplashScreen/MainShell
      // will pick this up via a global navigator key if needed. For now,
      // store for the detail screen to read.
      _pendingPlaylistId = id;
      debugPrint('deep link playlist id: $id');
    }
  }
}

/// Shared across the app so PlaylistDetailScreen can be opened from a link.
String? _pendingPlaylistId;

class HarmonyApp extends ConsumerStatefulWidget {
  final bool supabaseReady;
  const HarmonyApp({super.key, this.supabaseReady = false});

  @override
  ConsumerState<HarmonyApp> createState() => _HarmonyAppState();
}

class _HarmonyAppState extends ConsumerState<HarmonyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    T.setLocale(locale.languageCode);

    return MaterialApp(
      title: 'Iranian Sedà',
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
      home: widget.supabaseReady ? const SplashScreen() : const _SetupNeededScreen(),
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
              Text('Iranian Sedà', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
