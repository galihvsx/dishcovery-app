import 'dart:convert';

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
  final bool shared; // Field untuk tracking apakah sudah di-share sebagai feed
  final DateTime? sharedAt; // Kapan di-share
  final DateTime createdAt; // Kapan scan dilakukan

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
    this.shared = false,
    this.sharedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

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
      shared: json['shared'] == 1,
      sharedAt: json['sharedAt'] != null
          ? DateTime.parse(json['sharedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
      'shared': shared ? 1 : 0,
      'sharedAt': sharedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScanResult.fromDbMap(Map<String, dynamic> dbMap) {
    return ScanResult(
      id: dbMap['id'],
      isFood: dbMap['isFood'] == 1,
      imagePath: dbMap['imagePath'],
      name: dbMap['name'],
      origin: dbMap['origin'],
      description: dbMap['description'],
      history: dbMap['history'],
      recipe: Recipe.fromJson(jsonDecode(dbMap['recipe'] ?? '{}')),
      tags: (jsonDecode(dbMap['tags'] ?? '[]') as List).cast<String>(),
      shared: dbMap['shared'] == 1,
      sharedAt: dbMap['sharedAt'] != null
          ? DateTime.parse(dbMap['sharedAt'])
          : null,
      createdAt: DateTime.parse(dbMap['createdAt']),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'isFood': isFood ? 1 : 0,
      'imagePath': imagePath,
      'name': name,
      'origin': origin,
      'description': description,
      'history': history,
      'recipe': jsonEncode(recipe.toJson()),
      'tags': jsonEncode(tags),
      'shared': shared ? 1 : 0,
      'sharedAt': sharedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
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
    bool? shared,
    DateTime? sharedAt,
    DateTime? createdAt,
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
      shared: shared ?? this.shared,
      sharedAt: sharedAt ?? this.sharedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
