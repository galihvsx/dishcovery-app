class UserPreferences {
  final List<String> likedFlavors; // contoh: pedas, manis, asam
  final List<String> avoidedFlavors; // contoh: pedas, asin
  final List<String> allergies; // contoh: kacang, seafood, susu
  final double? latitude;
  final double? longitude;
  final List<String> categories; // contoh: fastfood, snack, dessert

  const UserPreferences({
    this.likedFlavors = const [],
    this.avoidedFlavors = const [],
    this.allergies = const [],
    this.categories = const [],
    this.latitude,
    this.longitude,
  });

  UserPreferences copyWith({
    List<String>? likedFlavors,
    List<String>? avoidedFlavors,
    List<String>? allergies,
    List<String>? categories,
    double? latitude,
    double? longitude,
  }) {
    return UserPreferences(
      likedFlavors: likedFlavors ?? this.likedFlavors,
      avoidedFlavors: avoidedFlavors ?? this.avoidedFlavors,
      allergies: allergies ?? this.allergies,
      categories: categories ?? this.categories,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'likedFlavors': likedFlavors,
      'avoidedFlavors': avoidedFlavors,
      'allergies': allergies,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categories,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      likedFlavors: List<String>.from(map['likedFlavors'] ?? const []),
      avoidedFlavors: List<String>.from(map['avoidedFlavors'] ?? const []),
      allergies: List<String>.from(map['allergies'] ?? const []),
      categories: List<String>.from(map['categories'] ?? const []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
