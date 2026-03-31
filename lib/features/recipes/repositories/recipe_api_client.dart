import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:http/http.dart' as http;

class RecipeApiClient {
  RecipeApiClient({http.Client? httpClient, String? apiKey})
    : _httpClient = httpClient ?? http.Client(),
      _apiKey = (apiKey != null && apiKey.trim().isNotEmpty)
          ? apiKey
          : dotenv.env['SPOONACULAR_API_KEY'] ??
                const String.fromEnvironment('SPOONACULAR_API_KEY');

  static const String _baseHost = 'api.spoonacular.com';
  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client _httpClient;
  final String _apiKey;

  Future<List<Recipe>> getRecipeSuggestions({
    required List<String> pantryIngredients,
    String? diet,
    String? cuisine,
    int? maxReadyTime,
    int number = 12,
  }) async {
    _ensureApiKey();

    final Map<String, String> query = <String, String>{
      'apiKey': _apiKey,
      'number': number.toString(),
      'sort': 'max-used-ingredients',
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
    };

    if (pantryIngredients.isNotEmpty) {
      query['includeIngredients'] = pantryIngredients.join(',');
    }
    if (diet != null && diet.isNotEmpty) {
      query['diet'] = diet;
    }
    if (cuisine != null && cuisine.isNotEmpty) {
      query['cuisine'] = cuisine;
    }
    if (maxReadyTime != null && maxReadyTime > 0) {
      query['maxReadyTime'] = maxReadyTime.toString();
    }

    final Uri uri = Uri.https(_baseHost, '/recipes/complexSearch', query);
    final Map<String, dynamic> payload = await _getJson(uri);

    final List<dynamic> results =
        payload['results'] as List<dynamic>? ?? const <dynamic>[];
    return results
        .whereType<Map<String, dynamic>>()
        .map(Recipe.fromSearchJson)
        .toList();
  }

  Future<Recipe> getRecipeDetail(int recipeId) async {
    _ensureApiKey();

    final Uri uri = Uri.https(
      _baseHost,
      '/recipes/$recipeId/information',
      <String, String>{'apiKey': _apiKey, 'includeNutrition': 'false'},
    );

    final Map<String, dynamic> payload = await _getJson(uri);
    return Recipe.fromDetailJson(payload);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final http.Response response = await _httpClient
          .get(uri)
          .timeout(_requestTimeout);

      final dynamic decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw const FormatException('Unexpected response format from server.');
      }

      final String message = decoded is Map<String, dynamic>
          ? (decoded['message']?.toString() ?? 'Unknown API error.')
          : 'Unknown API error.';
      throw Exception(
        'Spoonacular API error (${response.statusCode}): $message',
      );
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

  void _ensureApiKey() {
    if (_apiKey.trim().isEmpty) {
      throw const FormatException(
        'Thiếu Spoonacular API key. Hãy thêm SPOONACULAR_API_KEY vào file .env hoặc chạy với --dart-define=SPOONACULAR_API_KEY=YOUR_KEY.',
      );
    }
  }
}
