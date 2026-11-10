import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/auth_service.dart';

class AuthSignUpResult {
  final bool authenticated;
  final bool requiresEmailConfirmation;

  const AuthSignUpResult({
    required this.authenticated,
    required this.requiresEmailConfirmation,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authSub;

  Session? _session;
  User? _user;
  bool _initializing = true;
  bool _loading = false;
  bool _isAdmin = false;

  Session? get session => _session;
  User? get user => _user;
  String? get accessToken => _session?.accessToken;
  bool get isAuthenticated => _session != null && _user != null;
  bool get initializing => _initializing;
  bool get loading => _loading;
  bool get isAdmin => _isAdmin;

  AuthProvider({
    AuthService? authService,
    bool autoInit = true,
    Session? initialSession,
    User? initialUser,
    bool initialIsAdmin = false,
  }) : _authService = authService ?? AuthService() {
    if (initialSession != null || initialUser != null) {
      _session = initialSession;
      _user = initialUser ?? initialSession?.user;
      _isAdmin = initialIsAdmin;
      _initializing = false;
    } else if (autoInit) {
      _init();
    } else {
      _initializing = false;
    }
  }

  void _init() {
    try {
      _session = _authService.currentSession;
      _user = _session?.user ?? _authService.currentUser;
      _initializing = false;
      if (_user != null) {
        _checkAdmin();
      }

      _authSub = _authService.authStateChanges.listen((data) {
        final nextSession = data.session;
        final nextUser = nextSession?.user;
        final changed = nextSession?.accessToken != _session?.accessToken ||
            nextUser?.id != _user?.id;

        _session = nextSession;
        _user = nextUser;
        _initializing = false;

        if (_user == null) {
          _isAdmin = false;
        } else if (changed) {
          _checkAdmin();
        }
        notifyListeners();
      });
    } catch (_) {
      _initializing = false;
    }
  }

  Future<void> _checkAdmin() async {
    if (_user == null) {
      if (_isAdmin) {
        _isAdmin = false;
        notifyListeners();
      }
      return;
    }
    final admin = await _authService.checkIsAdmin();
    if (admin != _isAdmin) {
      _isAdmin = admin;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _authService.signIn(email: email, password: password);
      _session = res.session ?? _authService.currentSession;
      _user = res.user ?? _session?.user;
      await _checkAdmin();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AuthSignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _session = res.session ?? _authService.currentSession;
      _user = _session?.user;
      if (_session != null && _user != null) {
        await _checkAdmin();
        return const AuthSignUpResult(
          authenticated: true,
          requiresEmailConfirmation: false,
        );
      }
      return AuthSignUpResult(
        authenticated: false,
        requiresEmailConfirmation: res.user != null && res.session == null,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _session = null;
      _user = null;
      _isAdmin = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      final updated = await _authService.updateDisplayName(trimmed);
      if (updated != null) {
        _user = updated;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
