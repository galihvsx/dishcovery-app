import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FeedsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _pageSize = 10;
  static const String _feedsCollection = 'scans';
  static const String _likesCollection = 'likes';
  static const String _commentsCollection = 'comments';
  static const String _savedCollection = 'saved';

  List<FeedData> _feeds = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _feedsSubscription;

  List<FeedData> get feeds => _feeds;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  User? get currentUser => _auth.currentUser;

  @override
  void dispose() {
    _feedsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadInitialFeeds() async {
    if (_isLoading) return;

    _isLoading = true;
    _feeds = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final query = _firestore
          .collection(_feedsCollection)
          .where('isPublic', isEqualTo: true)
          .where('isFood', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _feeds = await _processFeedDocuments(snapshot.docs);
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error loading initial feeds: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreFeeds() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final query = _firestore
          .collection(_feedsCollection)
          .where('isPublic', isEqualTo: true)
          .where('isFood', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newFeeds = await _processFeedDocuments(snapshot.docs);
        _feeds.addAll(newFeeds);
        _hasMore = snapshot.docs.length == _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error loading more feeds: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<FeedData>> _processFeedDocuments(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final feeds = <FeedData>[];
    final userId = currentUser?.uid;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      final likesCount = await _getLikesCount(doc.id);
      final commentsCount = await _getCommentsCount(doc.id);

      bool isLiked = false;
      bool isSaved = false;

      if (userId != null) {
        isLiked = await _checkUserLiked(doc.id, userId);
        isSaved = await _checkUserSaved(doc.id, userId);
      }

      feeds.add(
        FeedData.fromFirestore(
          data,
          likesCount: likesCount,
          commentsCount: commentsCount,
          isLiked: isLiked,
          isSaved: isSaved,
        ),
      );
    }

    return feeds;
  }

  Future<void> toggleLike(String feedId) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final feed = _feeds[feedIndex];
    final likeRef = _firestore
        .collection(_feedsCollection)
        .doc(feedId)
        .collection(_likesCollection)
        .doc(userId);

    try {
      if (feed.isLiked) {
        await likeRef.delete();
        _feeds[feedIndex] = feed.copyWith(
          isLiked: false,
          likesCount: feed.likesCount - 1,
        );
      } else {
        await likeRef.set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _feeds[feedIndex] = feed.copyWith(
          isLiked: true,
          likesCount: feed.likesCount + 1,
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> toggleSave(String feedId) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final feed = _feeds[feedIndex];
    final saveRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(_savedCollection)
        .doc(feedId);

    try {
      if (feed.isSaved) {
        await saveRef.delete();
        _feeds[feedIndex] = feed.copyWith(isSaved: false);
      } else {
        await saveRef.set({
          'feedId': feedId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _feeds[feedIndex] = feed.copyWith(isSaved: true);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling save: $e');
    }
  }

  void updateSavedStatus(String feedId, bool isSaved) {
    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final current = _feeds[feedIndex];
    if (current.isSaved == isSaved) return;

    _feeds[feedIndex] = current.copyWith(isSaved: isSaved);
    notifyListeners();
  }

  void incrementCommentCount(String feedId) {
    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final feed = _feeds[feedIndex];
    _feeds[feedIndex] = feed.copyWith(commentsCount: feed.commentsCount + 1);
    notifyListeners();
  }

  void decrementCommentCount(String feedId) {
    final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
    if (feedIndex == -1) return;

    final feed = _feeds[feedIndex];
    final updatedCount = feed.commentsCount > 0 ? feed.commentsCount - 1 : 0;
    if (updatedCount == feed.commentsCount) return;

    _feeds[feedIndex] = feed.copyWith(commentsCount: updatedCount);
    notifyListeners();
  }

  Future<void> addComment(String feedId, String comment) async {
    final userId = currentUser?.uid;
    if (userId == null || comment.trim().isEmpty) return;

    try {
      await _firestore
          .collection(_feedsCollection)
          .doc(feedId)
          .collection(_commentsCollection)
          .add({
            'userId': userId,
            'userName': currentUser?.displayName ?? 'User',
            'userAvatar': currentUser?.photoURL ?? '',
            'comment': comment.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      final feedIndex = _feeds.indexWhere((f) => f.id == feedId);
      if (feedIndex != -1) {
        final feed = _feeds[feedIndex];
        _feeds[feedIndex] = feed.copyWith(
          commentsCount: feed.commentsCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<int> _getLikesCount(String feedId) async {
    try {
      final snapshot = await _firestore
          .collection(_feedsCollection)
          .doc(feedId)
          .collection(_likesCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getCommentsCount(String feedId) async {
    Future<int?> _readStoredCount(String collection) async {
      try {
        final doc = await _firestore.collection(collection).doc(feedId).get();
        final data = doc.data();
        final value = data?['comments'];
        if (value is int) {
          return value;
        }
        if (value is num) {
          return value.toInt();
        }
      } catch (_) {
        // ignored - fall back to other sources
      }
      return null;
    }

    final storedCount = await _readStoredCount(_feedsCollection)
        ?? await _readStoredCount('feeds');
    if (storedCount != null) {
      return storedCount;
    }

    try {
      final snapshot = await _firestore
          .collection(_commentsCollection)
          .where('feedId', isEqualTo: feedId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> _checkUserLiked(String feedId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_feedsCollection)
          .doc(feedId)
          .collection(_likesCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkUserSaved(String feedId, String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_savedCollection)
          .doc(feedId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshFeeds() async {
    await loadInitialFeeds();
  }
}

class FeedData {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String imageUrl;
  final String name;
  final String origin;
  final String description;
  final String history;
  final Map<String, dynamic> recipe;
  final List<String> tags;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;

  FeedData({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.imageUrl,
    required this.name,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipe,
    required this.tags,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isSaved,
  });

  factory FeedData.fromFirestore(
    Map<String, dynamic> data, {
    required int likesCount,
    required int commentsCount,
    required bool isLiked,
    required bool isSaved,
  }) {
    return FeedData(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? 'User',
      imageUrl: data['imageUrl'] ?? '',
      name: data['name'] ?? '',
      origin: data['origin'] ?? '',
      description: data['description'] ?? '',
      history: data['history'] ?? '',
      recipe: data['recipe'] ?? {},
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as dynamic).toDate(),
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked,
      isSaved: isSaved,
    );
  }

  FeedData copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? imageUrl,
    String? name,
    String? origin,
    String? description,
    String? history,
    Map<String, dynamic>? recipe,
    List<String>? tags,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return FeedData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      history: history ?? this.history,
      recipe: recipe ?? this.recipe,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
