import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/core/models/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing Firestore operations for comments
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _commentsCollection = 'comments';
  static const String _feedsCollection = 'feeds';
  static const String _scansCollection = 'scans';

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Add a new comment to Firestore
  ///
  /// Stores comment in 'comments' collection and updates comment count
  /// in the corresponding feed document
  Future<String?> addComment(Comment comment) async {
    try {
      final user = currentUser;
      if (user == null) return null;

      // Auto-generate document ID if not provided
      final docRef = comment.id.isEmpty
          ? _firestore.collection(_commentsCollection).doc()
          : _firestore.collection(_commentsCollection).doc(comment.id);

      // Update comment with document ID if it was auto-generated
      final updatedComment = comment.id.isEmpty
          ? comment.copyWith(id: docRef.id, createdAt: DateTime.now())
          : comment;

      // Save comment to Firestore
      await docRef.set(updatedComment.toJson());

      // Update comment count in feed document
      await _updateCommentCount(comment.feedId, increment: true);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// Get all comments for a specific feed
  ///
  /// Returns a Stream of comments ordered by createdAt descending (newest first)
  /// with real-time updates
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

  /// Delete a comment from Firestore
  ///
  /// Removes comment document and updates comment count in feed
  Future<bool> deleteComment(String commentId, String feedId) async {
    try {
      // Delete the comment document
      await _firestore.collection(_commentsCollection).doc(commentId).delete();

      // Update comment count in feed document
      await _updateCommentCount(feedId, increment: false);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Update an existing comment
  ///
  /// Updates comment content and sets updatedAt timestamp
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

  /// Get total comment count for a feed
  ///
  /// Returns a Stream of the comment count with real-time updates
  Stream<int> getCommentCount(String feedId) {
    return _firestore
        .collection(_commentsCollection)
        .where('feedId', isEqualTo: feedId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Internal method to update comment count in feed document
  ///
  /// Updates the 'comments' field in both 'feeds' and 'scans' collections
  Future<void> _updateCommentCount(
    String feedId, {
    required bool increment,
  }) async {
    try {
      final incrementValue = increment ? 1 : -1;

      // Try to update in feeds collection first
      final feedDoc = _firestore.collection(_feedsCollection).doc(feedId);
      final feedSnapshot = await feedDoc.get();

      if (feedSnapshot.exists) {
        await feedDoc.update({
          'comments': FieldValue.increment(incrementValue),
        });
      } else {
        // If not in feeds, try scans collection
        final scanDoc = _firestore.collection(_scansCollection).doc(feedId);
        final scanSnapshot = await scanDoc.get();

        if (scanSnapshot.exists) {
          // Initialize comments field if it doesn't exist
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
      // Don't throw error, allow comment operations to succeed even if count update fails
    }
  }

  /// Get a single comment by ID
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

  /// Get comments by user ID
  ///
  /// Returns a Stream of all comments made by a specific user
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

  /// Delete all comments for a specific feed
  ///
  /// Useful when a feed is deleted
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
