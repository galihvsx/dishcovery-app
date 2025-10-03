import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/services/firebase_auth_service.dart';

/// Provider for managing authentication state and operations
class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuthService? authService})
    : _authService = authService ?? FirebaseAuthService() {
    _init();
  }

  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  // Authentication state
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  /// Initialize the provider and listen to auth state changes
  void _init() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (User? user) {
        _user = user;
        _isInitialized = true;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Authentication state error: ${error.toString()}');
      },
    );
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _performAuthOperation(() async {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    });
  }

  /// Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _performAuthOperation(() async {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    });
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({required String email}) async {
    return _performAuthOperation(() async {
      await _authService.sendPasswordResetEmail(email: email);
      return true;
    });
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    return _performAuthOperation(() async {
      await _authService.signInWithGoogle();
      return true;
    });
  }

  /// Sign out
  Future<bool> signOut() async {
    return _performAuthOperation(() async {
      await _authService.signOut();
      return true;
    });
  }

  /// Delete current user account
  Future<bool> deleteAccount() async {
    return _performAuthOperation(() async {
      await _authService.deleteAccount();
      return true;
    });
  }

  /// Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    return _performAuthOperation(() async {
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      await _authService.reloadUser();
      return true;
    });
  }

  /// Update user email
  Future<bool> updateEmail({required String newEmail}) async {
    return _performAuthOperation(() async {
      await _authService.updateEmail(newEmail: newEmail);
      return true;
    });
  }

  /// Update user password
  Future<bool> updatePassword({required String newPassword}) async {
    return _performAuthOperation(() async {
      await _authService.updatePassword(newPassword: newPassword);
      return true;
    });
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return _performAuthOperation(() async {
      await _authService.sendEmailVerification();
      return true;
    });
  }

  /// Reload user data
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to reload user: ${e.toString()}');
      }
    }
  }

  /// Clear any existing error
  void clearError() {
    _clearError();
  }

  /// Helper method to perform authentication operations with loading state
  Future<T> _performAuthOperation<T>(Future<T> Function() operation) async {
    try {
      _setLoading(true);
      _clearError();
      final result = await operation();
      return result;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
