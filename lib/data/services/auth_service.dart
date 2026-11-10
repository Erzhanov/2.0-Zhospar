import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated =>
      _client.auth.currentSession != null && _client.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null && displayName.isNotEmpty
          ? {'display_name': displayName.trim()}
          : null,
    );

    if (res.user != null &&
        res.session != null &&
        displayName != null &&
        displayName.isNotEmpty) {
      try {
        await _client.from('profiles').upsert({
          'user_id': res.user!.id,
          'display_name': displayName.trim(),
          'theme': 'light',
        });
      } catch (_) {}
    }

    return res;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<User?> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return currentUser;
    final res = await _client.auth.updateUser(
      UserAttributes(data: {'display_name': trimmed}),
    );
    final updated = res.user ?? currentUser;
    if (updated != null) {
      try {
        await _client.from('profiles').upsert({
          'user_id': updated.id,
          'display_name': trimmed,
        });
      } catch (_) {}
    }
    return updated;
  }

  Future<bool> checkIsAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    try {
      final res = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .eq('role', 'admin')
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }
}
