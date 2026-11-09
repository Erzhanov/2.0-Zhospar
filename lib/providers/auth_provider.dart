import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _loading = true;
  bool _isAdmin = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _loading = false;
    _checkAdmin();

    _authService.authStateChanges.listen((data) {
      _user = data.session?.user;
      _loading = false;
      _checkAdmin();
      notifyListeners();
    });
  }

  Future<void> _checkAdmin() async {
    if (_user == null) {
      _isAdmin = false;
    } else {
      _isAdmin = await _authService.checkIsAdmin();
    }
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _authService.signIn(email: email, password: password);
      _user = res.user;
      await _checkAdmin();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
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
      _user = res.user;
      await _checkAdmin();
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
      _user = null;
      _isAdmin = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
