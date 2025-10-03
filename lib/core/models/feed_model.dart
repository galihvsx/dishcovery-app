import 'package:flutter/foundation.dart';

@immutable
class FeedItem {
  final String id;
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
  final List<String> ingredients;
  final String? recipe;
  final double? rating;

  const FeedItem({
    required this.id,
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
    required this.ingredients,
    this.recipe,
    this.rating,
  });

  FeedItem copyWith({
    String? id,
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
    List<String>? ingredients,
    String? recipe,
    double? rating,
  }) {
    return FeedItem(
      id: id ?? this.id,
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
      ingredients: ingredients ?? this.ingredients,
      recipe: recipe ?? this.recipe,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedItem &&
        other.id == id &&
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
        listEquals(other.ingredients, ingredients) &&
        other.recipe == recipe &&
        other.rating == rating;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
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
      Object.hashAll(ingredients),
      recipe,
      rating,
    );
  }

  @override
  String toString() {
    return 'FeedItem(id: $id, username: $username, caption: $caption, likes: $likes, comments: $comments)';
  }
}

class FakeFeedData {
  static List<FeedItem> generateFakeFeedItems() {
    final now = DateTime.now();

    return [
      FeedItem(
        id: '1',
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
        ingredients: [
          'Pasta',
          'Fresh Basil',
          'Tomatoes',
          'Olive Oil',
          'Garlic',
          'Parmesan',
        ],
        recipe:
            'Cook pasta al dente, sauté garlic in olive oil, add tomatoes and basil...',
        rating: 4.8,
      ),
      FeedItem(
        id: '2',
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
        ingredients: ['Fresh Salmon', 'Wasabi', 'Soy Sauce', 'Pickled Ginger'],
        rating: 4.9,
      ),
      FeedItem(
        id: '3',
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
        ingredients: [
          'Dark Chocolate',
          'Butter',
          'Eggs',
          'Sugar',
          'Flour',
          'Vanilla Ice Cream',
        ],
        recipe:
            'Melt chocolate and butter, whisk with eggs and sugar, bake for 12 minutes...',
        rating: 4.7,
      ),
      FeedItem(
        id: '4',
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
        ingredients: [
          'Quinoa',
          'Avocado',
          'Cherry Tomatoes',
          'Cucumber',
          'Carrots',
          'Tahini',
          'Lemon',
        ],
        rating: 4.6,
      ),
      FeedItem(
        id: '5',
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
        ingredients: [
          'Pizza Dough',
          'San Marzano Tomatoes',
          'Fresh Mozzarella',
          'Basil',
          'Olive Oil',
        ],
        recipe:
            'Stretch dough, add sauce and cheese, bake in wood-fired oven at 900°F...',
        rating: 4.9,
      ),
    ];
  }
}
