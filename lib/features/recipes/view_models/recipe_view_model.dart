import 'package:flutter/foundation.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';

class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({required RecipeApiClient apiClient})
    : _apiClient = apiClient;

  final RecipeApiClient _apiClient;

  final List<String> _mockPantryIngredients = <String>[
    'chicken',
    'egg',
    'tomato',
    'garlic',
    'onion',
  ];

  List<Recipe> _recipes = <Recipe>[];
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _errorMessage;

  String? _selectedDiet;
  String? _selectedCuisine;
  int? _maxReadyTime;

  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get errorMessage => _errorMessage;
  List<String> get mockPantryIngredients =>
      List<String>.unmodifiable(_mockPantryIngredients);

  String? get selectedDiet => _selectedDiet;
  String? get selectedCuisine => _selectedCuisine;
  int? get maxReadyTime => _maxReadyTime;

  static const List<String> dietOptions = <String>[
    'vegetarian',
    'vegan',
    'gluten free',
    'ketogenic',
    'paleo',
  ];

  static const List<String> cuisineOptions = <String>[
    'vietnamese',
    'italian',
    'japanese',
    'thai',
    'indian',
    'american',
  ];

  Future<void> loadInitialSuggestions() async {
    await fetchRecipes();
  }

  Future<void> fetchRecipes({List<String>? pantryIngredients}) async {
		print('[RecipeViewModel.fetchRecipes] Called with pantryIngredients: $pantryIngredients');
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			final List<String> ingredients =
					pantryIngredients ?? _mockPantryIngredients;
			print('[RecipeViewModel.fetchRecipes] Using ingredients: $ingredients');
      _recipes = await _apiClient.getRecipeSuggestions(
        pantryIngredients: ingredients,
        diet: _selectedDiet,
        cuisine: _selectedCuisine,
        maxReadyTime: _maxReadyTime,
      );
    } catch (error) {
      print('[RecipeViewModel.fetchRecipes] ERROR: $error');
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
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
    notifyListeners();
  }

  void updateCuisineFilter(String? value) {
    _selectedCuisine = (value == null || value.isEmpty) ? null : value;
    notifyListeners();
  }

  void updateMaxReadyTime(int? minutes) {
    _maxReadyTime = (minutes == null || minutes <= 0) ? null : minutes;
    notifyListeners();
  }

  void updateMockPantryIngredients(List<String> ingredients) {
    _mockPantryIngredients
      ..clear()
      ..addAll(
        ingredients
            .where((String item) => item.trim().isNotEmpty)
            .map((e) => e.trim()),
      );
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
