import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:dishcovery_app/core/services/firebase_auth_service.dart';
import 'package:dishcovery_app/core/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuthService? authService, UserService? userService})
    : _authService = authService ?? FirebaseAuthService(),
      _userService = userService ?? UserService() {
    _init();
  }

  final FirebaseAuthService _authService;
  final UserService _userService;
  StreamSubscription<User?>? _authStateSubscription;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  void _init() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (User? user) async {
        final previousUser = _user;
        _user = user;
        _isInitialized = true;
        _clearError();

        if (previousUser == null && user != null) {
          debugPrint('🔐 AuthProvider: User signed in, creating user document');
          try {
            await _userService.createUserDocument(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName,
              photoURL: user.photoURL,
              signInMethod: _getSignInMethod(user),
            );
            debugPrint('🔐 AuthProvider: User document created successfully');
          } catch (e) {
            debugPrint('🔐 AuthProvider: Error creating user document: $e');
          }
        }

        notifyListeners();
      },
      onError: (error) {
        _setError('Authentication state error: ${error.toString()}');
      },
    );
  }

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

  Future<bool> sendPasswordResetEmail({required String email}) async {
    return _performAuthOperation(() async {
      await _authService.sendPasswordResetEmail(email: email);
      return true;
    });
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('🔐 AuthProvider: Starting Google Sign-In process');
    debugPrint('🔐 AuthProvider: Current loading state: $_isLoading');
    debugPrint(
      '🔐 AuthProvider: Current user state: ${_user?.email ?? 'null'}',
    );

    return _performAuthOperation(() async {
      debugPrint(
        '🔐 AuthProvider: Calling FirebaseAuthService.signInWithGoogle()',
      );
      await _authService.signInWithGoogle();
      debugPrint(
        '🔐 AuthProvider: FirebaseAuthService.signInWithGoogle() completed successfully',
      );
      debugPrint(
        '🔐 AuthProvider: New user after sign-in: ${_authService.currentUser?.email ?? 'null'}',
      );
      return true;
    });
  }

  Future<bool> signOut() async {
    return _performAuthOperation(() async {
      await _authService.signOut();
      return true;
    });
  }

  Future<bool> deleteAccount() async {
    return _performAuthOperation(() async {
      await _authService.deleteAccount();
      return true;
    });
  }

  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    return _performAuthOperation(() async {
      if (_user == null) {
        throw Exception('No user is currently signed in');
      }

      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      if (updateData.isNotEmpty) {
        await _userService.updateUserDocument(_user!.uid, updateData);
      }

      await _authService.reloadUser();
      _user = _authService.currentUser;
      notifyListeners();

      return true;
    });
  }

  Future<bool> updateEmail({required String newEmail}) async {
    return _performAuthOperation(() async {
      await _authService.updateEmail(newEmail: newEmail);
      return true;
    });
  }

  Future<bool> updatePassword({required String newPassword}) async {
    return _performAuthOperation(() async {
      await _authService.updatePassword(newPassword: newPassword);
      return true;
    });
  }

  Future<bool> sendEmailVerification() async {
    return _performAuthOperation(() async {
      await _authService.sendEmailVerification();
      return true;
    });
  }

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

  void clearError() {
    _clearError();
  }

  Future<T> _performAuthOperation<T>(Future<T> Function() operation) async {
    try {
      debugPrint('🔄 AuthProvider: Setting loading state to true');
      _setLoading(true);
      _clearError();
      debugPrint('🔄 AuthProvider: Starting authentication operation');
      final result = await operation();
      debugPrint(
        '🔄 AuthProvider: Authentication operation completed successfully',
      );
      return result;
    } catch (e) {
      debugPrint(
        '❌ AuthProvider: Authentication operation failed with error: ${e.toString()}',
      );
      debugPrint('❌ AuthProvider: Error type: ${e.runtimeType}');
      _setError(e.toString());
      rethrow;
    } finally {
      debugPrint('🔄 AuthProvider: Setting loading state to false');
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  String _getSignInMethod(User user) {
    if (user.providerData.isEmpty) return 'unknown';

    final providerId = user.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return 'google';
      case 'password':
        return 'email';
      case 'facebook.com':
        return 'facebook';
      case 'apple.com':
        return 'apple';
      default:
        return providerId;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
