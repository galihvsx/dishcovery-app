import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  /// Creates a user document in Firestore after successful authentication
  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
    String? signInMethod,
  }) async {
    try {
      debugPrint('UserService: Creating user document for UID: $uid');
      
      // Check if user document already exists
      final userDoc = await _usersCollection.doc(uid).get();
      
      if (userDoc.exists) {
        debugPrint('UserService: User document already exists, updating last sign-in');
        // Update last sign-in time if document exists
        await _usersCollection.doc(uid).update({
          'lastSignInAt': FieldValue.serverTimestamp(),
          'signInMethod': signInMethod,
        });
        return;
      }

      // Create new user document
      final userData = {
        'uid': uid,
        'email': email,
        'displayName': displayName ?? '',
        'photoURL': photoURL ?? '',
        'signInMethod': signInMethod ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'onboardingCompleted': false,
      };

      await _usersCollection.doc(uid).set(userData);
      debugPrint('UserService: User document created successfully');

      // Also create initial user_preferences document to prevent loading issues
      await _createInitialUserPreferences(uid);
      
    } catch (e) {
      debugPrint('UserService: Error creating user document: $e');
      rethrow;
    }
  }

  /// Creates initial user preferences document to prevent loading issues
  Future<void> _createInitialUserPreferences(String uid) async {
    try {
      final prefsCollection = _db.collection('user_preferences');
      final prefsDoc = await prefsCollection.doc(uid).get();
      
      if (!prefsDoc.exists) {
        await prefsCollection.doc(uid).set({
          'onboardingCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('UserService: Initial user preferences document created');
      }
    } catch (e) {
      debugPrint('UserService: Error creating initial user preferences: $e');
      // Don't rethrow here as this is not critical for user creation
    }
  }

  /// Gets user document from Firestore
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('UserService: Error getting user document: $e');
      return null;
    }
  }

  /// Updates user document
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('UserService: User document updated successfully');
    } catch (e) {
      debugPrint('UserService: Error updating user document: $e');
      rethrow;
    }
  }

  /// Marks user as inactive (soft delete)
  Future<void> deactivateUser(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('UserService: User deactivated successfully');
    } catch (e) {
      debugPrint('UserService: Error deactivating user: $e');
      rethrow;
    }
  }

  /// Creates user document for current authenticated user
  Future<void> createCurrentUserDocument({String? signInMethod}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    await createUserDocument(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      displayName: currentUser.displayName,
      photoURL: currentUser.photoURL,
      signInMethod: signInMethod,
    );
  }
}