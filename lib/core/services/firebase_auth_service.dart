import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class for handling Firebase Authentication operations
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal() {
    _initializeGoogleSignIn();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  /// Initialize Google Sign-In (required for v7)
  Future<void> _initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;

    try {
      debugPrint('🚀 FirebaseAuthService: Initializing Google Sign-In');
      await _googleSignIn.initialize();
      _googleSignInInitialized = true;
      debugPrint('✅ FirebaseAuthService: Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('❌ FirebaseAuthService: Failed to initialize Google Sign-In: $e');
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get authentication state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    debugPrint('🚀 FirebaseAuthService: Starting Google Sign-In flow');
    debugPrint('🚀 FirebaseAuthService: Current Firebase user: ${_auth.currentUser?.email ?? 'null'}');

    try {
      // Ensure Google Sign-In is initialized
      if (!_googleSignInInitialized) {
        await _initializeGoogleSignIn();
      }

      // Check if authenticate is supported on this platform
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint('❌ FirebaseAuthService: Platform does not support authenticate method');
        throw Exception('Google Sign-In is not supported on this platform');
      }

      // Trigger the Google Sign-In flow using the new authenticate method
      // This replaces the old signIn() method
      debugPrint('🚀 FirebaseAuthService: Triggering Google Sign-In authentication');
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      debugPrint('🚀 FirebaseAuthService: Google Sign-In authentication completed');

      debugPrint('✅ FirebaseAuthService: Google user obtained: ${googleUser.email}');
      debugPrint('🚀 FirebaseAuthService: Google user display name: ${googleUser.displayName}');
      debugPrint('🚀 FirebaseAuthService: Google user ID: ${googleUser.id}');

      // In google_sign_in v7, we need to get the authentication tokens differently
      // The authentication property returns tokens directly
      debugPrint('🚀 FirebaseAuthService: Obtaining authentication tokens');

      // Get the authentication object
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      debugPrint('✅ FirebaseAuthService: Google authentication object obtained');

      // In v7, tokens are accessed directly from the authentication object
      final String? idToken = googleAuth.idToken;

      debugPrint('🚀 FirebaseAuthService: ID token available: ${idToken != null}');

      if (idToken == null) {
        debugPrint('❌ FirebaseAuthService: No ID token received');
        throw Exception('Failed to get ID token from Google Sign-In');
      }

      // Create a new credential using the ID token
      // For Firebase, we only need the ID token
      debugPrint('🚀 FirebaseAuthService: Creating Firebase credential from Google tokens');
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      debugPrint('✅ FirebaseAuthService: Firebase credential created successfully');

      // Sign in to Firebase with the Google credential
      debugPrint('🚀 FirebaseAuthService: Signing in to Firebase with Google credential');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ FirebaseAuthService: Firebase sign-in completed successfully');
      debugPrint('🚀 FirebaseAuthService: Firebase user: ${userCredential.user?.email ?? 'null'}');
      debugPrint('🚀 FirebaseAuthService: Firebase user UID: ${userCredential.user?.uid ?? 'null'}');
      debugPrint('🚀 FirebaseAuthService: Firebase user display name: ${userCredential.user?.displayName ?? 'null'}');
      debugPrint('🚀 FirebaseAuthService: Firebase user email verified: ${userCredential.user?.emailVerified ?? false}');

      return userCredential;
    } on GoogleSignInException catch (e) {
      debugPrint('❌ FirebaseAuthService: GoogleSignInException occurred');
      debugPrint('❌ FirebaseAuthService: Error code: ${e.code}');
      debugPrint('❌ FirebaseAuthService: Error details: ${e.toString()}');

      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('❌ FirebaseAuthService: User cancelled sign-in');
        throw Exception('Google sign-in was cancelled');
      }
      throw Exception('Google Sign-In failed: ${e.toString()}');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthService: FirebaseAuthException occurred');
      debugPrint('❌ FirebaseAuthService: Error code: ${e.code}');
      debugPrint('❌ FirebaseAuthService: Error message: ${e.message}');
      debugPrint('❌ FirebaseAuthService: Error details: ${e.toString()}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ FirebaseAuthService: General exception occurred');
      debugPrint('❌ FirebaseAuthService: Exception type: ${e.runtimeType}');
      debugPrint('❌ FirebaseAuthService: Exception message: ${e.toString()}');

      if (e.toString().contains('cancelled')) {
        debugPrint('❌ FirebaseAuthService: Re-throwing cancellation exception');
        rethrow;
      }
      throw Exception('Failed to sign in with Google: ${e.toString()}');
    }
  }

  /// Sign out from Google
  Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sign out from Google: ${e.toString()}');
      }
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.delete();
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update user email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Update user password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw Exception('No user is currently signed in');
      } else {
        throw Exception('Email is already verified');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Reload current user to get updated information
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to reload user: ${e.toString()}');
      }
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ??
            'An authentication error occurred. Please try again.';
    }
  }
}
