class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.summary,
    this.instructions,
    this.readyInMinutes,
    this.servings,
    this.sourceUrl,
    this.healthScore,
    this.isVegetarian = false,
    this.isVegan = false,
    this.ingredients = const <RecipeIngredient>[],
    this.diets = const <String>[],
    this.healthLabels = const <String>[],
    this.cuisines = const <String>[],
    this.mealTypes = const <String>[],
    this.dishTypes = const <String>[],
    this.usedIngredientCount = 0,
    this.missedIngredientCount = 0,
    this.usedIngredients = const <String>[],
    this.missedIngredients = const <String>[],
    this.videoUrl,
  });

  final int id;
  final String title;
  final String imageUrl;
  final String? summary;
  final String? instructions;
  final int? readyInMinutes;
  final int? servings;
  final String? sourceUrl;
  final num? healthScore;
  final bool isVegetarian;
  final bool isVegan;
  final List<RecipeIngredient> ingredients;
  final List<String> diets;
  final List<String> healthLabels;
  final List<String> cuisines;
  final List<String> mealTypes;
  final List<String> dishTypes;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> usedIngredients;
  final List<String> missedIngredients;
  final String? videoUrl;

  int get totalIngredientCount => usedIngredientCount + missedIngredientCount;

  bool get canCookFromPantry =>
      totalIngredientCount > 0 && missedIngredientCount == 0;

  factory Recipe.fromSearchJson(Map<String, dynamic> json) {
    final int parsedId = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;
    final String parsedImageUrl = _resolveImageUrl(json, parsedId);

    return Recipe(
      id: parsedId,
      title: (json['title'] ?? '').toString(),
      imageUrl: parsedImageUrl,
      summary: json['summary']?.toString(),
      instructions: json['instructions']?.toString(),
      readyInMinutes: json['readyInMinutes'] is int
          ? json['readyInMinutes'] as int
          : int.tryParse('${json['readyInMinutes']}'),
      servings: json['servings'] is int
          ? json['servings'] as int
          : int.tryParse('${json['servings']}'),
      sourceUrl: json['sourceUrl']?.toString(),
      healthScore: json['healthScore'] as num?,
      isVegetarian: json['vegetarian'] == true,
      isVegan: json['vegan'] == true,
      ingredients:
          (json['extendedIngredients'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(RecipeIngredient.fromJson)
              .toList(),
      diets: (json['diets'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      healthLabels:
          (json['healthLabels'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(),
      cuisines: (json['cuisines'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      mealTypes: (json['mealTypes'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      dishTypes: (json['dishTypes'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      usedIngredientCount: json['usedIngredientCount'] is int
          ? json['usedIngredientCount'] as int
          : int.tryParse('${json['usedIngredientCount']}') ?? 0,
      missedIngredientCount: json['missedIngredientCount'] is int
          ? json['missedIngredientCount'] as int
          : int.tryParse('${json['missedIngredientCount']}') ?? 0,
      usedIngredients:
          (json['usedIngredients'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> item) =>
                    (item['nameClean'] ?? item['name'] ?? '').toString(),
              )
              .where((String value) => value.isNotEmpty)
              .toList(),
      missedIngredients:
          (json['missedIngredients'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(
                (Map<String, dynamic> item) =>
                    (item['nameClean'] ?? item['name'] ?? '').toString(),
              )
              .where((String value) => value.isNotEmpty)
              .toList(),
      videoUrl: json['video']?.toString() ?? json['videoUrl']?.toString(),
    );
  }

  factory Recipe.fromDetailJson(Map<String, dynamic> json) {
    return Recipe.fromSearchJson(json);
  }

  factory Recipe.fromEdamamJson(
    Map<String, dynamic> json, {
    required int id,
    required List<String> pantryIngredients,
  }) {
    final List<RecipeIngredient> parsedIngredients =
        (json['ingredients'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> item) {
              final String text = (item['text'] ?? '').toString().trim();
              final String food = (item['food'] ?? '').toString().trim();
              return RecipeIngredient(
                name: food.isNotEmpty ? food : text,
                original: text.isNotEmpty ? text : food,
                amount: item['quantity'] as num?,
                unit: item['measure']?.toString(),
              );
            })
            .toList();

    final Set<String> normalizedPantry = pantryIngredients
        .map((String value) => value.toLowerCase().trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    final List<String> usedIngredients = <String>[];
    final List<String> missedIngredients = <String>[];

    for (final RecipeIngredient ingredient in parsedIngredients) {
      final String name = ingredient.name.trim();
      final String normalized = name.toLowerCase();
      final bool inPantry = normalizedPantry.any(
        (String pantry) =>
            normalized.contains(pantry) || pantry.contains(normalized),
      );
      if (inPantry) {
        usedIngredients.add(name);
      } else {
        missedIngredients.add(name);
      }
    }

    final List<String> cuisineTypes =
        (json['cuisineType'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().toLowerCase())
            .toList();
    final List<String> dishTypes =
        (json['dishType'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().toLowerCase())
            .toList();
    final List<String> instructionLines =
        (json['instructionLines'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic item) => item.toString().trim())
            .where((String line) => line.isNotEmpty)
            .toList();
    final String sourceName = (json['source'] ?? '').toString().trim();
    final String sourceUrl = (json['url'] ?? '').toString().trim();
    final String summaryText = [
      if (sourceName.isNotEmpty) sourceName,
      if (cuisineTypes.isNotEmpty) 'Am thuc: ${cuisineTypes.join(', ')}',
      if (dishTypes.isNotEmpty) 'Loai mon: ${dishTypes.join(', ')}',
    ].join(' | ');

    return Recipe(
      id: id,
      title: (json['label'] ?? '').toString(),
      imageUrl: _normalizeImageUrl((json['image'] ?? '').toString()),
      summary: summaryText,
      instructions: instructionLines.isEmpty
          ? null
          : instructionLines.join('\n'),
      readyInMinutes: _durationOrNull(json['totalTime']),
      servings: _toInt(json['yield']),
      sourceUrl: sourceUrl,
      healthScore: json['calories'] as num?,
      isVegetarian: _listContains(
        json['healthLabels'] as List<dynamic>?,
        'vegetarian',
      ),
      isVegan: _listContains(json['healthLabels'] as List<dynamic>?, 'vegan'),
      ingredients: parsedIngredients,
      diets: (json['dietLabels'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString().toLowerCase())
          .toList(),
      healthLabels:
          (json['healthLabels'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item.toString().toLowerCase())
              .toList(),
      cuisines: cuisineTypes,
      mealTypes: (json['mealType'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString().toLowerCase())
          .toList(),
      dishTypes: dishTypes,
      usedIngredientCount: usedIngredients.length,
      missedIngredientCount: missedIngredients.length,
      usedIngredients: usedIngredients,
      missedIngredients: missedIngredients,
      videoUrl: null,
    );
  }

  static String _resolveImageUrl(Map<String, dynamic> json, int recipeId) {
    final String candidate =
        (json['image'] ?? json['imageUrl'] ?? json['strMealThumb'] ?? '')
            .toString()
            .trim();

    if (candidate.isNotEmpty) {
      if (candidate.startsWith('//')) {
        return 'https:$candidate';
      }
      if (candidate.startsWith('http://')) {
        return candidate.replaceFirst('http://', 'https://');
      }
      return candidate;
    }

    if (recipeId > 0) {
      return 'https://img.spoonacular.com/recipes/$recipeId-636x393.jpg';
    }

    return '';
  }

  static String _normalizeImageUrl(String value) {
    final String candidate = value.trim();
    if (candidate.startsWith('//')) {
      return 'https:$candidate';
    }
    if (candidate.startsWith('http://')) {
      return candidate.replaceFirst('http://', 'https://');
    }
    return candidate;
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse('${value ?? ''}');
  }

  static int? _durationOrNull(dynamic value) {
    final int? parsed = _toInt(value);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static bool _listContains(List<dynamic>? values, String expected) {
    if (values == null) {
      return false;
    }
    final String target = expected.toLowerCase();
    return values
        .map((dynamic item) => item.toString().toLowerCase())
        .contains(target);
  }
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.name,
    required this.original,
    this.amount,
    this.unit,
  });

  final String name;
  final String original;
  final num? amount;
  final String? unit;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: (json['nameClean'] ?? json['name'] ?? '').toString(),
      original: (json['original'] ?? '').toString(),
      amount: json['amount'] as num?,
      unit: json['unit']?.toString(),
    );
  }
}
