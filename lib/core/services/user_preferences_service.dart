import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences.dart';

class UserPreferencesService {
  final FirebaseFirestore _db;
  UserPreferencesService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('user_preferences');

  Future<void> savePreferences({
    required String uid,
    required UserPreferences prefs,
  }) async {
    await _collection.doc(uid).set(prefs.toMap(), SetOptions(merge: true));
  }

  Future<UserPreferences> getPreferences({required String uid}) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return const UserPreferences();
    return UserPreferences.fromMap(doc.data()!);
  }

  Future<bool> hasCompletedOnboarding({required String uid}) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return false;

    final data = doc.data()!;
    // Check if user has completed onboarding by checking if preferences document exists
    // and has been explicitly set (not just default empty values)
    return data.containsKey('onboardingCompleted') &&
        data['onboardingCompleted'] == true;
  }

  Future<void> markOnboardingCompleted({required String uid}) async {
    await _collection.doc(uid).set({
      'onboardingCompleted': true,
    }, SetOptions(merge: true));
  }
}
