import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:http/http.dart' as http;

class RecipeApiClient {
	RecipeApiClient({http.Client? httpClient, String? apiKey})
			: _httpClient = httpClient ?? http.Client(),
				_apiKey = apiKey ?? const String.fromEnvironment('SPOONACULAR_API_KEY') {
		print('[RecipeApiClient] Initialized with API key: ${_apiKey.isEmpty ? "EMPTY" : "${_apiKey.substring(0, 5)}...${_apiKey.substring(_apiKey.length - 5)}"}');
	}

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
		print('[RecipeApiClient.getRecipeSuggestions] Called with ingredients: $pantryIngredients, diet: $diet, cuisine: $cuisine, maxReadyTime: $maxReadyTime');
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
		print('[RecipeApiClient] Calling API: $uri');
		final Map<String, dynamic> payload = await _getJson(uri);
		print('[RecipeApiClient] API response received, results count: ${payload["results"] != null ? (payload["results"] as List).length : 0}');

		final List<dynamic> results = payload['results'] as List<dynamic>? ?? const <dynamic>[];
		return results
				.whereType<Map<String, dynamic>>()
				.map(Recipe.fromSearchJson)
				.toList();
	}

	Future<Recipe> getRecipeDetail(int recipeId) async {
		_ensureApiKey();

		final Uri uri = Uri.https(_baseHost, '/recipes/$recipeId/information', <String, String>{
			'apiKey': _apiKey,
			'includeNutrition': 'false',
		});

		final Map<String, dynamic> payload = await _getJson(uri);
		return Recipe.fromDetailJson(payload);
	}

	Future<Map<String, dynamic>> _getJson(Uri uri) async {
		try {
			final http.Response response =
					await _httpClient.get(uri).timeout(_requestTimeout);

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
			throw Exception('Spoonacular API error (${response.statusCode}): $message');
		} on TimeoutException {
			throw const SocketException('Request timed out. Please check your network connection.');
		} on SocketException {
			rethrow;
		} on FormatException {
			rethrow;
		} catch (error) {
			throw Exception('Failed to fetch recipe data: $error');
		}
	}

	void _ensureApiKey() {
		print('[RecipeApiClient._ensureApiKey] API key is ${_apiKey.trim().isEmpty ? "EMPTY" : "present"}');
		if (_apiKey.trim().isEmpty) {
			throw const FormatException(
				'Missing Spoonacular API key. Run app with --dart-define=SPOONACULAR_API_KEY=YOUR_KEY.',
			);
		}
	}
}
