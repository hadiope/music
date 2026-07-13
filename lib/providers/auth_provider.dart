import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants.dart';

class AuthController {
  final SupabaseClient _auth = Supabase.instance.client;

  Future<void> signUp(String email, String password, {String? fullName}) async {
    await _auth.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty
          ? {'name': fullName, 'full_name': fullName}
          : null,
    );
    // Persist to profiles table too (for display + later editing)
    if (fullName != null && fullName.isNotEmpty) {
      try {
        final uid = _auth.auth.currentUser?.id;
        if (uid != null) {
          await _auth.from('profiles').upsert({
            'id': uid,
            'full_name': fullName,
          });
        }
      } catch (_) {
        // ignore — profile row is best-effort; RLS may block until policy set
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    await _auth.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.auth.signOut();
  }

  /// Update the signed-in user's display name + family.
  Future<void> updateName(String fullName) async {
    final uid = _auth.auth.currentUser?.id;
    if (uid == null) return;
    await _auth.auth.updateUser(UserAttributes(data: {
      'name': fullName,
      'full_name': fullName,
    }));
    try {
      await _auth.from('profiles').upsert({'id': uid, 'full_name': fullName});
    } catch (_) {
      // ignore
    }
  }

  /// Change password (requires a recent session; user must be logged in).
  Future<void> changePassword(String newPassword) async {
    await _auth.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Google sign-in (needs OAuth config in Supabase + Google console).
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }
    // Native flow — Google Web Client ID (from Google Cloud Console, Web Application type)
    const webClientId = '923347201603-7bporr7dd0hq45a19unoang281dd6a2n.apps.googleusercontent.com';
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
