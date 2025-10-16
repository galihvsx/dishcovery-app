import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/services/firebase_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  static const String _scansCollection = 'scans';

  User? get currentUser => _auth.currentUser;

  Future<bool> checkDuplicateScan(String contentHash, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_scansCollection)
          .where('userId', isEqualTo: userId)
          .where('contentHash', isEqualTo: contentHash)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for duplicate scan: $e');
      return false;
    }
  }

  Future<bool> checkRecentSimilarScan(String foodName, String userId) async {
    try {
      final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));

      final querySnapshot = await _firestore
          .collection(_scansCollection)
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: foodName)
          .where('createdAt', isGreaterThan: oneMinuteAgo)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for recent similar scan: $e');
      return false;
    }
  }

  Future<String?> saveScanResult(ScanResult scanResult) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      String? imageUrl = scanResult.imageUrl;
      if (scanResult.imagePath.isNotEmpty &&
          !scanResult.imagePath.startsWith('http')) {
        final uploadedUrl = await _storageService.uploadImage(
          scanResult.imagePath,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final updatedResult = scanResult.copyWith(
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName ?? user.email?.split('@').first ?? 'User',
        imageUrl: imageUrl,
        isPublic: true,
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_scansCollection)
          .add(updatedResult.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error saving scan result: $e');
      return null;
    }
  }

  Future<bool> updateScanResult(String docId, ScanResult scanResult) async {
    try {
      await _firestore
          .collection(_scansCollection)
          .doc(docId)
          .update(scanResult.toFirestore());
      return true;
    } catch (e) {
      print('Error updating scan result: $e');
      return false;
    }
  }

  Stream<List<ScanResult>> getUserScans(String userId) {
    return _firestore
        .collection(_scansCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['firestoreId'] = doc.id;
            return ScanResult.fromJson(data);
          }).toList();
        });
  }

  Stream<List<ScanResult>> getPublicFeeds({int limit = 50}) {
    return _firestore
        .collection(_scansCollection)
        .where('isPublic', isEqualTo: true)
        .where('isFood', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['firestoreId'] = doc.id;
            return ScanResult.fromJson(data);
          }).toList();
        });
  }

  Future<List<ScanResult>> searchFeeds(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_scansCollection)
          .where('isPublic', isEqualTo: true)
          .where('isFood', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['firestoreId'] = doc.id;
            return ScanResult.fromJson(data);
          })
          .where(
            (scan) =>
                scan.name.toLowerCase().contains(query.toLowerCase()) ||
                scan.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    } catch (e) {
      print('Error searching feeds: $e');
      return [];
    }
  }

  Future<bool> deleteScanResult(String docId) async {
    try {
      final doc = await _firestore
          .collection(_scansCollection)
          .doc(docId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final imageUrl = data['imageUrl'] as String?;

        if (imageUrl != null) {
          await _storageService.deleteImage(imageUrl);
        }
      }

      await _firestore.collection(_scansCollection).doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting scan result: $e');
      return false;
    }
  }

  Future<void> setSavedStatus(String feedId, bool isSaved) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final savedRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved')
          .doc(feedId);

      if (isSaved) {
        await savedRef.set({
          'feedId': feedId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await savedRef.delete();
      }
    } catch (e) {
      print('Error updating saved status: $e');
    }
  }

  Future<ScanResult?> getScanById(String docId) async {
    try {
      final doc = await _firestore
          .collection(_scansCollection)
          .doc(docId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['firestoreId'] = doc.id;
        return ScanResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting scan by ID: $e');
      return null;
    }
  }

  Future<void> batchSaveScanResults(List<ScanResult> scans) async {
    final batch = _firestore.batch();
    final user = currentUser;
    if (user == null) return;

    for (final scan in scans) {
      final docRef = _firestore.collection(_scansCollection).doc();
      final updatedScan = scan.copyWith(
        userId: user.uid,
        userEmail: user.email,
        userName: user.displayName ?? user.email?.split('@').first ?? 'User',
        isPublic: true,
        updatedAt: DateTime.now(),
      );
      batch.set(docRef, updatedScan.toFirestore());
    }

    await batch.commit();
  }
}
