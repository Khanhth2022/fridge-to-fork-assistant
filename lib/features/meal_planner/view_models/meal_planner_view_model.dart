import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../recipes/models/recipe_model.dart';
import '../../shopping_list/models/shopping_item_model.dart';
import '../../pantry/models/pantry_item_model.dart';
import '../../pantry/pantry_repository.dart';
import '../models/meal_plan_model.dart';
import '../repositories/meal_planner_repository.dart';

class MealPlannerViewModel extends ChangeNotifier {
  MealPlannerViewModel({MealPlannerRepository? repository})
    : _repository = repository ?? MealPlannerRepository() {
    _attachPantryListener();
    unawaited(_loadInitialData());
  }

  final MealPlannerRepository _repository;
  final PantryRepository _pantryRepository = PantryRepository();
  late final Box<PantryItemModel> _pantryBox;
  late final ValueListenable<Box<PantryItemModel>> _pantryListenable;
  String _lastPantryKey = '';

  DateTime _visibleWeekStart = _normalizeDate(DateTime.now());
  DateTime _selectedDate = _normalizeDate(DateTime.now());
  bool _isLoading = false;

  final Map<String, List<PlannedRecipe>> _plannedRecipesByDate =
      <String, List<PlannedRecipe>>{};
  final Map<String, List<ShoppingItemModel>> _shoppingItemsByDate =
      <String, List<ShoppingItemModel>>{};

  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  DateTime get visibleWeekStart => _visibleWeekStart;

  List<DateTime> get visibleWeekDates =>
      List<DateTime>.generate(7, (int index) {
        return _visibleWeekStart.add(Duration(days: index));
      });

  List<PlannedRecipe> get selectedDayRecipes => _recipesForDate(_selectedDate);

  List<ShoppingItemModel> get selectedDayShoppingItems =>
      _shoppingForDate(_selectedDate);

  String get selectedDayLabel => _formatFullDate(_selectedDate);

  bool isVisibleWeekDate(DateTime date) {
    final DateTime normalized = _normalizeDate(date);
    return !normalized.isBefore(_visibleWeekStart) &&
        normalized.isBefore(_visibleWeekStart.add(const Duration(days: 7)));
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    await _reloadVisibleWeek();
    await refreshMissingIngredientsFromPantry();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _pantryListenable.removeListener(_handlePantryBoxChanged);
    super.dispose();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _reloadVisibleWeek();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = _normalizeDate(date);
    if (!isVisibleWeekDate(_selectedDate)) {
      _visibleWeekStart = _selectedDate;
      await _reloadVisibleWeek();
    }
    notifyListeners();
  }

  Future<void> showPreviousWeek() async {
    _visibleWeekStart = _visibleWeekStart.subtract(const Duration(days: 7));
    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    await _reloadVisibleWeek();
    notifyListeners();
  }

  Future<void> showNextWeek() async {
    _visibleWeekStart = _visibleWeekStart.add(const Duration(days: 7));
    _selectedDate = _selectedDate.add(const Duration(days: 7));
    await _reloadVisibleWeek();
    notifyListeners();
  }

  Future<bool> addRecipeToSelectedDate(
    Recipe recipe, {
    List<String> missingIngredients = const <String>[],
    bool addMissingToShopping = true,
  }) {
    return addRecipeToDate(
      _selectedDate,
      recipe,
      missingIngredients: missingIngredients,
      addMissingToShopping: addMissingToShopping,
    );
  }

  Future<bool> addRecipeToDate(
    DateTime date,
    Recipe recipe, {
    List<String> missingIngredients = const <String>[],
    bool addMissingToShopping = true,
  }) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<PlannedRecipe> recipes = List<PlannedRecipe>.from(
      _recipesForDate(normalizedDate),
    );

    if (recipes.any((PlannedRecipe item) => item.recipeId == recipe.id)) {
      return false;
    }

    final List<ShoppingIngredientSnapshot> shoppingIngredients =
        _buildShoppingIngredientSnapshots(recipe, missingIngredients);
    final List<ShoppingIngredientSnapshot> allIngredients =
        _buildAllIngredientSnapshots(recipe);

    recipes.add(
      PlannedRecipe.fromRecipe(
        recipe,
        allIngredients: allIngredients,
        shoppingIngredients: shoppingIngredients,
      ),
    );

    _plannedRecipesByDate[_dateKey(normalizedDate)] = recipes;
    await _repository.savePlannedRecipes(normalizedDate, recipes);

    if (addMissingToShopping && shoppingIngredients.isNotEmpty) {
      await _addShoppingItemsForRecipe(
        normalizedDate,
        recipe.id.toString(),
        shoppingIngredients,
      );
    }

    notifyListeners();
    return true;
  }

  Future<bool> addCustomRecipeToSelectedDate({
    required String title,
    required List<String> ingredientNames,
    required List<String> pantryIngredients,
  }) {
    return addCustomRecipeToDate(
      _selectedDate,
      title: title,
      ingredientNames: ingredientNames,
      pantryIngredients: pantryIngredients,
    );
  }

  Future<bool> addCustomRecipeToDate(
    DateTime date, {
    required String title,
    required List<String> ingredientNames,
    required List<String> pantryIngredients,
  }) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final String cleanedTitle = title.trim();
    if (cleanedTitle.isEmpty) {
      return false;
    }

    final List<PlannedRecipe> recipes = List<PlannedRecipe>.from(
      _recipesForDate(normalizedDate),
    );
    final String normalizedTitle = _normalizeText(cleanedTitle);
    if (recipes.any(
      (PlannedRecipe item) => _normalizeText(item.title) == normalizedTitle,
    )) {
      return false;
    }

    final Set<String> pantryIndex = pantryIngredients
        .map(_normalizeText)
        .where((String item) => item.isNotEmpty)
        .toSet();

    final List<ShoppingIngredientSnapshot> shoppingIngredients =
        <ShoppingIngredientSnapshot>[];
    final List<ShoppingIngredientSnapshot> allIngredients =
        <ShoppingIngredientSnapshot>[];
    for (final String ingredient in ingredientNames) {
      final String cleanedIngredient = ingredient.trim();
      if (cleanedIngredient.isEmpty) {
        continue;
      }

      allIngredients.add(
        ShoppingIngredientSnapshot(
          name: cleanedIngredient,
          quantity: 1,
          unit: '',
        ),
      );

      final String normalizedIngredient = _normalizeText(cleanedIngredient);
      final bool available = pantryIndex.any(
        (String pantryItem) =>
            pantryItem.contains(normalizedIngredient) ||
            normalizedIngredient.contains(pantryItem),
      );
      if (!available) {
        shoppingIngredients.add(
          ShoppingIngredientSnapshot(
            name: cleanedIngredient,
            quantity: 1,
            unit: '',
          ),
        );
      }
    }

    final int customRecipeId = -DateTime.now().microsecondsSinceEpoch;
    recipes.add(
      PlannedRecipe(
        recipeId: customRecipeId,
        title: cleanedTitle,
        imageUrl: '',
        addedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        summary: 'Món ăn tự thêm',
        allIngredients: allIngredients,
        shoppingIngredients: shoppingIngredients,
      ),
    );

    _plannedRecipesByDate[_dateKey(normalizedDate)] = recipes;
    await _repository.savePlannedRecipes(normalizedDate, recipes);

    if (shoppingIngredients.isNotEmpty) {
      await _addShoppingItemsForRecipe(
        normalizedDate,
        customRecipeId.toString(),
        shoppingIngredients,
      );
    }

    notifyListeners();
    return true;
  }

  Future<bool> removeRecipeFromSelectedDate(int recipeId) {
    return removeRecipeFromDate(_selectedDate, recipeId);
  }

  Future<bool> removeRecipeFromDate(DateTime date, int recipeId) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<PlannedRecipe> recipes = List<PlannedRecipe>.from(
      _recipesForDate(normalizedDate),
    );

    final int index = recipes.indexWhere(
      (PlannedRecipe item) => item.recipeId == recipeId,
    );
    if (index == -1) {
      return false;
    }

    final PlannedRecipe removedRecipe = recipes.removeAt(index);
    _plannedRecipesByDate[_dateKey(normalizedDate)] = recipes;
    await _repository.savePlannedRecipes(normalizedDate, recipes);

    await _removeShoppingItemsForRecipe(normalizedDate, removedRecipe);
    notifyListeners();
    return true;
  }

  Future<void> toggleShoppingItemChecked(DateTime date, String itemId) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(normalizedDate),
    );
    final int index = items.indexWhere(
      (ShoppingItemModel item) => item.itemId == itemId,
    );
    if (index == -1) {
      return;
    }

    items[index] = items[index].copyWith(checked: !items[index].checked);
    _shoppingItemsByDate[_dateKey(normalizedDate)] = items;
    await _repository.saveShoppingItems(normalizedDate, items);
    notifyListeners();
  }

  Future<bool> addShoppingItemToPantry(DateTime date, String itemId) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(normalizedDate),
    );
    final int index = items.indexWhere(
      (ShoppingItemModel item) => item.itemId == itemId,
    );
    if (index == -1) {
      return false;
    }

    final ShoppingItemModel shoppingItem = items[index];
    final String name = shoppingItem.name.trim();
    if (name.isEmpty) {
      await removeShoppingItem(normalizedDate, itemId);
      return false;
    }

    final double quantity = shoppingItem.quantity > 0
        ? shoppingItem.quantity
        : 1;
    final String unit = shoppingItem.unit.trim();
    final DateTime now = DateTime.now();
    final DateTime purchaseDate = DateTime(now.year, now.month, now.day);
    final DateTime expiryDate = purchaseDate.add(const Duration(days: 7));

    final List<PantryItemModel> pantryItems = await _pantryRepository
        .getAllItems();
    final String normalizedName = _normalizeText(name);
    final String normalizedUnit = _normalizeText(unit);
    final int existingIndex = pantryItems.indexWhere(
      (PantryItemModel item) =>
          _normalizeText(item.name) == normalizedName &&
          _normalizeText(item.unit) == normalizedUnit,
    );

    if (existingIndex != -1) {
      final PantryItemModel existing = pantryItems[existingIndex];
      await _pantryRepository.updateItem(
        existing.itemId,
        existing.copyWith(quantity: existing.quantity + quantity),
      );
    } else {
      await _pantryRepository.addItem(
        PantryItemModel(
          name: name,
          quantity: quantity,
          unit: unit,
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
        ),
      );
    }

    await removeShoppingItem(normalizedDate, itemId);
    await refreshMissingIngredientsFromPantry();
    return true;
  }

  Future<bool> addMissingIngredientsToShopping(
    DateTime date,
    PlannedRecipe recipe,
    List<ShoppingIngredientSnapshot> missing,
  ) async {
    if (missing.isEmpty) {
      return false;
    }

    final DateTime normalizedDate = _normalizeDate(date);
    await _addShoppingItemsForRecipe(
      normalizedDate,
      recipe.recipeId.toString(),
      missing,
    );
    notifyListeners();
    return true;
  }

  void _attachPantryListener() {
    _pantryBox = Hive.box<PantryItemModel>(PantryRepository.boxName);
    _pantryListenable = _pantryBox.listenable();
    _pantryListenable.addListener(_handlePantryBoxChanged);
  }

  void _handlePantryBoxChanged() {
    unawaited(refreshMissingIngredientsFromPantry());
  }

  Future<void> refreshMissingIngredientsFromPantry() async {
    if (_plannedRecipesByDate.isEmpty) {
      return;
    }

    final List<String> pantryNames = _pantryBox.values
        .where((PantryItemModel item) => item.deletedAtUtcMs == null)
        .map((PantryItemModel item) => item.name)
        .where((String name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

    final String pantryKey = _buildPantryKey(pantryNames);
    if (pantryKey == _lastPantryKey) {
      return;
    }
    _lastPantryKey = pantryKey;

    final Set<String> pantryIndex = pantryNames
        .map(_normalizeText)
        .where((String value) => value.isNotEmpty)
        .toSet();

    bool anyChanged = false;
    for (final DateTime date in visibleWeekDates) {
      final String key = _dateKey(date);
      final List<PlannedRecipe> recipes = List<PlannedRecipe>.from(
        _plannedRecipesByDate[key] ?? <PlannedRecipe>[],
      );
      bool dateChanged = false;

      for (int i = 0; i < recipes.length; i++) {
        final PlannedRecipe recipe = recipes[i];
        if (recipe.shoppingIngredients.isEmpty) {
          continue;
        }

        final List<ShoppingIngredientSnapshot> remaining = recipe
            .shoppingIngredients
            .where(
              (ShoppingIngredientSnapshot item) =>
                  !_isIngredientInPantry(item.name, pantryIndex),
            )
            .toList();

        if (remaining.length != recipe.shoppingIngredients.length) {
          recipes[i] = recipe.copyWith(shoppingIngredients: remaining);
          dateChanged = true;
        }
      }

      if (dateChanged) {
        _plannedRecipesByDate[key] = recipes;
        await _repository.savePlannedRecipes(date, recipes);
        anyChanged = true;
      }
    }

    if (anyChanged) {
      notifyListeners();
    }
  }

  Future<bool> addCustomShoppingItem(
    DateTime date, {
    required String name,
    double quantity = 1,
    String unit = '',
  }) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(normalizedDate),
    );

    final String normalizedName = _normalizeText(name);
    if (normalizedName.isEmpty) {
      return false;
    }

    final String itemKey = _shoppingKey(normalizedName, unit);
    final int index = items.indexWhere(
      (ShoppingItemModel item) => item.normalizedKey == itemKey,
    );

    if (index == -1) {
      items.add(
        ShoppingItemModel(
          itemId: itemKey,
          name: name.trim(),
          quantity: quantity,
          unit: unit.trim(),
          checked: false,
          sourceQuantities: <String, double>{},
        ),
      );
    } else {
      final ShoppingItemModel existing = items[index];
      items[index] = existing.copyWith(quantity: existing.quantity + quantity);
    }

    _shoppingItemsByDate[_dateKey(normalizedDate)] = items;
    await _repository.saveShoppingItems(normalizedDate, items);
    notifyListeners();
    return true;
  }

  Future<bool> completePlannedRecipe(
    DateTime date,
    PlannedRecipe recipe,
  ) async {
    final List<ShoppingIngredientSnapshot> ingredients = recipe.allIngredients;
    if (ingredients.isEmpty) {
      await _ensureRecipeRemoved(date, recipe);
      return false;
    }

    final List<PantryItemModel> pantryItems = await _pantryRepository
        .getAllItems();
    bool deductedAny = false;

    for (int i = 0; i < ingredients.length; i++) {
      final ShoppingIngredientSnapshot ingredient = ingredients[i];
      final String normalizedName = _normalizeText(ingredient.name);
      if (normalizedName.isEmpty) {
        continue;
      }

      final int index = pantryItems.indexWhere((PantryItemModel item) {
        return _normalizeText(item.name) == normalizedName &&
            _unitMatches(ingredient.unit, item.unit);
      });
      if (index == -1) {
        continue;
      }

      final PantryItemModel item = pantryItems[index];
      final double used = ingredient.quantity > 0 ? ingredient.quantity : 1;
      final double remaining = item.quantity - used;

      if (remaining <= 0) {
        await _pantryRepository.deleteItem(item.itemId);
        pantryItems.removeAt(index);
        deductedAny = true;
      } else {
        final PantryItemModel updated = item.copyWith(quantity: remaining);
        pantryItems[index] = updated;
        await _pantryRepository.updateItem(item.itemId, updated);
        deductedAny = true;
      }
    }

    await _ensureRecipeRemoved(date, recipe);
    return deductedAny;
  }

  Future<void> _ensureRecipeRemoved(DateTime date, PlannedRecipe recipe) async {
    final bool removed = await removeRecipeFromDate(date, recipe.recipeId);
    if (removed) {
      return;
    }

    final DateTime normalizedDate = _normalizeDate(date);
    final List<PlannedRecipe> recipes = List<PlannedRecipe>.from(
      _recipesForDate(normalizedDate),
    );
    final String normalizedTitle = _normalizeText(recipe.title);
    final int index = recipes.indexWhere(
      (PlannedRecipe item) => _normalizeText(item.title) == normalizedTitle,
    );
    if (index == -1) {
      return;
    }

    final PlannedRecipe removedRecipe = recipes.removeAt(index);
    _plannedRecipesByDate[_dateKey(normalizedDate)] = recipes;
    await _repository.savePlannedRecipes(normalizedDate, recipes);
    await _removeShoppingItemsForRecipe(normalizedDate, removedRecipe);
    notifyListeners();
  }

  Future<bool> removeShoppingItem(DateTime date, String itemId) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(normalizedDate),
    );
    final int index = items.indexWhere(
      (ShoppingItemModel item) => item.itemId == itemId,
    );
    if (index == -1) {
      return false;
    }

    items.removeAt(index);
    _shoppingItemsByDate[_dateKey(normalizedDate)] = items;
    await _repository.saveShoppingItems(normalizedDate, items);
    notifyListeners();
    return true;
  }

  Future<bool> updateShoppingItem(
    DateTime date,
    String itemId, {
    required String name,
    required double quantity,
    String unit = '',
  }) async {
    final DateTime normalizedDate = _normalizeDate(date);
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(normalizedDate),
    );

    final int index = items.indexWhere(
      (ShoppingItemModel item) => item.itemId == itemId,
    );
    if (index == -1) {
      return false;
    }

    final String cleanedName = name.trim();
    final String cleanedUnit = unit.trim();
    if (cleanedName.isEmpty || quantity <= 0) {
      return false;
    }

    final ShoppingItemModel current = items[index];
    final String nextKey = _shoppingKey(cleanedName, cleanedUnit);
    final ShoppingItemModel updated = current.copyWith(
      itemId: nextKey,
      name: cleanedName,
      quantity: quantity,
      unit: cleanedUnit,
    );

    final int duplicateIndex = items.indexWhere(
      (ShoppingItemModel item) =>
          item.itemId != current.itemId && item.normalizedKey == nextKey,
    );

    if (duplicateIndex != -1) {
      final ShoppingItemModel duplicate = items[duplicateIndex];
      final Map<String, double> mergedSources = Map<String, double>.from(
        duplicate.sourceQuantities,
      );
      updated.sourceQuantities.forEach((String key, double value) {
        mergedSources.update(
          key,
          (double existing) => existing + value,
          ifAbsent: () => value,
        );
      });

      items[duplicateIndex] = duplicate.copyWith(
        quantity: duplicate.quantity + updated.quantity,
        checked: duplicate.checked || updated.checked,
        sourceQuantities: mergedSources,
      );
      items.removeAt(index);
    } else {
      items[index] = updated;
    }

    _shoppingItemsByDate[_dateKey(normalizedDate)] = items;
    await _repository.saveShoppingItems(normalizedDate, items);
    notifyListeners();
    return true;
  }

  List<PlannedRecipe> _recipesForDate(DateTime date) {
    return _plannedRecipesByDate[_dateKey(date)] ?? <PlannedRecipe>[];
  }

  List<ShoppingItemModel> _shoppingForDate(DateTime date) {
    return _shoppingItemsByDate[_dateKey(date)] ?? <ShoppingItemModel>[];
  }

  Future<void> _reloadVisibleWeek() async {
    for (final DateTime date in visibleWeekDates) {
      final String key = _dateKey(date);
      _plannedRecipesByDate[key] = await _repository.getPlannedRecipes(date);
      _shoppingItemsByDate[key] = await _repository.getShoppingItems(date);
    }
  }

  Future<void> _addShoppingItemsForRecipe(
    DateTime date,
    String sourceKey,
    List<ShoppingIngredientSnapshot> shoppingIngredients,
  ) async {
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(date),
    );

    for (final ShoppingIngredientSnapshot ingredient in shoppingIngredients) {
      final String normalizedKey = _shoppingKey(
        ingredient.name,
        ingredient.unit,
      );
      final int index = items.indexWhere(
        (ShoppingItemModel item) => item.normalizedKey == normalizedKey,
      );

      if (index == -1) {
        items.add(
          ShoppingItemModel(
            itemId: normalizedKey,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            checked: false,
            sourceQuantities: <String, double>{sourceKey: ingredient.quantity},
          ),
        );
      } else {
        final ShoppingItemModel existing = items[index];
        final Map<String, double> sources = Map<String, double>.from(
          existing.sourceQuantities,
        );
        sources.update(
          sourceKey,
          (double current) => current + ingredient.quantity,
          ifAbsent: () => ingredient.quantity,
        );
        items[index] = existing.copyWith(
          quantity: existing.quantity + ingredient.quantity,
          sourceQuantities: sources,
        );
      }
    }

    _shoppingItemsByDate[_dateKey(date)] = items;
    await _repository.saveShoppingItems(date, items);
  }

  Future<void> _removeShoppingItemsForRecipe(
    DateTime date,
    PlannedRecipe recipe,
  ) async {
    final List<ShoppingItemModel> items = List<ShoppingItemModel>.from(
      _shoppingForDate(date),
    );
    bool changed = false;

    for (final ShoppingIngredientSnapshot ingredient
        in recipe.shoppingIngredients) {
      final String normalizedKey = _shoppingKey(
        ingredient.name,
        ingredient.unit,
      );
      final int index = items.indexWhere(
        (ShoppingItemModel item) => item.normalizedKey == normalizedKey,
      );
      if (index == -1) {
        continue;
      }

      final ShoppingItemModel existing = items[index];
      final Map<String, double> sources = Map<String, double>.from(
        existing.sourceQuantities,
      );
      final String recipeKey = recipe.recipeId.toString();
      final double contributed = sources[recipeKey] ?? 0;
      if (contributed <= 0) {
        continue;
      }

      sources.remove(recipeKey);
      final double nextQuantity = (existing.quantity - contributed)
          .clamp(0, double.infinity)
          .toDouble();
      changed = true;

      if (sources.isEmpty || nextQuantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = existing.copyWith(
          quantity: nextQuantity,
          sourceQuantities: sources,
        );
      }
    }

    if (changed) {
      _shoppingItemsByDate[_dateKey(date)] = items;
      await _repository.saveShoppingItems(date, items);
    }
  }

  List<ShoppingIngredientSnapshot> _buildShoppingIngredientSnapshots(
    Recipe recipe,
    List<String> missingIngredients,
  ) {
    if (missingIngredients.isEmpty) {
      return <ShoppingIngredientSnapshot>[];
    }

    final List<ShoppingIngredientSnapshot> snapshots =
        <ShoppingIngredientSnapshot>[];
    for (final String missing in missingIngredients) {
      final RecipeIngredient? matched = _matchIngredient(recipe, missing);
      final String name = matched?.name.trim().isNotEmpty == true
          ? matched!.name.trim()
          : missing.trim();
      final double quantity = _toQuantity(matched?.amount) ?? 1;
      final String unit = matched?.unit?.trim() ?? '';
      snapshots.add(
        ShoppingIngredientSnapshot(name: name, quantity: quantity, unit: unit),
      );
    }

    return snapshots;
  }

  RecipeIngredient? _matchIngredient(Recipe recipe, String missingIngredient) {
    final String normalizedMissing = _normalizeText(missingIngredient);
    for (final RecipeIngredient ingredient in recipe.ingredients) {
      final String normalizedName = _normalizeText(ingredient.name);
      final String normalizedOriginal = _normalizeText(ingredient.original);
      if (normalizedName.contains(normalizedMissing) ||
          normalizedMissing.contains(normalizedName) ||
          normalizedOriginal.contains(normalizedMissing) ||
          normalizedMissing.contains(normalizedOriginal)) {
        return ingredient;
      }
    }
    return null;
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateKey(DateTime date) {
    final DateTime normalized = _normalizeDate(date);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }

  static String _shoppingKey(String name, String unit) {
    return '${_normalizeText(name)}|${_normalizeText(unit)}';
  }

  static String _buildPantryKey(List<String> ingredients) {
    final List<String> normalized =
        ingredients
            .map(_normalizeText)
            .where((String value) => value.isNotEmpty)
            .toList()
          ..sort();
    return normalized.join('|');
  }

  static bool _isIngredientInPantry(
    String ingredient,
    Set<String> pantryIndex,
  ) {
    final String normalizedIngredient = _normalizeText(ingredient);
    for (final String pantryItem in pantryIndex) {
      if (normalizedIngredient.contains(pantryItem) ||
          pantryItem.contains(normalizedIngredient)) {
        return true;
      }
    }
    return false;
  }

  static String _normalizeText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static double? _toQuantity(num? value) {
    if (value == null) {
      return null;
    }
    return value.toDouble();
  }

  static bool _unitMatches(String candidate, String current) {
    final String left = _normalizeText(candidate);
    final String right = _normalizeText(current);
    if (left.isEmpty || right.isEmpty) {
      return true;
    }
    return left == right;
  }

  List<ShoppingIngredientSnapshot> _buildAllIngredientSnapshots(Recipe recipe) {
    final List<ShoppingIngredientSnapshot> snapshots =
        <ShoppingIngredientSnapshot>[];

    for (final RecipeIngredient ingredient in recipe.ingredients) {
      final String name = ingredient.name.trim().isNotEmpty
          ? ingredient.name
          : ingredient.original.trim();
      if (name.isEmpty) {
        continue;
      }

      snapshots.add(
        ShoppingIngredientSnapshot(
          name: name,
          quantity: _toQuantity(ingredient.amount) ?? 1,
          unit: ingredient.unit?.trim() ?? '',
        ),
      );
    }

    if (snapshots.isNotEmpty) {
      return snapshots;
    }

    for (final String ingredient in recipe.usedIngredients) {
      final String name = ingredient.trim();
      if (name.isEmpty) {
        continue;
      }
      snapshots.add(
        ShoppingIngredientSnapshot(name: name, quantity: 1, unit: ''),
      );
    }

    for (final String ingredient in recipe.missedIngredients) {
      final String name = ingredient.trim();
      if (name.isEmpty) {
        continue;
      }
      snapshots.add(
        ShoppingIngredientSnapshot(name: name, quantity: 1, unit: ''),
      );
    }

    return snapshots;
  }

  static String _formatFullDate(DateTime date) {
    const List<String> weekdays = <String>[
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];

    final String weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
