import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';

class PlannedRecipe {
  const PlannedRecipe({
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.addedAtUtcMs,
    this.summary,
    this.readyInMinutes,
    this.servings,
    this.sourceUrl,
    this.shoppingIngredients = const <ShoppingIngredientSnapshot>[],
  });

  final int recipeId;
  final String title;
  final String imageUrl;
  final int addedAtUtcMs;
  final String? summary;
  final int? readyInMinutes;
  final int? servings;
  final String? sourceUrl;
  final List<ShoppingIngredientSnapshot> shoppingIngredients;

  PlannedRecipe copyWith({
    int? recipeId,
    String? title,
    String? imageUrl,
    int? addedAtUtcMs,
    String? summary,
    int? readyInMinutes,
    int? servings,
    String? sourceUrl,
    List<ShoppingIngredientSnapshot>? shoppingIngredients,
  }) {
    return PlannedRecipe(
      recipeId: recipeId ?? this.recipeId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAtUtcMs: addedAtUtcMs ?? this.addedAtUtcMs,
      summary: summary ?? this.summary,
      readyInMinutes: readyInMinutes ?? this.readyInMinutes,
      servings: servings ?? this.servings,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      shoppingIngredients: shoppingIngredients ?? this.shoppingIngredients,
    );
  }

  factory PlannedRecipe.fromRecipe(
    Recipe recipe, {
    required List<ShoppingIngredientSnapshot> shoppingIngredients,
  }) {
    return PlannedRecipe(
      recipeId: recipe.id,
      title: recipe.title,
      imageUrl: recipe.imageUrl,
      addedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      summary: recipe.summary,
      readyInMinutes: recipe.readyInMinutes,
      servings: recipe.servings,
      sourceUrl: recipe.sourceUrl,
      shoppingIngredients: shoppingIngredients,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recipeId': recipeId,
      'title': title,
      'imageUrl': imageUrl,
      'addedAtUtcMs': addedAtUtcMs,
      'summary': summary,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'sourceUrl': sourceUrl,
      'shoppingIngredients': shoppingIngredients.map((
        ShoppingIngredientSnapshot item,
      ) {
        return item.toJson();
      }).toList(),
    };
  }

  factory PlannedRecipe.fromJson(Map<String, dynamic> json) {
    return PlannedRecipe(
      recipeId: (json['recipeId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      addedAtUtcMs: (json['addedAtUtcMs'] as num?)?.toInt() ?? 0,
      summary: json['summary']?.toString(),
      readyInMinutes: (json['readyInMinutes'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toInt(),
      sourceUrl: json['sourceUrl']?.toString(),
      shoppingIngredients:
          (json['shoppingIngredients'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(ShoppingIngredientSnapshot.fromJson)
              .toList(),
    );
  }
}

class ShoppingIngredientSnapshot {
  const ShoppingIngredientSnapshot({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;

  String get normalizedKey => '${_normalize(name)}|${_normalize(unit)}';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name, 'quantity': quantity, 'unit': unit};
  }

  factory ShoppingIngredientSnapshot.fromJson(Map<String, dynamic> json) {
    return ShoppingIngredientSnapshot(
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: (json['unit'] ?? '').toString(),
    );
  }

  static String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
