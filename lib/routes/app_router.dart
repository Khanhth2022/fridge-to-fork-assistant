import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../core/widgets/notification_test_screen.dart';

// Placeholder Screens (các thành viên khác sẽ thay thế)
class MealPlannerScreen extends StatelessWidget {
  final String? mealId;
  const MealPlannerScreen({this.mealId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Planner')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Meal Planner Screen'),
            if (mealId != null) Text('Meal ID: $mealId'),
          ],
        ),
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(child: Text('Calendar Screen')),
    );
  }
}

class MealDetailsScreen extends StatelessWidget {
  final String mealId;
  const MealDetailsScreen({required this.mealId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Details')),
      body: Center(child: Text('Meal Details - ID: $mealId')),
    );
  }
}

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantry')),
      body: const Center(child: Text('Pantry Screen')),
    );
  }
}

class AddItemScreen extends StatelessWidget {
  final String? ingredient;
  const AddItemScreen({this.ingredient, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Add Item Screen'),
            if (ingredient != null) Text('Ingredient: $ingredient'),
          ],
        ),
      ),
    );
  }
}

class ReceiptScannerScreen extends StatelessWidget {
  const ReceiptScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Scanner')),
      body: const Center(child: Text('Receipt Scanner Screen')),
    );
  }
}

class RecipesListScreen extends StatelessWidget {
  const RecipesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: const Center(child: Text('Recipes List Screen')),
    );
  }
}

class RecipeDetailsScreen extends StatelessWidget {
  final String recipeId;
  const RecipeDetailsScreen({required this.recipeId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: Center(child: Text('Recipe Details - ID: $recipeId')),
    );
  }
}

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: const Center(child: Text('Shopping List Screen')),
    );
  }
}

class ShoppingItemDetailsScreen extends StatelessWidget {
  final String itemId;
  const ShoppingItemDetailsScreen({required this.itemId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Item Details')),
      body: Center(child: Text('Shopping Item Details - ID: $itemId')),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fridge to Fork')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Meal Planner'),
              onTap: () => context.go(RouteNames.mealPlanner),
            ),
            ListTile(
              title: const Text('Pantry'),
              onTap: () => context.go(RouteNames.pantryScreen),
            ),
            ListTile(
              title: const Text('Recipes'),
              onTap: () => context.go(RouteNames.recipesListScreen),
            ),
            ListTile(
              title: const Text('Shopping List'),
              onTap: () => context.go(RouteNames.shoppingListScreen),
            ),
            const Divider(),
            ListTile(
              title: const Text('🧪 Test Notifications'),
              onTap: () => context.go('/test-notifications'),
            ),
          ],
        ),
      ),
    );
  }
}

/// GoRouter configuration with deep linking support
final appRouter = GoRouter(
  initialLocation: RouteNames.root,
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Error: ${state.error}')),
  ),
  routes: [
    // Root/Home
    GoRoute(
      path: RouteNames.root,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Test Notifications Route (Development)
    GoRoute(
      path: '/test-notifications',
      name: 'testNotifications',
      builder: (context, state) => const NotificationTestScreen(),
    ),

    // Meal Planner Routes
    GoRoute(
      path: RouteNames.mealPlanner,
      name: 'mealPlanner',
      builder: (context, state) => const MealPlannerScreen(),
      routes: [
        GoRoute(
          path: 'calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: 'meal-details/:mealId',
          name: 'mealDetails',
          builder: (context, state) {
            final mealId = state.pathParameters['mealId'] ?? '';
            return MealDetailsScreen(mealId: mealId);
          },
        ),
      ],
    ),

    // Pantry Routes
    GoRoute(
      path: RouteNames.pantryScreen,
      name: 'pantryScreen',
      builder: (context, state) => const PantryScreen(),
      routes: [
        GoRoute(
          path: 'add-item',
          name: 'addItem',
          builder: (context, state) {
            final ingredient = state.uri.queryParameters['ingredient'];
            return AddItemScreen(ingredient: ingredient);
          },
        ),
        GoRoute(
          path: 'receipt-scanner',
          name: 'receiptScanner',
          builder: (context, state) => const ReceiptScannerScreen(),
        ),
      ],
    ),

    // Recipes Routes
    GoRoute(
      path: RouteNames.recipesListScreen,
      name: 'recipesList',
      builder: (context, state) => const RecipesListScreen(),
      routes: [
        GoRoute(
          path: 'details/:recipeId',
          name: 'recipeDetails',
          builder: (context, state) {
            final recipeId = state.pathParameters['recipeId'] ?? '';
            return RecipeDetailsScreen(recipeId: recipeId);
          },
        ),
      ],
    ),

    // Shopping List Routes
    GoRoute(
      path: RouteNames.shoppingListScreen,
      name: 'shoppingList',
      builder: (context, state) => const ShoppingListScreen(),
      routes: [
        GoRoute(
          path: 'item-details/:itemId',
          name: 'shoppingItemDetails',
          builder: (context, state) {
            final itemId = state.pathParameters['itemId'] ?? '';
            return ShoppingItemDetailsScreen(itemId: itemId);
          },
        ),
      ],
    ),
  ],
);
