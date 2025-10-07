import 'package:flutter/foundation.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/core/models/recipe_model.dart';

@immutable
class FeedItem {
  final String id;
  final String userId; // ID user yang melakukan scan
  final String username;
  final String userAvatarUrl;
  final String imageUrl;
  final String caption;
  final List<String> tags;
  final int likes;
  final int comments;
  final bool isSaved;
  final bool isLiked;
  final DateTime createdAt;
  final String location;

  // Data dari scan result
  final String? scanResultId; // Referensi ke scan result yang menjadi sumber
  final String foodName;
  final String origin;
  final String description;
  final String history;
  final Recipe recipe; // Menggunakan Recipe object yang lengkap
  final double? rating;

  // Metadata untuk tracking
  final bool isFromScan; // Apakah feed ini berasal dari scan result
  final DateTime? sharedAt; // Kapan di-share ke feed

  const FeedItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.isSaved,
    required this.isLiked,
    required this.createdAt,
    required this.location,
    this.scanResultId,
    required this.foodName,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipe,
    this.rating,
    required this.isFromScan,
    this.sharedAt,
  });

  FeedItem copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatarUrl,
    String? imageUrl,
    String? caption,
    List<String>? tags,
    int? likes,
    int? comments,
    bool? isSaved,
    bool? isLiked,
    DateTime? createdAt,
    String? location,
    String? scanResultId,
    String? foodName,
    String? origin,
    String? description,
    String? history,
    Recipe? recipe,
    double? rating,
    bool? isFromScan,
    DateTime? sharedAt,
  }) {
    return FeedItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isSaved: isSaved ?? this.isSaved,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      scanResultId: scanResultId ?? this.scanResultId,
      foodName: foodName ?? this.foodName,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      history: history ?? this.history,
      recipe: recipe ?? this.recipe,
      rating: rating ?? this.rating,
      isFromScan: isFromScan ?? this.isFromScan,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedItem &&
        other.id == id &&
        other.userId == userId &&
        other.username == username &&
        other.userAvatarUrl == userAvatarUrl &&
        other.imageUrl == imageUrl &&
        other.caption == caption &&
        listEquals(other.tags, tags) &&
        other.likes == likes &&
        other.comments == comments &&
        other.isSaved == isSaved &&
        other.isLiked == isLiked &&
        other.createdAt == createdAt &&
        other.location == location &&
        other.scanResultId == scanResultId &&
        other.foodName == foodName &&
        other.origin == origin &&
        other.description == description &&
        other.history == history &&
        other.recipe == recipe &&
        other.rating == rating &&
        other.isFromScan == isFromScan &&
        other.sharedAt == sharedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
          id,
          userId,
          username,
          userAvatarUrl,
          imageUrl,
          caption,
          Object.hashAll(tags),
          likes,
          comments,
          isSaved,
          isLiked,
          createdAt,
          location,
          scanResultId,
          foodName,
          origin,
          description,
          history,
          recipe,
          rating,
        ) ^
        Object.hash(isFromScan, sharedAt);
  }

  @override
  String toString() {
    return 'FeedItem(id: $id, userId: $userId, username: $username, foodName: $foodName, likes: $likes, comments: $comments)';
  }

  /// Factory method untuk membuat FeedItem dari ScanResult
  factory FeedItem.fromScanResult({
    required String feedId,
    required String userId,
    required String username,
    required String userAvatarUrl,
    required ScanResult scanResult,
    required String caption,
    required String location,
    List<String>? additionalTags,
  }) {
    return FeedItem(
      id: feedId,
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      imageUrl: scanResult.imagePath,
      caption: caption,
      tags: [...scanResult.tags, ...(additionalTags ?? [])],
      likes: 0,
      comments: 0,
      isSaved: false,
      isLiked: false,
      createdAt: DateTime.now(),
      location: location,
      scanResultId: scanResult.id?.toString(),
      foodName: scanResult.name,
      origin: scanResult.origin,
      description: scanResult.description,
      history: scanResult.history,
      recipe: scanResult.recipe,
      rating: null,
      isFromScan: true,
      sharedAt: DateTime.now(),
    );
  }

  /// Method untuk konversi ke Map (untuk Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'tags': tags,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'scanResultId': scanResultId,
      'foodName': foodName,
      'origin': origin,
      'description': description,
      'history': history,
      'recipe': {'ingredients': recipe.ingredients, 'steps': recipe.steps},
      'rating': rating,
      'isFromScan': isFromScan,
      'sharedAt': sharedAt?.toIso8601String(),
    };
  }

  /// Factory method untuk membuat FeedItem dari Firestore data
  factory FeedItem.fromFirestore(Map<String, dynamic> data) {
    return FeedItem(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      isSaved: false, // This will be determined by user's collection
      isLiked: false, // This will be determined by user's likes
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      location: data['location'] ?? '',
      scanResultId: data['scanResultId'],
      foodName: data['foodName'] ?? '',
      origin: data['origin'] ?? '',
      description: data['description'] ?? '',
      history: data['history'] ?? '',
      recipe: Recipe.fromJson(data['recipe'] ?? {}),
      rating: data['rating']?.toDouble(),
      isFromScan: data['isFromScan'] ?? false,
      sharedAt: data['sharedAt'] != null
          ? DateTime.parse(data['sharedAt'])
          : null,
    );
  }
}

class FakeFeedData {
  static List<FeedItem> generateFakeFeedItems() {
    final now = DateTime.now();

    return [
      FeedItem(
        id: '1',
        userId: 'user_maria_123',
        username: 'chef_maria',
        userAvatarUrl: 'https://picsum.photos/seed/chef_maria/100/100.jpg',
        imageUrl: 'https://picsum.photos/seed/pasta/400/400.jpg',
        caption:
            'Homemade pasta with fresh basil and tomatoes! 🍝✨ Nothing beats the taste of authentic Italian cuisine.',
        tags: ['#pasta', '#italian', '#homemade', '#basil', '#tomatoes'],
        likes: 234,
        comments: 18,
        isSaved: false,
        isLiked: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        location: 'Rome, Italy',
        scanResultId: 'scan_001',
        foodName: 'Pasta Pomodoro',
        origin: 'Italy',
        description:
            'Traditional Italian pasta dish with fresh tomatoes and basil',
        history:
            'Pasta Pomodoro originated in Southern Italy and has been a staple dish for centuries.',
        recipe: Recipe(
          ingredients: [
            'Pasta',
            'Fresh Basil',
            'Tomatoes',
            'Olive Oil',
            'Garlic',
            'Parmesan',
          ],
          steps: [
            'Cook pasta al dente',
            'Sauté garlic in olive oil',
            'Add tomatoes and basil',
            'Toss with pasta and serve',
          ],
        ),
        rating: 4.8,
        isFromScan: true,
        sharedAt: now.subtract(const Duration(hours: 2)),
      ),
      FeedItem(
        id: '2',
        userId: 'user_sushi_456',
        username: 'sushi_master',
        userAvatarUrl: 'https://picsum.photos/seed/sushi_master/100/100.jpg',
        imageUrl: 'https://picsum.photos/seed/sushi/400/400.jpg',
        caption:
            'Fresh salmon sashimi, perfectly cut and beautifully presented 🍣🐟',
        tags: ['#sushi', '#sashimi', '#japanese', '#salmon', '#fresh'],
        likes: 189,
        comments: 12,
        isSaved: true,
        isLiked: true,
        createdAt: now.subtract(const Duration(hours: 4)),
        location: 'Tokyo, Japan',
        scanResultId: 'scan_002',
        foodName: 'Salmon Sashimi',
        origin: 'Japan',
        description: 'Fresh raw salmon sliced thinly and served without rice',
        history:
            'Sashimi has been part of Japanese cuisine for over 1000 years.',
        recipe: Recipe(
          ingredients: [
            'Fresh Salmon',
            'Wasabi',
            'Soy Sauce',
            'Pickled Ginger',
          ],
          steps: [
            'Select the freshest salmon',
            'Cut against the grain in thin slices',
            'Arrange on plate',
            'Serve with wasabi and soy sauce',
          ],
        ),
        rating: 4.9,
        isFromScan: true,
        sharedAt: now.subtract(const Duration(hours: 4)),
      ),
      FeedItem(
        id: '3',
        userId: 'user_dessert_789',
        username: 'dessert_queen',
        userAvatarUrl: 'https://picsum.photos/seed/dessert_queen/100/100.jpg',
        imageUrl: 'https://picsum.photos/seed/chocolate/400/400.jpg',
        caption:
            'Decadent chocolate lava cake with vanilla ice cream 🍰🍦 Pure indulgence!',
        tags: ['#dessert', '#chocolate', '#lavacake', '#icecream', '#sweet'],
        likes: 312,
        comments: 25,
        isSaved: false,
        isLiked: false,
        createdAt: now.subtract(const Duration(hours: 6)),
        location: 'Paris, France',
        scanResultId: 'scan_003',
        foodName: 'Chocolate Lava Cake',
        origin: 'France',
        description:
            'Rich chocolate cake with molten chocolate center served with ice cream',
        history:
            'Chocolate lava cake was popularized in the 1980s by French chef Michel Bras.',
        recipe: Recipe(
          ingredients: [
            'Dark Chocolate',
            'Butter',
            'Eggs',
            'Sugar',
            'Flour',
            'Vanilla Ice Cream',
          ],
          steps: [
            'Melt chocolate and butter',
            'Whisk with eggs and sugar',
            'Add flour and mix',
            'Bake for 12 minutes',
            'Serve with ice cream',
          ],
        ),
        rating: 4.7,
        isFromScan: true,
        sharedAt: now.subtract(const Duration(hours: 6)),
      ),
      FeedItem(
        id: '4',
        userId: 'user_healthy_101',
        username: 'healthy_eats',
        userAvatarUrl: 'https://picsum.photos/seed/healthy_eats/100/100.jpg',
        imageUrl: 'https://picsum.photos/seed/salad/400/400.jpg',
        caption:
            'Rainbow Buddha bowl with quinoa, avocado, and tahini dressing 🌈🥗 Healthy never tasted so good!',
        tags: ['#healthy', '#buddhabowl', '#quinoa', '#avocado', '#vegan'],
        likes: 156,
        comments: 8,
        isSaved: true,
        isLiked: false,
        createdAt: now.subtract(const Duration(hours: 8)),
        location: 'Los Angeles, CA',
        scanResultId: 'scan_004',
        foodName: 'Rainbow Buddha Bowl',
        origin: 'Modern Fusion',
        description:
            'Colorful and nutritious bowl with quinoa, fresh vegetables, and tahini dressing',
        history:
            'Buddha bowls became popular in the 2010s as part of the healthy eating movement.',
        recipe: Recipe(
          ingredients: [
            'Quinoa',
            'Avocado',
            'Cherry Tomatoes',
            'Cucumber',
            'Carrots',
            'Tahini',
            'Lemon',
          ],
          steps: [
            'Cook quinoa according to package instructions',
            'Prepare all vegetables',
            'Make tahini dressing with lemon',
            'Arrange in bowl',
            'Drizzle with dressing',
          ],
        ),
        rating: 4.6,
        isFromScan: true,
        sharedAt: now.subtract(const Duration(hours: 8)),
      ),
      FeedItem(
        id: '5',
        userId: 'user_pizza_202',
        username: 'pizza_lover',
        userAvatarUrl: 'https://picsum.photos/seed/pizza_lover/100/100.jpg',
        imageUrl: 'https://picsum.photos/seed/pizza/400/400.jpg',
        caption:
            'Wood-fired Margherita pizza with fresh mozzarella 🍕🔥 Crispy crust, perfect char!',
        tags: [
          '#pizza',
          '#margherita',
          '#woodfired',
          '#mozzarella',
          '#italian',
        ],
        likes: 278,
        comments: 22,
        isSaved: false,
        isLiked: true,
        createdAt: now.subtract(const Duration(hours: 10)),
        location: 'Naples, Italy',
        scanResultId: 'scan_005',
        foodName: 'Margherita Pizza',
        origin: 'Italy',
        description:
            'Classic Neapolitan pizza with tomatoes, mozzarella, and basil',
        history:
            'Pizza Margherita was created in 1889 in honor of Queen Margherita of Savoy.',
        recipe: Recipe(
          ingredients: [
            'Pizza Dough',
            'San Marzano Tomatoes',
            'Fresh Mozzarella',
            'Basil',
            'Olive Oil',
          ],
          steps: [
            'Stretch dough to desired thickness',
            'Add tomato sauce',
            'Add fresh mozzarella',
            'Bake in wood-fired oven at 900°F',
            'Garnish with fresh basil',
          ],
        ),
        rating: 4.9,
        isFromScan: true,
        sharedAt: now.subtract(const Duration(hours: 10)),
      ),
    ];
  }
}
