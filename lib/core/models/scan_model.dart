import 'package:dishcovery_app/core/models/recipe_model.dart';

class ScanResult {
  final int? id;
  final bool isFood;
  final String imagePath;
  final String name;
  final String origin;
  final String description;
  final String history;
  final Recipe recipe;
  final List<String> tags;
  final List<String> relatedFoods;

  ScanResult({
    this.id,
    required this.isFood,
    required this.imagePath,
    required this.name,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipe,
    required this.tags,
    required this.relatedFoods,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] ?? '').toString().trim();

    final isFood =
        rawName.isNotEmpty &&
        !rawName.toLowerCase().contains("bukan makanan") &&
        !rawName.toLowerCase().contains("not food");

    return ScanResult(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      isFood: isFood,
      imagePath: (json['imagePath'] ?? '').toString(),
      name: rawName,
      origin: (json['origin'] ?? 'Tidak diketahui').toString(),
      description: (json['description'] ?? 'Deskripsi tidak tersedia')
          .toString(),
      history: (json['history'] ?? '').toString(),
      recipe: Recipe.fromJson(
        json['recipe'] is Map<String, dynamic> ? json['recipe'] : {},
      ),
      tags: (json['tags'] is List)
          ? List<String>.from(json['tags'].map((e) => e.toString()))
          : const [],
      relatedFoods: (json['relatedFoods'] is List)
          ? List<String>.from(json['relatedFoods'].map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isFood': isFood ? 1 : 0,
      'imagePath': imagePath,
      'name': name,
      'origin': origin,
      'description': description,
      'history': history,
      'recipe': recipe,
      'tags': tags.join(','),
      'relatedFoods': relatedFoods.join(','),
    };
  }

  ScanResult copyWith({
    int? id,
    bool? isFood,
    String? imagePath,
    String? name,
    String? origin,
    String? description,
    String? history,
    Recipe? recipe,
    List<String>? tags,
    List<String>? relatedFoods,
  }) {
    return ScanResult(
      id: id ?? this.id,
      isFood: isFood ?? this.isFood,
      imagePath: imagePath ?? this.imagePath,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      description: description ?? this.description,
      history: history ?? this.history,
      recipe: recipe ?? this.recipe,
      tags: tags ?? this.tags,
      relatedFoods: relatedFoods ?? this.relatedFoods,
    );
  }
}
