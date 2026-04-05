import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fridge_to_fork_assistant/core/config/api_config.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:http/http.dart' as http;

class RecipeApiClient {
  RecipeApiClient({
    http.Client? httpClient,
    String? appId,
    String? appKey,
    String? accountUser,
  }) : _httpClient = httpClient ?? http.Client(),
       _appId = (appId != null && appId.trim().isNotEmpty)
           ? appId
           : ApiConfig.edamamAppId,
       _appKey = (appKey != null && appKey.trim().isNotEmpty)
           ? appKey
           : ApiConfig.edamamAppKey,
       _accountUser = (accountUser != null && accountUser.trim().isNotEmpty)
           ? accountUser
           : ApiConfig.edamamAccountUser;

  static const String _baseHost = 'api.edamam.com';
  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client _httpClient;
  final String _appId;
  final String _appKey;
  final String _accountUser;
  final Map<int, String> _idToUri = <int, String>{};
  final Map<int, Recipe> _recipeCache = <int, Recipe>{};

  Future<List<Recipe>> getRecipeSuggestions({
    required List<String> pantryIngredients,
    String? cuisine,
    String? mealType,
    String? dishType,
    String? diet,
    String? health,
    int? maxReadyTime,
    int? maxCalories,
    int number = 12,
  }) async {
    _ensureCredentials();

    if (pantryIngredients.isEmpty) {
      return <Recipe>[];
    }

    final String queryText = pantryIngredients.take(6).join(' ');
    final Map<String, String> query = <String, String>{
      'type': 'public',
      'q': queryText,
      'app_id': _appId,
      'app_key': _appKey,
      'random': 'false',
    };

    if (cuisine != null && cuisine.isNotEmpty) {
      query['cuisineType'] = cuisine;
    }
    if (mealType != null && mealType.isNotEmpty) {
      query['mealType'] = mealType;
    }
    if (dishType != null && dishType.isNotEmpty) {
      query['dishType'] = dishType;
    }
    if (diet != null && diet.isNotEmpty) {
      query['diet'] = diet;
    }
    if (health != null && health.isNotEmpty) {
      query['health'] = health;
    }
    if (maxReadyTime != null && maxReadyTime > 0) {
      query['time'] = '1-$maxReadyTime';
    }
    if (maxCalories != null && maxCalories > 0) {
      query['calories'] = '1-$maxCalories';
    }

    final Uri uri = Uri.https(_baseHost, '/api/recipes/v2', query);
    final Map<String, dynamic> payload = await _getJson(uri);

    final List<dynamic> hits =
        payload['hits'] as List<dynamic>? ?? const <dynamic>[];
    final List<Recipe> recipes = <Recipe>[];

    for (final dynamic hit in hits) {
      if (hit is! Map<String, dynamic>) {
        continue;
      }
      final Map<String, dynamic>? recipeJson =
          hit['recipe'] as Map<String, dynamic>?;
      if (recipeJson == null) {
        continue;
      }

      final String recipeUri = (recipeJson['uri'] ?? '').toString();
      final int id = _edamamIdFromUri(recipeUri);
      if (id <= 0) {
        continue;
      }

      final Recipe recipe = Recipe.fromEdamamJson(
        recipeJson,
        id: id,
        pantryIngredients: pantryIngredients,
      );
      _idToUri[id] = recipeUri;
      _recipeCache[id] = recipe;
      recipes.add(recipe);

      if (recipes.length >= number) {
        break;
      }
    }

    return recipes;
  }

  Future<RecipeSuggestionPage> searchRecipesByKeywordPage({
    required String keyword,
    required List<String> pantryIngredients,
    int from = 0,
    int number = 12,
  }) async {
    _ensureCredentials();

    final String normalizedKeyword = keyword.trim();
    if (normalizedKeyword.isEmpty) {
      return const RecipeSuggestionPage(
        recipes: <Recipe>[],
        queryIngredients: <String>[],
        priorityRecipeIds: <int>[],
        hasNext: false,
      );
    }

    final List<Recipe> recipes = await _getRecipeSuggestionsByQuery(
      queryText: normalizedKeyword,
      pantryIngredients: pantryIngredients,
      from: from,
      number: number,
    );

    return RecipeSuggestionPage(
      recipes: recipes,
      queryIngredients: <String>[normalizedKeyword],
      priorityRecipeIds: const <int>[],
      hasNext: recipes.length >= number,
    );
  }

  Future<RecipeSuggestionPage> getRecipeSuggestionsPage({
    required List<String> pantryIngredients,
    List<String> mainIngredients = const <String>[],
    List<String> subIngredients = const <String>[],
    String? cuisine,
    String? mealType,
    String? dishType,
    String? diet,
    String? health,
    int? maxReadyTime,
    int? maxCalories,
    bool usePantryFallbackStrategy = false,
    int from = 0,
    int number = 12,
  }) async {
    _ensureCredentials();

    List<String> queryIngredients = pantryIngredients;
    if (queryIngredients.isEmpty && usePantryFallbackStrategy) {
      if (mainIngredients.isNotEmpty) {
        queryIngredients = mainIngredients;
      } else if (subIngredients.isNotEmpty) {
        queryIngredients = subIngredients;
      }
    }

    if (queryIngredients.isEmpty) {
      return const RecipeSuggestionPage(
        recipes: <Recipe>[],
        queryIngredients: <String>[],
        priorityRecipeIds: <int>[],
        hasNext: false,
      );
    }

    final String queryText = queryIngredients.take(6).join(' ');
    final List<Recipe> recipes = await _getRecipeSuggestionsByQuery(
      queryText: queryText,
      pantryIngredients: pantryIngredients.isNotEmpty
          ? pantryIngredients
          : queryIngredients,
      cuisine: cuisine,
      mealType: mealType,
      dishType: dishType,
      diet: diet,
      health: health,
      maxReadyTime: maxReadyTime,
      maxCalories: maxCalories,
      from: from,
      number: number,
    );

    return RecipeSuggestionPage(
      recipes: recipes,
      queryIngredients: queryIngredients,
      priorityRecipeIds: const <int>[],
      hasNext: recipes.length >= number,
    );
  }

  Future<Recipe> getRecipeDetail(int recipeId) async {
    _ensureCredentials();

    final Recipe? cached = _recipeCache[recipeId];
    if (cached != null) {
      return cached;
    }

    final String? recipeUri = _idToUri[recipeId];
    if (recipeUri == null || recipeUri.isEmpty) {
      throw const FormatException(
        'Khong tim thay cong thuc trong bo nho tam. Vui long quay lai danh sach va mo lai chi tiet mon.',
      );
    }

    final Uri uri = Uri.https(
      _baseHost,
      '/api/recipes/v2/by-uri',
      <String, String>{
        'type': 'public',
        'app_id': _appId,
        'app_key': _appKey,
        'uri': recipeUri,
      },
    );

    final Map<String, dynamic> payload = await _getJson(uri);
    final List<dynamic> hits =
        payload['hits'] as List<dynamic>? ?? const <dynamic>[];
    if (hits.isEmpty || hits.first is! Map<String, dynamic>) {
      throw const FormatException(
        'Khong lay duoc chi tiet cong thuc tu Edamam.',
      );
    }
    final Map<String, dynamic>? recipeJson =
        (hits.first as Map<String, dynamic>)['recipe'] as Map<String, dynamic>?;
    if (recipeJson == null) {
      throw const FormatException('Du lieu chi tiet cong thuc khong hop le.');
    }

    final Recipe recipe = Recipe.fromEdamamJson(
      recipeJson,
      id: recipeId,
      pantryIngredients: cached?.usedIngredients ?? const <String>[],
    );
    _recipeCache[recipeId] = recipe;
    return recipe;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final http.Response response = await _httpClient
          .get(
            uri,
            headers: _accountUser.trim().isNotEmpty
                ? <String, String>{'Edamam-Account-User': _accountUser}
                : null,
          )
          .timeout(_requestTimeout);

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is List<dynamic>) {
          return <String, dynamic>{'root': decoded};
        }
        throw const FormatException('Unexpected response format from server.');
      }

      final String message = decoded is Map<String, dynamic>
          ? (decoded['message']?.toString() ?? 'Unknown API error.')
          : 'Unknown API error.';
      throw Exception('Edamam API error (${response.statusCode}): $message');
    } on TimeoutException {
      throw const SocketException(
        'Request timed out. Please check your network connection.',
      );
    } on SocketException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw Exception('Failed to fetch recipe data: $error');
    }
  }

  void _ensureCredentials() {
    if (_appId.trim().isEmpty || _appKey.trim().isEmpty) {
      throw const FormatException(
        'Thieu thong tin Edamam. Hay them EDAMAM_APP_ID va EDAMAM_APP_KEY vao file .env.',
      );
    }
  }

  int _edamamIdFromUri(String recipeUri) {
    if (recipeUri.trim().isEmpty) {
      return 0;
    }
    int hash = 0x811C9DC5;
    for (final int unit in utf8.encode(recipeUri)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<List<Recipe>> _getRecipeSuggestionsByQuery({
    required String queryText,
    required List<String> pantryIngredients,
    String? cuisine,
    String? mealType,
    String? dishType,
    String? diet,
    String? health,
    int? maxReadyTime,
    int? maxCalories,
    int from = 0,
    int number = 12,
  }) async {
    final Map<String, String> query = <String, String>{
      'type': 'public',
      'q': queryText,
      'app_id': _appId,
      'app_key': _appKey,
      'random': 'false',
      'from': from.toString(),
      'to': (from + number).toString(),
    };

    if (cuisine != null && cuisine.isNotEmpty) {
      query['cuisineType'] = cuisine;
    }
    if (mealType != null && mealType.isNotEmpty) {
      query['mealType'] = mealType;
    }
    if (dishType != null && dishType.isNotEmpty) {
      query['dishType'] = dishType;
    }
    if (diet != null && diet.isNotEmpty) {
      query['diet'] = diet;
    }
    if (health != null && health.isNotEmpty) {
      query['health'] = health;
    }
    if (maxReadyTime != null && maxReadyTime > 0) {
      query['time'] = '1-$maxReadyTime';
    }
    if (maxCalories != null && maxCalories > 0) {
      query['calories'] = '1-$maxCalories';
    }

    final Uri uri = Uri.https(_baseHost, '/api/recipes/v2', query);
    final Map<String, dynamic> payload = await _getJson(uri);

    final List<dynamic> hits =
        payload['hits'] as List<dynamic>? ?? const <dynamic>[];
    final List<Recipe> recipes = <Recipe>[];

    for (final dynamic hit in hits) {
      if (hit is! Map<String, dynamic>) {
        continue;
      }
      final Map<String, dynamic>? recipeJson =
          hit['recipe'] as Map<String, dynamic>?;
      if (recipeJson == null) {
        continue;
      }

      final String recipeUri = (recipeJson['uri'] ?? '').toString();
      final int id = _edamamIdFromUri(recipeUri);
      if (id <= 0) {
        continue;
      }

      final Recipe recipe = Recipe.fromEdamamJson(
        recipeJson,
        id: id,
        pantryIngredients: pantryIngredients,
      );
      _idToUri[id] = recipeUri;
      _recipeCache[id] = recipe;
      recipes.add(recipe);
    }

    return recipes;
  }
}

class RecipeSuggestionPage {
  const RecipeSuggestionPage({
    required this.recipes,
    required this.queryIngredients,
    required this.priorityRecipeIds,
    required this.hasNext,
  });

  final List<Recipe> recipes;
  final List<String> queryIngredients;
  final List<int> priorityRecipeIds;
  final bool hasNext;
}
