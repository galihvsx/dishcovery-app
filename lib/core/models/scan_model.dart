import 'package:dishcovery_app/core/models/recipe_model.dart';

class ScanResult {
  final String name;
  final String origin;
  final String description;
  final String history;
  final Recipe recipe;
  final List<String> tags;
  final List<String> relatedFoods;

  ScanResult({
    required this.name,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipe,
    required this.tags,
    required this.relatedFoods,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      name: json['name'] ?? '',
      origin: json['origin'] ?? '',
      description: json['description'] ?? '',
      history: json['history'] ?? '',
      recipe: Recipe.fromJson(json['recipe'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      relatedFoods: List<String>.from(json['relatedFoods'] ?? []),
    );
  }
}
