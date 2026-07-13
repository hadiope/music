import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openTelegram() async {
    final uri = Uri.parse(AppConstants.telegramChannel);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          const Center(child: CircleAvatar(radius: 44, child: Icon(Icons.person, size: 48))),
          const SizedBox(height: 12),
          Center(child: Text(user?.email ?? 'مهمان', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),

          // Telegram channel button
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF229ED9),
            child: ListTile(
              leading: const Icon(Icons.telegram, color: Colors.white, size: 30),
              title: const Text('کانال تلگرام ما', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('عضو شو و از آهنگای جدید باخبر شو', style: TextStyle(color: Colors.white70, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: _openTelegram,
            ),
          ),

          // Theme toggle
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('تم تیره'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('زبان'),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) => ref.read(localeProvider.notifier).set(v ?? 'fa'),
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('خروج از حساب', style: TextStyle(color: Colors.redAccent)),
            onTap: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
