import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/core/models/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _commentsCollection = 'comments';
  static const String _feedsCollection = 'feeds';
  static const String _scansCollection = 'scans';

  User? get currentUser => _auth.currentUser;

  Future<String?> addComment(Comment comment) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final docRef = comment.id.isEmpty
          ? _firestore.collection(_commentsCollection).doc()
          : _firestore.collection(_commentsCollection).doc(comment.id);

      final updatedComment = comment.id.isEmpty
          ? comment.copyWith(id: docRef.id, createdAt: DateTime.now())
          : comment;

      await docRef.set(updatedComment.toJson());

      await _updateCommentCount(comment.feedId, increment: true);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  Stream<List<Comment>> getComments(String feedId) {
    return _firestore
        .collection(_commentsCollection)
        .where('feedId', isEqualTo: feedId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Comment.fromJson(data);
          }).toList();
        });
  }

  Future<bool> deleteComment(String commentId, String feedId) async {
    try {
      await _firestore.collection(_commentsCollection).doc(commentId).delete();

      await _updateCommentCount(feedId, increment: false);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  Future<bool> updateComment(Comment comment) async {
    try {
      final updatedComment = comment.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_commentsCollection)
          .doc(comment.id)
          .update(updatedComment.toJson());

      return true;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }

  Stream<int> getCommentCount(String feedId) {
    return _firestore
        .collection(_commentsCollection)
        .where('feedId', isEqualTo: feedId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> _updateCommentCount(
    String feedId, {
    required bool increment,
  }) async {
    try {
      final incrementValue = increment ? 1 : -1;

      final feedDoc = _firestore.collection(_feedsCollection).doc(feedId);
      final feedSnapshot = await feedDoc.get();

      if (feedSnapshot.exists) {
        await feedDoc.update({
          'comments': FieldValue.increment(incrementValue),
        });
      } else {
        final scanDoc = _firestore.collection(_scansCollection).doc(feedId);
        final scanSnapshot = await scanDoc.get();

        if (scanSnapshot.exists) {
          final currentData = scanSnapshot.data();
          if (currentData != null && !currentData.containsKey('comments')) {
            await scanDoc.update({'comments': increment ? 1 : 0});
          } else {
            await scanDoc.update({
              'comments': FieldValue.increment(incrementValue),
            });
          }
        }
      }
    } catch (e) {
      print('Error updating comment count: $e');
    }
  }

  Future<Comment?> getCommentById(String commentId) async {
    try {
      final doc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();

      if (doc.exists) {
        return Comment.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting comment by ID: $e');
      return null;
    }
  }

  Stream<List<Comment>> getCommentsByUser(String userId) {
    return _firestore
        .collection(_commentsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Comment.fromJson(data);
          }).toList();
        });
  }

  Future<bool> deleteAllCommentsForFeed(String feedId) async {
    try {
      final snapshot = await _firestore
          .collection(_commentsCollection)
          .where('feedId', isEqualTo: feedId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting all comments for feed: $e');
      return false;
    }
  }
}
