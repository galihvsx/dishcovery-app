class Recipe {
  final List<String> ingredients;
  final List<String> steps;

  Recipe({required this.ingredients, required this.steps});

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
    );
  }
}
