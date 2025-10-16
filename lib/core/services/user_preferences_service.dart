import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/core/models/user_preferences.dart';

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
    try {
      final doc = await _collection.doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        await _createInitialDocument(uid);
        return false;
      }

      final data = doc.data()!;
      return data.containsKey('onboardingCompleted') &&
          data['onboardingCompleted'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createInitialDocument(String uid) async {
    try {
      await _collection.doc(uid).set({
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

  Future<void> markOnboardingCompleted({required String uid}) async {
    await _collection.doc(uid).set({
      'onboardingCompleted': true,
    }, SetOptions(merge: true));
  }
}
