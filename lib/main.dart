import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background audio (notification + lock screen controls)
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.harmony.music.channel.audio',
      androidNotificationChannelName: 'Iranian Spotify',
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
}

class HarmonyApp extends ConsumerWidget {
  final bool supabaseReady;
  const HarmonyApp({super.key, this.supabaseReady = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Iranian Spotify',
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
      home: supabaseReady ? const SplashScreen() : const _SetupNeededScreen(),
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
              Text('Iranian Spotify', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
