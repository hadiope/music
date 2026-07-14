import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Guest sign-in: stores a sessionless guest flag so the app can be used
  /// without an account. We still create an anonymous-like local state via
  /// SharedPreferences (handled in AuthController caller). Here we just mark
  /// a guest so the splash screen lets them in.
  static const _guestKey = 'is_guest';

  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestKey) ?? false;
  }

  Future<void> signOut() async {
    await _auth.auth.signOut().catchError((_) {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
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
}

final authControllerProvider = Provider<AuthController>((ref) => AuthController());
