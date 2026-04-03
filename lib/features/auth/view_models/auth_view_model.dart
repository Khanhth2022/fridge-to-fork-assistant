import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/auth/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService authService;
  final AuthRepository authRepository;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  AuthViewModel({required this.authService, required this.authRepository}) {
    _initializeUser();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _user?.email;
  String? get userId => _user?.uid;

  // Initialize user from Firebase
  Future<void> _initializeUser() async {
    _user = authService.currentUser;
    _isLoggedIn = _user != null;

    if (_isLoggedIn && _user != null) {
      // Save user info locally
      await authRepository.saveUserInfo(
        userId: _user!.uid,
        email: _user!.email ?? '',
      );
    }
    notifyListeners();
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        throw 'Mật khẩu không khớp';
      }

      if (password.length < 6) {
        throw 'Mật khẩu phải có ít nhất 6 ký tự';
      }

      final credential = await authService.registerWithEmail(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        _user = credential!.user;
        _isLoggedIn = true;

        // Save user info locally
        await authRepository.saveUserInfo(
          userId: _user!.uid,
          email: _user!.email ?? '',
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Vui lòng nhập email và mật khẩu';
      }

      final credential = await authService.loginWithEmail(
        email: email,
        password: password,
      );

      if (credential?.user != null) {
        _user = credential!.user;
        _isLoggedIn = true;

        // Save user info locally
        await authRepository.saveUserInfo(
          userId: _user!.uid,
          email: _user!.email ?? '',
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await authService.loginWithGoogle();
      if (credential?.user == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = credential!.user;
      _isLoggedIn = true;

      await authRepository.saveUserInfo(
        userId: _user!.uid,
        email: _user!.email ?? '',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.signOut();
      await authRepository.clearUserInfo();

      _user = null;
      _isLoggedIn = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (email.isEmpty) {
        throw 'Vui lòng nhập email';
      }

      await authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
