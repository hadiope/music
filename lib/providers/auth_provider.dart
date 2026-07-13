import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants.dart';

class AuthController {
  final SupabaseClient _auth = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    await _auth.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.auth.signOut();
  }

  /// Google sign-in (needs OAuth config in Supabase + Google console).
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }
    // Native flow — Google Web Client ID (from Google Cloud Console)
    const webClientId = '923347201603-bfkr04a0rur53oatp498ntnvv8btssed.apps.googleusercontent.com';
    final google = GoogleSignIn(serverClientId: webClientId);
    final account = await google.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    if (auth.idToken == null) return;
    await _auth.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: auth.idToken!,
      accessToken: auth.accessToken,
    );
  }
}

final authControllerProvider = Provider<AuthController>((ref) => AuthController());
