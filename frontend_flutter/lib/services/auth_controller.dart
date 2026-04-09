import 'package:flutter/material.dart';

import 'auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthService authService,
    String? initialUser,
  })  : _authService = authService,
        _user = initialUser;

  final AuthService _authService;
  String? _user;
  bool _working = false;

  String? get user => _user;
  bool get isSignedIn => _user != null;
  bool get working => _working;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (_working) {
      return;
    }
    _working = true;
    notifyListeners();
    try {
      await _authService.signIn(username: username, password: password);
      _user = username.trim();
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    if (_working) {
      return;
    }
    _working = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
      final signedInUser = await _authService.loadSignedInUser();
      _user = signedInUser;
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    if (_working) {
      return;
    }
    _working = true;
    notifyListeners();
    try {
      await _authService.register(username: username, password: password);
      _user = username.trim();
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_working) {
      return;
    }
    _working = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
    } finally {
      _working = false;
      notifyListeners();
    }
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    required AuthController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree.');
    return scope!.notifier!;
  }
}
