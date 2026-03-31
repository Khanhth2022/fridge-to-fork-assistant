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
		this.dishTypes = const <String>[],
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
	final List<String> dishTypes;

	factory Recipe.fromSearchJson(Map<String, dynamic> json) {
		return Recipe(
			id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
			title: (json['title'] ?? '').toString(),
			imageUrl: (json['image'] ?? '').toString(),
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
			ingredients: (json['extendedIngredients'] as List<dynamic>? ?? const <dynamic>[])
					.whereType<Map<String, dynamic>>()
					.map(RecipeIngredient.fromJson)
					.toList(),
			diets: (json['diets'] as List<dynamic>? ?? const <dynamic>[])
					.map((dynamic item) => item.toString())
					.toList(),
			dishTypes: (json['dishTypes'] as List<dynamic>? ?? const <dynamic>[])
					.map((dynamic item) => item.toString())
					.toList(),
		);
	}

	factory Recipe.fromDetailJson(Map<String, dynamic> json) {
		return Recipe.fromSearchJson(json);
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
