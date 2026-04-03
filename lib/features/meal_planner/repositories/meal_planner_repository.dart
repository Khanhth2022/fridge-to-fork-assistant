import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/meal_plan_model.dart';
import '../../shopping_list/models/shopping_item_model.dart';

class MealPlannerRepository {
  static const String mealPlanBoxName = 'meal_plans_box';
  static const String shoppingListBoxName = 'shopping_lists_box';
  static const String mealPlanMetaBoxName = 'meal_plans_meta';
  static const String shoppingListMetaBoxName = 'shopping_lists_meta';

  Future<Box<String>> _openMealPlanBox() async {
    return Hive.openBox<String>(mealPlanBoxName);
  }

  Future<Box<String>> _openShoppingListBox() async {
    return Hive.openBox<String>(shoppingListBoxName);
  }

  Future<Box<int>> _openMealPlanMetaBox() async {
    return Hive.openBox<int>(mealPlanMetaBoxName);
  }

  Future<Box<int>> _openShoppingListMetaBox() async {
    return Hive.openBox<int>(shoppingListMetaBoxName);
  }

  Future<List<PlannedRecipe>> getPlannedRecipes(DateTime date) async {
    final Box<String> box = await _openMealPlanBox();
    final String? raw = box.get(_dateKey(date));
    if (raw == null || raw.isEmpty) {
      return <PlannedRecipe>[];
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <PlannedRecipe>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PlannedRecipe.fromJson)
        .toList();
  }

  Future<void> savePlannedRecipes(
    DateTime date,
    List<PlannedRecipe> recipes,
  ) async {
    final Box<String> box = await _openMealPlanBox();
    final Box<int> metaBox = await _openMealPlanMetaBox();
    final String key = _dateKey(date);
    if (recipes.isEmpty) {
      await box.delete(key);
      await metaBox.delete(key);
      return;
    }

    await box.put(
      key,
      jsonEncode(
        recipes.map((PlannedRecipe recipe) => recipe.toJson()).toList(),
      ),
    );
    await metaBox.put(key, DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  Future<List<ShoppingItemModel>> getShoppingItems(DateTime date) async {
    final Box<String> box = await _openShoppingListBox();
    final String? raw = box.get(_dateKey(date));
    if (raw == null || raw.isEmpty) {
      return <ShoppingItemModel>[];
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <ShoppingItemModel>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ShoppingItemModel.fromJson)
        .toList();
  }

  Future<void> saveShoppingItems(
    DateTime date,
    List<ShoppingItemModel> items,
  ) async {
    final Box<String> box = await _openShoppingListBox();
    final Box<int> metaBox = await _openShoppingListMetaBox();
    final String key = _dateKey(date);
    if (items.isEmpty) {
      await box.delete(key);
      await metaBox.delete(key);
      return;
    }

    await box.put(
      key,
      jsonEncode(items.map((ShoppingItemModel item) => item.toJson()).toList()),
    );
    await metaBox.put(key, DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  static String _dateKey(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}
