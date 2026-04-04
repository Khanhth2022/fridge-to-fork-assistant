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
  final List<String> _mainPantryIngredients = <String>[];
  final List<String> _subPantryIngredients = <String>[];

  List<Recipe> _recipes = <Recipe>[];
  List<Recipe> _allFetchedRecipes = <Recipe>[];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _errorMessage;
  String _lastFetchedIngredientKey = '';
  List<String> _currentQueryIngredients = <String>[];
  List<String> _requiredQueryIngredients = <String>[];
  bool _usePantryFallbackStrategy = false;

  String? _selectedDiet;
  String? _selectedHealth;
  String? _selectedCuisine;
  String? _selectedMealType;
  String? _selectedDishType;
  int? _maxReadyTime;
  int? _maxCalories;
  bool _isKeywordSearchMode = false;

  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreRecipes => _hasMoreRecipes;
  bool get isDetailLoading => _isDetailLoading;
  String? get errorMessage => _errorMessage;
  List<String> get mockPantryIngredients =>
      List<String>.unmodifiable(_mockPantryIngredients);
  List<String> get referencePantryIngredients =>
      List<String>.unmodifiable(_referencePantryIngredients);
  List<String> get mainPantryIngredients =>
      List<String>.unmodifiable(_mainPantryIngredients);
  List<String> get subPantryIngredients =>
      List<String>.unmodifiable(_subPantryIngredients);
  List<String> get _activePantryIngredients {
    if (_mockPantryIngredients.isNotEmpty) {
      return _mockPantryIngredients;
    }
    return _referencePantryIngredients;
  }

  String? get selectedDiet => _selectedDiet;
  String? get selectedHealth => _selectedHealth;
  String? get selectedCuisine => _selectedCuisine;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDishType => _selectedDishType;
  int? get maxReadyTime => _maxReadyTime;
  int? get maxCalories => _maxCalories;
  bool get isKeywordSearchMode => _isKeywordSearchMode;

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
  static const int _pageSize = 12;

  bool _isLoadingMore = false;
  bool _hasMoreRecipes = true;
  int _nextFetchOffset = 0;
  final Map<int, int> _priorityRecipeOrder = <int, int>{};

  Future<void> loadInitialSuggestions({bool? usePantryFallbackStrategy}) async {
    await fetchRecipes(usePantryFallbackStrategy: usePantryFallbackStrategy);
  }

  Future<void> fetchRecipes({
    List<String>? pantryIngredients,
    bool forceRefresh = false,
    bool? usePantryFallbackStrategy,
  }) async {
    if (usePantryFallbackStrategy != null) {
      _usePantryFallbackStrategy = usePantryFallbackStrategy;
    }

    final List<String> ingredients = _sanitizeIngredients(
      pantryIngredients ??
          (_currentQueryIngredients.isNotEmpty
              ? _currentQueryIngredients
              : _activePantryIngredients),
    );
    final String ingredientKey = _buildIngredientKey(ingredients);

    if (!forceRefresh &&
        ingredientKey == _lastFetchedIngredientKey &&
        _allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
      notifyListeners();
      return;
    }

    _resetPagingState();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchNextPage(
        ingredients,
        usePantryFallbackStrategy: _usePantryFallbackStrategy,
      );
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _allFetchedRecipes = <Recipe>[];
      _recipes = <Recipe>[];
      _hasMoreRecipes = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreRecipes() async {
    if (_isLoading || _isLoadingMore || !_hasMoreRecipes) {
      return;
    }

    final List<String> ingredients = _sanitizeIngredients(
      _currentQueryIngredients.isNotEmpty
          ? _currentQueryIngredients
          : _activePantryIngredients,
    );
    if (ingredients.isEmpty) {
      _hasMoreRecipes = false;
      notifyListeners();
      return;
    }

    final String ingredientKey = _buildIngredientKey(ingredients);
    if (ingredientKey != _lastFetchedIngredientKey) {
      await fetchRecipes(
        forceRefresh: true,
        usePantryFallbackStrategy: _usePantryFallbackStrategy,
      );
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchNextPage(ingredients, usePantryFallbackStrategy: false);
    } catch (_) {
      // Keep current list visible when loading additional pages fails.
    } finally {
      _isLoadingMore = false;
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

  void updateRequiredQueryIngredients(List<String> ingredients) {
    _requiredQueryIngredients = _sanitizeIngredients(ingredients);
    if (_allFetchedRecipes.isNotEmpty) {
      _applyFiltersAndSort();
    }
    notifyListeners();
  }

  Future<void> searchRecipesByKeyword(String keyword) async {
    final String normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _isKeywordSearchMode = true;
    notifyListeners();

    try {
      final RecipeSuggestionPage page = await _apiClient
          .searchRecipesByKeywordPage(
            keyword: normalizedKeyword,
            pantryIngredients: _referencePantryIngredients.isNotEmpty
                ? _referencePantryIngredients
                : _activePantryIngredients,
            from: 0,
            number: _pageSize,
          );

      _allFetchedRecipes = List<Recipe>.from(page.recipes);
      _recipes = List<Recipe>.from(page.recipes);
      _currentQueryIngredients = <String>[normalizedKeyword];
      _lastFetchedIngredientKey = _buildIngredientKey(<String>[
        normalizedKeyword,
      ]);
      _nextFetchOffset = _pageSize;
      _hasMoreRecipes = false;
      _isLoadingMore = false;
      _priorityRecipeOrder.clear();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _allFetchedRecipes = <Recipe>[];
      _recipes = <Recipe>[];
      _hasMoreRecipes = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearKeywordSearch() async {
    _isKeywordSearchMode = false;
    await fetchRecipes(forceRefresh: true, usePantryFallbackStrategy: false);
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

  void updateClassifiedPantryIngredients({
    required List<String> mainIngredients,
    required List<String> subIngredients,
  }) {
    _mainPantryIngredients
      ..clear()
      ..addAll(_sanitizeIngredients(mainIngredients));
    _subPantryIngredients
      ..clear()
      ..addAll(_sanitizeIngredients(subIngredients));

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
    return recipe.totalIngredientCount > 0;
  }

  int _sortByPantryUsefulness(Recipe a, Recipe b) {
    if (_usePantryFallbackStrategy) {
      final int? priorityIndexA = _priorityRecipeOrder[a.id];
      final int? priorityIndexB = _priorityRecipeOrder[b.id];
      if (priorityIndexA != null && priorityIndexB != null) {
        return priorityIndexA.compareTo(priorityIndexB);
      }
      if (priorityIndexA != null) {
        return -1;
      }
      if (priorityIndexB != null) {
        return 1;
      }

      final int scoreA = _computePantryScore(a);
      final int scoreB = _computePantryScore(b);
      final int scoreCompare = scoreB.compareTo(scoreA);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
    }

    final PantryMatchResult matchA = getPantryMatchForRecipe(a);
    final PantryMatchResult matchB = getPantryMatchForRecipe(b);

    if (matchA.isFullMatch != matchB.isFullMatch) {
      return matchA.isFullMatch ? -1 : 1;
    }

    final int missingCompare = matchA.missingIngredientCount.compareTo(
      matchB.missingIngredientCount,
    );
    if (missingCompare != 0) {
      return missingCompare;
    }

    final double availableRatioA = matchA.totalIngredientCount == 0
        ? 0
        : matchA.availableIngredientCount / matchA.totalIngredientCount;
    final double availableRatioB = matchB.totalIngredientCount == 0
        ? 0
        : matchB.availableIngredientCount / matchB.totalIngredientCount;
    final int ratioCompare = availableRatioB.compareTo(availableRatioA);
    if (ratioCompare != 0) {
      return ratioCompare;
    }

    return b.usedIngredientCount.compareTo(a.usedIngredientCount);
  }

  int _computePantryScore(Recipe recipe) {
    final List<String> requiredIngredients = _requiredIngredients(recipe);
    if (requiredIngredients.isEmpty) {
      return 0;
    }

    final Set<String> normalizedMain = _mainPantryIngredients
        .map(_normalizeIngredient)
        .where((String value) => value.isNotEmpty)
        .toSet();
    final Set<String> normalizedSub = _subPantryIngredients
        .map(_normalizeIngredient)
        .where((String value) => value.isNotEmpty)
        .toSet();

    if (normalizedMain.isEmpty && normalizedSub.isEmpty) {
      return 0;
    }

    int mainUsed = 0;
    int subUsed = 0;
    int mainMissing = 0;
    int subMissing = 0;

    for (final String ingredient in requiredIngredients) {
      final bool inMain = _isInPantry(ingredient, normalizedMain);
      final bool inSub = _isInPantry(ingredient, normalizedSub);

      if (inMain) {
        mainUsed++;
      } else if (inSub) {
        subUsed++;
      } else {
        final bool shouldTreatAsMain = _looksLikeMainIngredient(
          ingredient,
          normalizedMain,
        );
        if (shouldTreatAsMain) {
          mainMissing++;
        } else {
          subMissing++;
        }
      }
    }

    return (mainUsed * 4) +
        (subUsed * 1) -
        (mainMissing * 3) -
        (subMissing * 1);
  }

  bool _looksLikeMainIngredient(String ingredient, Set<String> normalizedMain) {
    final List<String> tokens = _normalizeIngredient(ingredient)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String token) => token.length >= 3)
        .toList();
    if (tokens.isEmpty) {
      return false;
    }
    return normalizedMain.any((String mainItem) {
      for (final String token in tokens) {
        if (mainItem.contains(token)) {
          return true;
        }
      }
      return false;
    });
  }

  void _applyFiltersAndSort() {
    List<Recipe> baseFiltered;
    if (_isKeywordSearchMode) {
      baseFiltered = List<Recipe>.from(_allFetchedRecipes);
    } else {
      baseFiltered = _allFetchedRecipes.where(_matchesNonPantryFilters).toList()
        ..sort(_sortByPantryUsefulness);
    }

    if (_requiredQueryIngredients.isNotEmpty) {
      baseFiltered = baseFiltered
          .where(_matchesRequiredIngredients)
          .toList();
    }

    _recipes = baseFiltered;
  }

  bool _matchesNonPantryFilters(Recipe recipe) {
    if (!_matchesRequiredIngredients(recipe)) {
      return false;
    }
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

    return true;
  }

  bool _matchesRequiredIngredients(Recipe recipe) {
    if (_requiredQueryIngredients.isEmpty) {
      return true;
    }

    final List<String> requiredIngredients = _requiredIngredients(recipe);
    if (requiredIngredients.isEmpty) {
      return false;
    }

    final Set<String> normalizedRecipe = requiredIngredients
        .map(_normalizeIngredient)
        .where((String value) => value.isNotEmpty)
        .toSet();

    for (final String required in _requiredQueryIngredients) {
      if (!_isInPantry(required, normalizedRecipe)) {
        return false;
      }
    }

    return true;
  }

  Set<String> _normalizedReferencePantry() {
    final List<String> source = _referencePantryIngredients.isNotEmpty
        ? _referencePantryIngredients
        : _activePantryIngredients;

    return source
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

  void _resetPagingState() {
    _allFetchedRecipes = <Recipe>[];
    _recipes = <Recipe>[];
    _nextFetchOffset = 0;
    _hasMoreRecipes = true;
    _isLoadingMore = false;
    _priorityRecipeOrder.clear();
  }

  Future<void> _fetchNextPage(
    List<String> ingredients, {
    required bool usePantryFallbackStrategy,
  }) async {
    final RecipeSuggestionPage page = await _apiClient.getRecipeSuggestionsPage(
      pantryIngredients: ingredients,
      mainIngredients: _mainPantryIngredients,
      subIngredients: _subPantryIngredients,
      cuisine: _selectedCuisine,
      mealType: _selectedMealType,
      dishType: _selectedDishType,
      diet: _selectedDiet,
      health: _selectedHealth,
      maxReadyTime: _maxReadyTime,
      maxCalories: _maxCalories,
      usePantryFallbackStrategy: usePantryFallbackStrategy,
      from: _nextFetchOffset,
      number: _pageSize,
    );
    if (page.priorityRecipeIds.isNotEmpty && _priorityRecipeOrder.isEmpty) {
      int order = 0;
      for (final int id in page.priorityRecipeIds) {
        _priorityRecipeOrder[id] = order;
        order++;
      }
    }
    final List<Recipe> fetched = page.recipes;
    final List<String> resolvedQueryIngredients =
        page.queryIngredients.isNotEmpty
        ? _sanitizeIngredients(page.queryIngredients)
        : ingredients;

    _nextFetchOffset += _pageSize;
    _currentQueryIngredients = resolvedQueryIngredients;

    if (fetched.isEmpty) {
      _hasMoreRecipes = false;
      _lastFetchedIngredientKey = _buildIngredientKey(resolvedQueryIngredients);
      _applyFiltersAndSort();
      return;
    }

    final Set<int> existingIds = _allFetchedRecipes
        .map((Recipe recipe) => recipe.id)
        .toSet();
    final List<Recipe> uniqueFetched = fetched
        .where((Recipe recipe) => !existingIds.contains(recipe.id))
        .toList();

    _allFetchedRecipes.addAll(uniqueFetched);
    _lastFetchedIngredientKey = _buildIngredientKey(resolvedQueryIngredients);
    _hasMoreRecipes = page.hasNext;
    _applyFiltersAndSort();
  }
}
