import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Deep link handler for intelligent routing based on notification payload
class DeepLinkHandler {
  /// Parse notification payload and return appropriate route
  ///
  /// Payload formats:
  /// - "route:pantry" -> Navigate to pantry screen
  /// - "route:pantry?ingredient=milk" -> Navigate to add item with ingredient parameter
  /// - "route:shopping-list" -> Navigate to shopping list
  /// - "route:recipes" -> Navigate to recipes
  /// - "screen:recipe:123" -> Navigate to recipe details with ID 123
  /// - "alert:expiring:milk" -> Navigate to pantry with highlight expired item
  static String? parsePayloadToRoute(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final uri = Uri.tryParse(payload);
      if (uri == null) return null;

      // Handle route: scheme
      if (uri.scheme == 'route') {
        return _handleRouteScheme(uri);
      }

      // Handle screen: scheme
      if (uri.scheme == 'screen') {
        return _handleScreenScheme(uri);
      }

      // Handle alert: scheme
      if (uri.scheme == 'alert') {
        return _handleAlertScheme(uri);
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing deep link payload: $e');
      return null;
    }
  }

  /// Handle route:// scheme
  /// Examples: route:pantry, route:shopping-list?ingredient=milk
  static String? _handleRouteScheme(Uri uri) {
    final host = uri.host;

    switch (host) {
      case 'pantry':
        final ingredient = uri.queryParameters['ingredient'];
        if (ingredient != null) {
          return '/pantry/pantry-screen/add-item?ingredient=$ingredient';
        }
        return '/pantry/pantry-screen';

      case 'shopping-list':
        return '/shopping-list/list';

      case 'recipes':
        return '/recipes/list';

      case 'meal-planner':
        return '/meal-planner';

      default:
        return null;
    }
  }

  /// Handle screen://type/id scheme
  /// Examples: screen:recipe:123, screen:meal:456
  static String? _handleScreenScheme(Uri uri) {
    final path = uri.path.split('/');
    if (path.length < 2) return null;

    final screenType = path[0];
    final itemId = path[1];

    switch (screenType) {
      case 'recipe':
        return '/recipes/list/details/$itemId';

      case 'meal':
        return '/meal-planner/meal-details/$itemId';

      case 'shopping-item':
        return '/shopping-list/list/item-details/$itemId';

      default:
        return null;
    }
  }

  /// Handle alert:// scheme for expiring items
  /// Examples: alert:expiring:milk, alert:expired:cheese
  static String? _handleAlertScheme(Uri uri) {
    final alertType = uri.host; // "expiring" or "expired"
    final itemName = uri.path.replaceFirst('/', '');

    // Navigate to pantry screen with extra info
    return '/pantry/pantry-screen?alertType=$alertType&item=$itemName';
  }

  /// Build navigation payload for different scenarios
  static String buildPantryPayload({String? ingredient}) {
    if (ingredient != null) {
      return 'route:pantry?ingredient=$ingredient';
    }
    return 'route:pantry';
  }

  static String buildRecipePayload({required String recipeId}) {
    return 'screen:recipe:$recipeId';
  }

  static String buildMealPayload({required String mealId}) {
    return 'screen:meal:$mealId';
  }

  static String buildExpiringItemPayload({
    required String itemName,
    bool isExpired = false,
  }) {
    final alertType = isExpired ? 'expired' : 'expiring';
    return 'alert:$alertType:$itemName';
  }

  static String buildShoppingListPayload() {
    return 'route:shopping-list';
  }
}

/// Extension on GoRouter for easier deep linking
extension DeepLinkNavigation on GoRouter {
  /// Navigate using deep link payload
  void goWithDeepLink(String? payload) {
    final route = DeepLinkHandler.parsePayloadToRoute(payload);
    if (route != null) {
      go(route);
    }
  }
}
