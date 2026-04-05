import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'route_names.dart';
import '../core/services/scanner/scanner_service.dart';
import '../features/pantry/views/pantry_screen.dart' as pantry_view;
import '../features/pantry/views/receipt_scanner_screen.dart' as pantry_receipt;
import '../features/pantry/view_models/pantry_view_model.dart';
import '../features/recipes/views/recipe_list_screen.dart';
import '../features/recipes/views/recipe_detail_screen.dart';

import '../features/meal_planner/views/calendar_screen.dart';
import '../features/shopping_list/views/shopping_list_screen.dart';

class MealDetailsScreen extends StatelessWidget {
  final String mealId;
  const MealDetailsScreen({required this.mealId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bữa ăn')),
      body: Center(child: Text('Chi tiết bữa ăn - Mã ID: $mealId')),
    );
  }
}

class AddItemScreen extends StatelessWidget {
  final String? ingredient;
  const AddItemScreen({this.ingredient, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm hàng')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Màn hình thêm hàng'),
            if (ingredient != null) Text('Nguyên liệu: $ingredient'),
          ],
        ),
      ),
    );
  }
}

class ReceiptScannerPlaceholderScreen extends StatelessWidget {
  const ReceiptScannerPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét hoá đơn')),
      body: const Center(child: Text('Màn hình quét hoá đơn')),
    );
  }
}

class ShoppingItemDetailsScreen extends StatelessWidget {
  final String itemId;
  const ShoppingItemDetailsScreen({required this.itemId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết mục mua sắm')),
      body: Center(child: Text('Chi tiết mục - Mã ID: $itemId')),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tủ lạnh Đến Bàn Ăn')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Lên menu'),
              onTap: () => context.go(RouteNames.mealPlanner),
            ),
            ListTile(
              title: const Text('Tủ bếp'),
              onTap: () => context.go(RouteNames.pantryScreen),
            ),
            ListTile(
              title: const Text('Công thức'),
              onTap: () => context.go(RouteNames.recipesListScreen),
            ),
            ListTile(
              title: const Text('Danh sách mua'),
              onTap: () => context.go(RouteNames.shoppingListScreen),
            ),
          ],
        ),
      ),
    );
  }
}

/// GoRouter configuration with deep linking support
final appRouter = GoRouter(
  initialLocation: RouteNames.pantryScreen,
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Lỗi')),
    body: Center(child: Text('Lỗi: ${state.error}')),
  ),
  routes: [
    // Root/Home
    GoRoute(
      path: RouteNames.root,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
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
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => PantryViewModel(),
        child: const pantry_view.PantryScreen(),
      ),
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
          builder: (context, state) => Provider<ScannerService>(
            create: (_) => ScannerService(),
            child: const pantry_receipt.ReceiptScannerScreen(),
          ),
        ),
      ],
    ),

    // Recipes Routes
    GoRoute(
      path: RouteNames.recipesListScreen,
      name: 'recipesList',
      builder: (context, state) => const RecipeListScreen(),
      routes: [
        GoRoute(
          path: 'details/:recipeId',
          name: 'recipeDetails',
          builder: (context, state) {
            final String recipeIdParam = state.pathParameters['recipeId'] ?? '';
            final int? recipeId = int.tryParse(recipeIdParam);

            if (recipeId == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid recipe id.')),
              );
            }

            return RecipeDetailScreen(recipeId: recipeId);
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
