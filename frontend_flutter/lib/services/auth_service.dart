import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static const _userKey = 'auth_user';
  final ApiService _apiService;

  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<String?> loadSignedInUser() async {
    if (kIsWeb) {
      final currentUser = FirebaseAuth.instance.currentUser;
      final email = currentUser?.email?.trim();
      if (email != null && email.isNotEmpty) {
        return email;
      }
      final displayName = currentUser?.displayName?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final username = value.trim();
    try {
      final exists = await _apiService.hasSession(username: username);
      if (!exists) {
        await prefs.remove(_userKey);
        return null;
      }
      return username;
    } catch (_) {
      // Keep local session when backend is temporarily unavailable.
      return username;
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required.');
    }

    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedUsername,
        password: password,
      );
      return;
    }

    final backendUsername = await _apiService.signIn(
      username: trimmedUsername,
      password: password,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, backendUsername.trim());
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      throw Exception('Username and password are required.');
    }

    if (kIsWeb) {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: trimmedUsername,
        password: password,
      );
      return;
    }

    final backendUsername = await _apiService.register(
      username: trimmedUsername,
      password: password,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, backendUsername.trim());
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_userKey)?.trim();
    if (kIsWeb) {
      await FirebaseAuth.instance.signOut();
      await prefs.remove(_userKey);
      return;
    }

    if (username != null && username.isNotEmpty) {
      try {
        await _apiService.signOut(username: username);
      } catch (_) {
        // Sign-out should still clear local state even if backend call fails.
      }
    }
    await prefs.remove(_userKey);
  }

  Future<void> signInWithGoogle() async {
    if (!kIsWeb) {
      throw Exception(
          'Google sign-in is currently configured for Flutter web only.');
    }

    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});

    await FirebaseAuth.instance.signInWithPopup(provider);
  }
}
