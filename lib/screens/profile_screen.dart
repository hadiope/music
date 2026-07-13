import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'admin_upload_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtl = TextEditingController();
  final _oldPassCtl = TextEditingController();
  final _newPassCtl = TextEditingController();
  bool _saving = false;
  String? _msg;
  bool _msgOk = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _oldPassCtl.dispose();
    _newPassCtl.dispose();
    super.dispose();
  }

  String _email() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return 'مهمان';
    if (u.email != null) return u.email!;
    return 'کاربر';
  }

  String _fullName() {
    final u = Supabase.instance.client.auth.currentUser;
    final meta = u?.userMetadata?['full_name'] ?? u?.userMetadata?['name'];
    return meta?.toString() ?? '';
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse(AppConstants.telegramChannel);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() { _saving = true; _msg = null; });
    try {
      await ref.read(authControllerProvider).updateName(name);
      setState(() { _msg = 'نام با موفقیت ذخیره شد'; _msgOk = true; });
    } catch (e) {
      setState(() { _msg = 'خطا: ${e.toString()}'; _msgOk = false; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final newP = _newPassCtl.text.trim();
    if (newP.length < 6) {
      setState(() { _msg = 'رمز جدید حداقل ۶ کاراکتر باشد'; _msgOk = false; });
      return;
    }
    setState(() { _saving = true; _msg = null; });
    try {
      await ref.read(authControllerProvider).changePassword(newP);
      _oldPassCtl.clear();
      _newPassCtl.clear();
      setState(() { _msg = 'رمز عبور با موفقیت تغییر کرد'; _msgOk = true; });
    } on AuthException catch (e) {
      setState(() { _msg = 'خطا: ${e.message}'; _msgOk = false; });
    } catch (e) {
      setState(() { _msg = 'خطا: ${e.toString()}'; _msgOk = false; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final name = _fullName();
    _nameCtl.text = name;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل و تنظیمات')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Text(
                (name.isNotEmpty ? name[0] : _email()[0]).toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(name.isNotEmpty ? name : _email(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Center(child: Text(_email(), style: const TextStyle(color: Colors.grey, fontSize: 13))),
          const SizedBox(height: 18),

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

          // Admin upload (for you to add music)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
              title: const Text('افزودن آهنگ (پنل مدیریت)'),
              subtitle: const Text('آهنگ جدید آپلود و منتشر کن'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUploadScreen())),
            ),
          ),

          const Divider(height: 28),

          // --- Edit name ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('نام نمایشی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameCtl,
                        decoration: const InputDecoration(
                          hintText: 'نام و نام خانوادگی',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton.filled(
                            onPressed: _saveName,
                            icon: const Icon(Icons.check),
                          ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // --- Change password ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('تغییر رمز عبور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextFormField(
                  controller: _newPassCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'رمز عبور جدید (حداقل ۶ کاراکتر)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : _changePassword,
                    child: const Text('تغییر رمز عبور'),
                  ),
                ),
              ],
            ),
          ),

          if (_msg != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _msgOk ? AppColors.primary.withOpacity(0.12) : Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_msg!, style: TextStyle(color: _msgOk ? AppColors.primary : Colors.redAccent, fontSize: 13)),
              ),
            ),
          ],

          const Divider(height: 28),

          // --- Appearance & language ---
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('تم تیره'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('درباره Iranian Spotify'),
            subtitle: const Text('نسخه ۱.۰.۰'),
            onTap: () {},
          ),

          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('خروج از حساب', style: TextStyle(color: Colors.redAccent)),
            onTap: () => ref.read(authControllerProvider).signOut(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
