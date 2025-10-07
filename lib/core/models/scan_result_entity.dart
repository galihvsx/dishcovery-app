import 'dart:convert';

import 'package:dishcovery_app/core/models/recipe_model.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ScanResultEntity {
  @Id()
  int id;

  bool isFood;
  String imagePath;
  String name;
  String origin;
  String description;
  String history;

  // Recipe stored as JSON string
  String recipeJson;

  // Tags stored as comma-separated string
  String tagsString;

  bool shared;

  @Property(type: PropertyType.date)
  DateTime? sharedAt;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  ScanResultEntity({
    this.id = 0,
    required this.isFood,
    required this.imagePath,
    required this.name,
    required this.origin,
    required this.description,
    required this.history,
    required this.recipeJson,
    required this.tagsString,
    this.shared = false,
    this.sharedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert from domain model to entity
  factory ScanResultEntity.fromScanResult(ScanResult scanResult) {
    return ScanResultEntity(
      id: scanResult.id ?? 0,
      isFood: scanResult.isFood,
      imagePath: scanResult.imagePath,
      name: scanResult.name,
      origin: scanResult.origin,
      description: scanResult.description,
      history: scanResult.history,
      recipeJson: jsonEncode(scanResult.recipe.toJson()),
      tagsString: scanResult.tags.join(','),
      shared: scanResult.shared,
      sharedAt: scanResult.sharedAt,
      createdAt: scanResult.createdAt,
    );
  }

  // Convert from entity to domain model
  ScanResult toScanResult() {
    return ScanResult(
      id: id == 0 ? null : id,
      isFood: isFood,
      imagePath: imagePath,
      name: name,
      origin: origin,
      description: description,
      history: history,
      recipe: Recipe.fromJson(jsonDecode(recipeJson)),
      tags: tagsString.isEmpty ? [] : tagsString.split(','),
      shared: shared,
      sharedAt: sharedAt,
      createdAt: createdAt,
    );
  }

  // Helper method to get tags as list
  List<String> get tags => tagsString.isEmpty ? [] : tagsString.split(',');

  // Helper method to set tags from list
  set tags(List<String> tags) {
    tagsString = tags.join(',');
  }

  // Helper method to get Recipe object
  Recipe getRecipe() {
    return Recipe.fromJson(jsonDecode(recipeJson));
  }

  // Helper method to set Recipe object
  void setRecipe(Recipe recipe) {
    recipeJson = jsonEncode(recipe.toJson());
  }
}