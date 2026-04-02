import 'package:flutter/foundation.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';

class PantryMatchResult {
  const PantryMatchResult({
    required this.totalIngredientCount,
    required this.availableIngredientCount,
    required this.missingIngredients,
  });

  final int totalIngredientCount;
  final int availableIngredientCount;
  final List<String> missingIngredients;

  int get missingIngredientCount =>
      totalIngredientCount - availableIngredientCount;

  bool get isFullMatch =>
      totalIngredientCount > 0 && missingIngredientCount == 0;
}

class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({required RecipeApiClient apiClient})
    : _apiClient = apiClient;

  final RecipeApiClient _apiClient;

  final List<String> _mockPantryIngredients = <String>[];

  final List<String> _referencePantryIngredients = <String>[];

  List<Recipe> _recipes = <Recipe>[];
  List<Recipe> _allFetchedRecipes = <Recipe>[];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _errorMessage;
  String _lastFetchedIngredientKey = '';

  String? _selectedDiet;
  String? _selectedHealth;
  String? _selectedCuisine;
  String? _selectedMealType;
  String? _selectedDishType;
  int? _maxReadyTime;
  int? _maxCalories;

  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get errorMessage => _errorMessage;
  List<String> get mockPantryIngredients =>
      List<String>.unmodifiable(_mockPantryIngredients);
  List<String> get referencePantryIngredients =>
      List<String>.unmodifiable(_referencePantryIngredients);

  String? get selectedDiet => _selectedDiet;
  String? get selectedHealth => _selectedHealth;
  String? get selectedCuisine => _selectedCuisine;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDishType => _selectedDishType;
  int? get maxReadyTime => _maxReadyTime;
  int? get maxCalories => _maxCalories;

  static const List<String> dietOptions = <String>[
    'balanced',
    'high-protein',
    'low-carb',
    'low-fat',
  ];

  static const List<String> healthOptions = <String>[
    'vegetarian',
    'vegan',
    'gluten-free',
    'dairy-free',
    'egg-free',
    'peanut-free',
    'tree-nut-free',
    'soy-free',
    'fish-free',
    'shellfish-free',
    'wheat-free',
  ];

  static const List<String> cuisineOptions = <String>[
    'american',
    'asian',
    'british',
    'caribbean',
    'central europe',
    'chinese',
    'eastern europe',
    'french',
    'indian',
    'italian',
    'japanese',
    'kosher',
    'mediterranean',
    'mexican',
    'middle eastern',
    'nordic',
    'south american',
    'south east asian',
  ];

  static const List<String> mealTypeOptions = <String>[
    'breakfast',
    'brunch',
    'lunch',
    'dinner',
    'snack',
    'teatime',
  ];

  static const List<String> dishTypeOptions = <String>[
    'main course',
    'starter',
    'side dish',
    'salad',
    'soup',
    'dessert',
    'drinks',
    'sandwiches',
  ];

  static const int _nearEnoughThreshold = 2;

  Future<void> loadInitialSuggestions() async {
    await fetchRecipes();
  }

  Future<void> fetchRecipes({
    List<String>? pantryIngredients,
    bool forceRefresh = false,
  }) async {
    final List<String> ingredients = _sanitizeIngredients(
      pantryIngredients ?? _mockPantryIngredients,
    );
    final String ingredientKey = _buildIngredientKey(ingredients);

    if (!forceRefresh &&
        ingredientKey == _lastFetchedIngredientKey &&
        _allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Recipe> fetched = await _apiClient.getRecipeSuggestions(
        pantryIngredients: ingredients,
        cuisine: _selectedCuisine,
        mealType: _selectedMealType,
        dishType: _selectedDishType,
        diet: _selectedDiet,
        health: _selectedHealth,
        maxReadyTime: _maxReadyTime,
        maxCalories: _maxCalories,
        number: 24,
      );

      _allFetchedRecipes = fetched;
      _lastFetchedIngredientKey = ingredientKey;
      _applyFiltersAndSort();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _allFetchedRecipes = <Recipe>[];
      _recipes = <Recipe>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecipeDetail(int recipeId) async {
    _isDetailLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRecipe = await _apiClient.getRecipeDetail(recipeId);
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void updateDietFilter(String? value) {
    _selectedDiet = (value == null || value.isEmpty) ? null : value;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateHealthFilter(String? value) {
    _selectedHealth = (value == null || value.isEmpty) ? null : value;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateCuisineFilter(String? value) {
    _selectedCuisine = (value == null || value.isEmpty) ? null : value;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateMealTypeFilter(String? value) {
    _selectedMealType = (value == null || value.isEmpty) ? null : value;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateDishTypeFilter(String? value) {
    _selectedDishType = (value == null || value.isEmpty) ? null : value;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateMaxReadyTime(int? minutes) {
    _maxReadyTime = (minutes == null || minutes <= 0) ? null : minutes;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateMaxCalories(int? calories) {
    _maxCalories = (calories == null || calories <= 0) ? null : calories;
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  void updateMockPantryIngredients(List<String> ingredients) {
    _mockPantryIngredients
      ..clear()
      ..addAll(_sanitizeIngredients(ingredients));
    notifyListeners();
  }

  void updateReferencePantryIngredients(List<String> ingredients) {
    _referencePantryIngredients
      ..clear()
      ..addAll(_sanitizeIngredients(ingredients));

    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  PantryMatchResult getPantryMatchForRecipe(Recipe recipe) {
    final List<String> requiredIngredients = _requiredIngredients(recipe);
    if (requiredIngredients.isEmpty) {
      return const PantryMatchResult(
        totalIngredientCount: 0,
        availableIngredientCount: 0,
        missingIngredients: <String>[],
      );
    }

    final Set<String> normalizedPantry = _normalizedReferencePantry();
    int available = 0;
    final List<String> missing = <String>[];

    for (final String ingredient in requiredIngredients) {
      if (_isInPantry(ingredient, normalizedPantry)) {
        available++;
      } else {
        missing.add(ingredient);
      }
    }

    return PantryMatchResult(
      totalIngredientCount: requiredIngredients.length,
      availableIngredientCount: available,
      missingIngredients: missing,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void applyCurrentFilters() {
    _applyFiltersAndSort();
    notifyListeners();
  }

  bool _matchesCurrentFilters(Recipe recipe) {
    if (_maxReadyTime != null) {
      if (recipe.readyInMinutes == null) {
        return false;
      }
      if (recipe.readyInMinutes! > _maxReadyTime!) {
        return false;
      }
    }

    if (_maxCalories != null && recipe.healthScore != null) {
      if (recipe.healthScore! > _maxCalories!) {
        return false;
      }
    }

    if (_selectedMealType != null && _selectedMealType!.isNotEmpty) {
      if (!_matchesByAny(recipe.mealTypes, _selectedMealType!)) {
        return false;
      }
    }

    if (_selectedDishType != null && _selectedDishType!.isNotEmpty) {
      if (!_matchesByAny(recipe.dishTypes, _selectedDishType!)) {
        return false;
      }
    }

    if (_selectedCuisine != null && _selectedCuisine!.isNotEmpty) {
      if (!_matchesByAny(recipe.cuisines, _selectedCuisine!)) {
        return false;
      }
    }

    if (_selectedDiet != null && _selectedDiet!.isNotEmpty) {
      if (!_matchesByAny(recipe.diets, _selectedDiet!)) {
        return false;
      }
    }

    if (_selectedHealth != null && _selectedHealth!.isNotEmpty) {
      if (!_matchesByAny(recipe.healthLabels, _selectedHealth!)) {
        return false;
      }
    }

    return _isCookableOrNearEnough(recipe);
  }

  bool _matchesByAny(List<String> values, String selected) {
    if (values.isEmpty) {
      return true;
    }

    final String normalizedSelected = _normalizeIngredient(selected);
    return values.any((String value) {
      final String normalizedValue = _normalizeIngredient(value);
      return normalizedValue == normalizedSelected ||
          normalizedValue.contains(normalizedSelected) ||
          normalizedSelected.contains(normalizedValue);
    });
  }

  bool _isCookableOrNearEnough(Recipe recipe) {
    if (recipe.canCookFromPantry) {
      return true;
    }
    return recipe.missedIngredientCount > 0 &&
        recipe.missedIngredientCount <= _nearEnoughThreshold;
  }

  int _sortByPantryUsefulness(Recipe a, Recipe b) {
    if (a.canCookFromPantry != b.canCookFromPantry) {
      return a.canCookFromPantry ? -1 : 1;
    }

    final int missingCompare = a.missedIngredientCount.compareTo(
      b.missedIngredientCount,
    );
    if (missingCompare != 0) {
      return missingCompare;
    }

    return b.usedIngredientCount.compareTo(a.usedIngredientCount);
  }

  void _applyFiltersAndSort() {
    _recipes = _allFetchedRecipes.where(_matchesCurrentFilters).toList()
      ..sort(_sortByPantryUsefulness);
  }

  Set<String> _normalizedReferencePantry() {
    return _referencePantryIngredients
        .map(_normalizeIngredient)
        .where((String value) => value.isNotEmpty)
        .toSet();
  }

  List<String> _requiredIngredients(Recipe recipe) {
    final List<String> fromRecipe = <String>[
      ...recipe.usedIngredients,
      ...recipe.missedIngredients,
    ];

    if (fromRecipe.isEmpty) {
      fromRecipe.addAll(
        recipe.ingredients.map((RecipeIngredient ingredient) {
          return ingredient.name.trim().isNotEmpty
              ? ingredient.name
              : ingredient.original;
        }),
      );
    }

    final List<String> result = <String>[];
    final Set<String> seen = <String>{};

    for (final String ingredient in fromRecipe) {
      final String normalized = _normalizeIngredient(ingredient);
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(ingredient.trim());
    }

    return result;
  }

  bool _isInPantry(String ingredient, Set<String> normalizedPantry) {
    final String normalizedIngredient = _normalizeIngredient(ingredient);
    for (final String pantryItem in normalizedPantry) {
      if (normalizedIngredient.contains(pantryItem) ||
          pantryItem.contains(normalizedIngredient)) {
        return true;
      }
    }
    return false;
  }

  List<String> _sanitizeIngredients(List<String> ingredients) {
    final List<String> result = <String>[];
    final Set<String> seen = <String>{};

    for (final String ingredient in ingredients) {
      final String normalized = _normalizeIngredient(ingredient);
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(ingredient.trim());
    }

    return result;
  }

  String _buildIngredientKey(List<String> ingredients) {
    final List<String> normalized =
        ingredients
            .map(_normalizeIngredient)
            .where((String value) => value.isNotEmpty)
            .toList()
          ..sort();
    return normalized.join('|');
  }

  String _normalizeIngredient(String value) {
    return value.toLowerCase().trim();
  }
}
