import '../core/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.trim().length < 6) {
      setState(() => _error = T.authFillFields);
      return;
    }
    if (!_isLogin && _name.text.trim().isEmpty) {
      setState(() => _error = T.authFillName);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(authControllerProvider);
      if (_isLogin) {
        await auth.signIn(_email.text.trim(), _password.text.trim());
      } else {
        await auth.signUp(_email.text.trim(), _password.text.trim(),
            fullName: _name.text.trim());
      }
    } catch (e) {
      setState(() => _error = _cleanError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guest() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).continueAsGuest();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      setState(() => _error = _cleanError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
      // OAuth opens a browser; the deep-link callback brings the user back
      // and the splash screen will pick up the session.
    } catch (e) {
      setState(() => _error = _cleanError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(String e) {
    return e
        .replaceAll('AuthException', '')
        .replaceAll('Exception:', '')
        .replaceAll('PostgrestException', '')
        .replaceAll('ApiException', '')
        .replaceAll(RegExp(r'message:\s*'), '')
        .trim();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.30),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App icon
                  Hero(
                    tag: 'appIcon',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/login_logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [AppColors.primary, Colors.tealAccent],
                    ).createShader(b),
                    child: const Text('Iran Seda',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  Text(_isLogin ? T.loginHint : T.signUpHint,
                      textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 30),

                  // Name field (sign up only)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _isLogin ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    secondChild: const SizedBox.shrink(),
                    firstChild: Column(
                      children: [
                        TextField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: T.fullNameLabel,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: T.emailLabel,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: T.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(_isLogin ? T.loginBtn : T.signUpBtn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(T.or, style: const TextStyle(fontSize: 12))),
                      Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _google,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text(T.googleSignIn),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _guest,
                    icon: const Icon(Icons.person_outline),
                    label: const Text(T.guestSignIn),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? T.noAccount : T.hasAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
