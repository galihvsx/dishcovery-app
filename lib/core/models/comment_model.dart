import 'package:flutter/foundation.dart';

/// Model representing a comment on a feed item
@immutable
class Comment {
  /// Unique identifier for the comment
  final String id;

  /// Reference to the feed/scan this comment belongs to
  final String feedId;

  /// User ID of the commenter
  final String userId;

  /// Display name of the commenter
  final String userName;

  /// Optional profile photo URL of the commenter
  final String? userPhotoUrl;

  /// The comment text content
  final String content;

  /// Timestamp when the comment was created
  final DateTime createdAt;

  /// Optional timestamp when the comment was last updated
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.feedId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy of this comment with the given fields replaced with new values
  Comment copyWith({
    String? id,
    String? feedId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this comment to a Map for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedId': feedId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a Comment instance from a Firestore Map
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      feedId: json['feedId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhotoUrl: json['userPhotoUrl'],
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.feedId == feedId &&
        other.userId == userId &&
        other.userName == userName &&
        other.userPhotoUrl == userPhotoUrl &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      feedId,
      userId,
      userName,
      userPhotoUrl,
      content,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, feedId: $feedId, userId: $userId, userName: $userName, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';
  }
}
