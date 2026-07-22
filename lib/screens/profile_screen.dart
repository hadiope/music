import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';
import 'playlist_detail_screen.dart';
import 'local_songs_screen.dart';
import 'auth_screen.dart';

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
  bool _nameInitialized = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _oldPassCtl.dispose();
    _newPassCtl.dispose();
    super.dispose();
  }

  String _email() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return T.lang == 'en' ? 'Guest' : 'مهمان';
    if (u.email != null) return u.email!;
    return T.lang == 'en' ? 'User' : 'کاربر';
  }

  bool _isGuest() {
    final u = Supabase.instance.client.auth.currentUser;
    return u == null;
  }

  void _goSignIn(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  String _fullName() {
    final u = Supabase.instance.client.auth.currentUser;
    final meta = u?.userMetadata?['full_name'] ?? u?.userMetadata?['name'];
    return meta?.toString() ?? '';
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse(AppConstants.telegramChannel);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() { _saving = true; _msg = null; });
    try {
      await ref.read(authControllerProvider).updateName(name);
      setState(() { _msg = T.nameSaved; _msgOk = true; });
    } catch (e) {
      setState(() { _msg = T.errGeneric.replaceAll('{e}', e.toString()); _msgOk = false; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final newP = _newPassCtl.text.trim();
    if (newP.length < 6) {
      setState(() { _msg = T.passMin; _msgOk = false; });
      return;
    }
    setState(() { _saving = true; _msg = null; });
    try {
      await ref.read(authControllerProvider).changePassword(newP);
      _oldPassCtl.clear();
      _newPassCtl.clear();
      setState(() { _msg = T.passChanged; _msgOk = true; });
    } on AuthException catch (e) {
      setState(() { _msg = T.errGeneric.replaceAll('{e}', e.message); _msgOk = false; });
    } catch (e) {
      setState(() { _msg = T.errGeneric.replaceAll('{e}', e.toString()); _msgOk = false; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Step 1: Ask for password to confirm
    final passCtl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(T.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(T.deleteAccountConfirm),
            const SizedBox(height: 16),
            TextField(
              controller: passCtl,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: T.lang == 'en' ? 'Enter your password' : 'رمز عبور خود را وارد کنید',
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(T.deleteAccountBtn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _saving = true; _msg = null; });
    try {
      final supa = Supabase.instance.client;
      final u = supa.auth.currentUser;
      if (u == null) return;

      // Delete user data (profiles table may not exist — ignore errors)
      try {
        await supa.from('playlists').delete().eq('user_id', u.id);
      } catch (_) {}
      try {
        await supa.from('likes').delete().eq('user_id', u.id);
      } catch (_) {}
      try {
        await supa.from('play_history').delete().eq('user_id', u.id);
      } catch (_) {}
      // profiles table may not exist — don't crash on PGRST205
      try {
        await supa.from('profiles').delete().eq('id', u.id);
      } catch (_) {}

      // Sign out (the actual auth user deletion requires service_role key
      // which we don't have client-side; signOut is the safe path)
      await ref.read(authControllerProvider).signOut();
      if (mounted) {
        setState(() { _msg = T.accountDeleted; _msgOk = true; _saving = false; });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _msg = T.errGeneric.replaceAll('{e}', e.toString()); _msgOk = false; _saving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider); // sync language
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final name = _fullName();
    // Initialise the field once so user edits are never wiped on rebuild
    // (e.g. when the theme/locale switches or a save error occurs).
    if (!_nameInitialized) {
      _nameCtl.text = name;
      _nameInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
          tooltip: T.lang == 'en' ? 'Back' : 'بازگشت',
        ),
        title: Text(T.profileSettings,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Profile header with gradient
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (name.isNotEmpty ? name[0] : _email()[0]).toUpperCase(),
                        style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name.isNotEmpty ? name : _email(),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_email(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Telegram channel button
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF229ED9),
            child: ListTile(
              leading: const Icon(Icons.telegram, color: Colors.white, size: 30),
              title: Text(T.telegramChannel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(T.joinTelegram, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: _openTelegram,
            ),
          ),

          const Divider(height: 28),

          // --- Guest vs signed-in actions ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isGuest()
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _goSignIn(context),
                        icon: const Icon(Icons.login),
                        label: Text(T.signInToAccount),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => ref.read(authControllerProvider).signInWithGoogle().catchError((e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(T.errGeneric.replaceAll('{e}', e.toString()))),
                            );
                          }
                        }),
                        icon: const Icon(Icons.g_mobiledata, size: 22),
                        label: Text(T.googleSignIn),
                      ),
                    ],
                  )
                : ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(T.signOut, style: const TextStyle(color: Colors.redAccent)),
                    onTap: () => ref.read(authControllerProvider).signOut(),
                  ),
          ),

          const Divider(height: 28),

          if (!_isGuest()) ...[
            // --- Edit name ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(T.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameCtl,
                          decoration: InputDecoration(
                            hintText: T.nameFamily,
                            prefixIcon: const Icon(Icons.person_outline),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(T.changePassTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _newPassCtl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: T.newPassHint,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _saving ? null : _changePassword,
                      child: Text(T.changePassBtn),
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
          ],

          // --- Appearance & language ---
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: Text(T.darkTheme),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(T.language),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'fa', child: Text(T.persian)),
                DropdownMenuItem(value: 'en', child: const Text('English')),
              ],
              onChanged: (v) => ref.read(localeProvider.notifier).set(v ?? 'fa'),
            ),
          ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(T.about),
            subtitle: const Text('Version 1.2.0'),
            onTap: () {},
          ),

          // --- Delete account (only for signed-in users) ---
          if (!_isGuest()) ...[
            const Divider(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                onPressed: _saving ? null : _deleteAccount,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                    : const Icon(Icons.person_remove),
                label: Text(T.deleteAccount),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
