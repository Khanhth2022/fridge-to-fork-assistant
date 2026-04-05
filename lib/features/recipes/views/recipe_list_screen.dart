import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fridge_to_fork_assistant/core/config/api_config.dart';
import 'package:fridge_to_fork_assistant/features/meal_planner/view_models/meal_planner_view_model.dart';
import 'package:fridge_to_fork_assistant/features/meal_planner/widgets/planner_footer.dart';
import 'package:fridge_to_fork_assistant/features/pantry/models/pantry_item_model.dart';
import 'package:fridge_to_fork_assistant/features/pantry/pantry_repository.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';
import 'package:fridge_to_fork_assistant/features/recipes/view_models/recipe_view_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/views/recipe_detail_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({
    super.key,
    this.pantryIngredients,
    this.isPantrySuggestionWindow = false,
  });

  final List<String>? pantryIngredients;
  final bool isPantrySuggestionWindow;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late final RecipeViewModel _viewModel;
  late final Box<PantryItemModel> _pantryBox;
  late final ValueListenable<Box<PantryItemModel>> _pantryListenable;
  bool _followPantry = true;
  String _lastPantryKey = '';
  bool _hasPantrySyncedOnce = false;
  List<String> _pantryIngredients = <String>[];
  Set<String> _selectedIngredientKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _viewModel = RecipeViewModel(
      apiClient: RecipeApiClient(
        appId: ApiConfig.edamamAppId,
        appKey: ApiConfig.edamamAppKey,
      ),
    );
    _attachPantryListener();

    final List<String> seedIngredients =
        widget.pantryIngredients ?? const <String>[];
    if (seedIngredients.isNotEmpty) {
      _viewModel.updateReferencePantryIngredients(seedIngredients);
      _pantryIngredients = List<String>.from(seedIngredients)..sort();
      _selectedIngredientKeys = <String>{};
      _applySelectionAndFetch();
    } else {
      _syncPantryIngredientsFromBox();
    }
  }

  void _attachPantryListener() {
    _pantryBox = Hive.box<PantryItemModel>(PantryRepository.boxName);
    _pantryListenable = _pantryBox.listenable();
    _pantryListenable.addListener(_handlePantryBoxChanged);
  }

  void _handlePantryBoxChanged() {
    _syncPantryIngredientsFromBox();
  }

  void _syncPantryIngredientsFromBox({bool forceFetch = false}) {
    final List<String> pantryNames =
        _pantryBox.values
            .where((PantryItemModel item) => item.deletedAtUtcMs == null)
            .map((PantryItemModel item) => item.name.trim())
            .where((String name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final String pantryKey = _buildIngredientKey(pantryNames);
    if (_hasPantrySyncedOnce && pantryKey == _lastPantryKey) {
      return;
    }
    _hasPantrySyncedOnce = true;
    _lastPantryKey = pantryKey;

    _viewModel.updateReferencePantryIngredients(pantryNames);

    final Set<String> normalizedPantry = pantryNames
        .map(_normalizeIngredient)
        .where((String value) => value.isNotEmpty)
        .toSet();

    if (mounted) {
      setState(() {
        _pantryIngredients = pantryNames;
        _selectedIngredientKeys = _selectedIngredientKeys.intersection(
          normalizedPantry,
        );
      });
    } else {
      _pantryIngredients = pantryNames;
      _selectedIngredientKeys = _selectedIngredientKeys.intersection(
        normalizedPantry,
      );
    }

    final bool shouldFollowPantry =
        widget.isPantrySuggestionWindow || _followPantry;
    if (shouldFollowPantry) {
      _applySelectionAndFetch(forceFetch: forceFetch);
    }
  }

  String _buildIngredientKey(List<String> ingredients) {
    final List<String> normalized =
        ingredients
            .map((String value) => value.toLowerCase().trim())
            .where((String value) => value.isNotEmpty)
            .toList()
          ..sort();
    return normalized.join('|');
  }

  void _applySelectionAndFetch({bool forceFetch = false}) {
    _selectedIngredientKeys = <String>{};
    _viewModel.updateRequiredQueryIngredients(const <String>[]);
    _viewModel.updateOptionalQueryIngredients(const <String>[]);
    _viewModel.fetchRecipes(
      pantryIngredients: const <String>[],
      forceRefresh: forceFetch,
      usePantryFallbackStrategy: false,
    );
  }

  void _toggleIngredient(String ingredient) {
    final String key = _normalizeIngredient(ingredient);
    if (key.isEmpty) {
      return;
    }
    setState(() {
      if (_selectedIngredientKeys.contains(key)) {
        _selectedIngredientKeys.remove(key);
      } else {
        _selectedIngredientKeys.add(key);
      }
    });
    _applySelectionAndFetch(forceFetch: true);
  }

  String _normalizeIngredient(String value) {
    return value.toLowerCase().trim();
  }

  void _requestLoadMoreIfNeeded(int index) {
    if (!_viewModel.hasMoreRecipes || _viewModel.isLoadingMore) {
      return;
    }

    if (index >= _viewModel.recipes.length - 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewModel.loadMoreRecipes();
      });
    }
  }

  @override
  void dispose() {
    _pantryListenable.removeListener(_handlePantryBoxChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isPantrySuggestionWindow
        ? 'Bạn muốn nấu món gì?'
        : 'Gợi ý món ăn';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (BuildContext context, _) {
          return Column(
            children: <Widget>[
              _PantryIngredientsBar(
                ingredients: _pantryIngredients,
                selectedIngredientKeys: _selectedIngredientKeys,
                allowManualEdit: !widget.isPantrySuggestionWindow,
                isPantrySuggestionWindow: widget.isPantrySuggestionWindow,
                onManualUpdate: _handleManualIngredientsUpdate,
                onToggleIngredient: _toggleIngredient,
              ),
              _FiltersBar(viewModel: _viewModel),
              if (_viewModel.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _buildContent(context)),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.isPantrySuggestionWindow
          ? const PlannerFooter(
              currentIndex: 1,
              showCalendar: false,
              showBottomNav: false,
            )
          : const PlannerFooter(
              currentIndex: 1,
              showCalendar: false,
              showBottomNav: false,
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.isLoading && _viewModel.recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null && _viewModel.recipes.isEmpty) {
      return _ErrorState(
        message: _viewModel.errorMessage!,
        onRetry: () => _viewModel.fetchRecipes(forceRefresh: true),
      );
    }

    if (_viewModel.recipes.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy công thức phù hợp với nguyên liệu hiện tại.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _viewModel.fetchRecipes(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        itemCount:
            _viewModel.recipes.length + (_viewModel.hasMoreRecipes ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: widget.isPantrySuggestionWindow ? 324 : 304,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _viewModel.recipes.length) {
            if (_viewModel.isLoadingMore) {
              return const Center(child: CircularProgressIndicator());
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _viewModel.loadMoreRecipes();
            });
            return const SizedBox.shrink();
          }

          _requestLoadMoreIfNeeded(index);

          final Recipe recipe = _viewModel.recipes[index];
          final PantryMatchResult pantryMatch = _viewModel
              .getPantryMatchForRecipe(recipe);
          final MealPlannerViewModel plannerViewModel = context
              .read<MealPlannerViewModel>();

          return _RecipeCard(
            recipe: recipe,
            pantryMatch: pantryMatch,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecipeDetailScreen(
                    recipeId: recipe.id,
                    recipeTitle: recipe.title,
                    viewModel: _viewModel,
                    pantryIngredients: _viewModel.referencePantryIngredients,
                  ),
                ),
              );
            },
            onQuickAdd: () async {
              final List<String> missing = pantryMatch.missingIngredients;
              bool addMissingToShopping = true;

              if (missing.isNotEmpty) {
                final String missingText = missing.take(4).join(', ');
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Thêm vào mua sắm?'),
                      content: Text(
                        'Món "${recipe.title}" còn thiếu: $missingText${missing.length > 4 ? '...' : ''}. Bạn muốn thêm vào danh sách mua sắm không?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Không'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Thêm'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == null) {
                  return;
                }
                addMissingToShopping = confirmed;
              }

              final bool added = await plannerViewModel.addRecipeToSelectedDate(
                recipe,
                missingIngredients: missing,
                addMissingToShopping: addMissingToShopping,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? 'Đã thêm món ăn ${recipe.title} vào ngày ${plannerViewModel.selectedDayLabel} thành công'
                          : 'Món ăn này đã có trong ngày ${plannerViewModel.selectedDayLabel}.',
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  void _handleManualIngredientsUpdate(List<String> ingredients) {
    if (ingredients.isEmpty) {
      _followPantry = true;
      setState(() {
        _pantryIngredients = <String>[];
        _selectedIngredientKeys = <String>{};
      });
      _syncPantryIngredientsFromBox(forceFetch: true);
      return;
    }

    _followPantry = false;
    setState(() {
      _pantryIngredients = List<String>.from(ingredients)..sort();
      _selectedIngredientKeys = <String>{};
    });
    _applySelectionAndFetch(forceFetch: true);
  }
}

class _PantryIngredientsBar extends StatelessWidget {
  const _PantryIngredientsBar({
    required this.ingredients,
    required this.selectedIngredientKeys,
    required this.allowManualEdit,
    required this.isPantrySuggestionWindow,
    required this.onManualUpdate,
    required this.onToggleIngredient,
  });

  final List<String> ingredients;
  final Set<String> selectedIngredientKeys;
  final bool allowManualEdit;
  final bool isPantrySuggestionWindow;
  final ValueChanged<List<String>> onManualUpdate;
  final ValueChanged<String> onToggleIngredient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                isPantrySuggestionWindow
                    ? 'Nguyên liệu trong kho'
                    : 'Nhập nguyên liệu',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (allowManualEdit)
                TextButton.icon(
                  onPressed: () =>
                      _showEditIngredientsDialog(context, ingredients),
                  icon: Icon(
                    ingredients.isEmpty ? Icons.add : Icons.edit,
                    size: 16,
                  ),
                  label: Text(ingredients.isEmpty ? 'Thêm' : 'Sửa'),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients
                .map(
                  (String ingredient) => FilterChip(
                    label: Text(ingredient),
                    selected: isPantrySuggestionWindow
                        ? false
                        : selectedIngredientKeys.contains(
                            _normalizeIngredient(ingredient),
                          ),
                    onSelected: isPantrySuggestionWindow
                        ? null
                        : (_) => onToggleIngredient(ingredient),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showEditIngredientsDialog(
    BuildContext context,
    List<String> ingredients,
  ) {
    final TextEditingController controller = TextEditingController(
      text: ingredients.join(', '),
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cập nhật nguyên liệu'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: chicken, tomato, egg, garlic',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final List<String> ingredients = controller.text
                    .split(',')
                    .map((String value) => value.trim())
                    .where((String value) => value.isNotEmpty)
                    .toList();
                onManualUpdate(ingredients);
                Navigator.of(context).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  String _normalizeIngredient(String value) {
    return value.toLowerCase().trim();
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.viewModel});

  final RecipeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final Widget mealTypeDropdown = _FilterDropdown(
      label: 'Loại bữa',
      selectedValue: viewModel.selectedMealType,
      options: RecipeViewModel.mealTypeOptions,
      onChanged: (value) {
        viewModel.updateMealTypeFilter(value);
        viewModel.applyCurrentFilters();
      },
    );

    final Widget dishTypeDropdown = _FilterDropdown(
      label: 'Loại món',
      selectedValue: viewModel.selectedDishType,
      options: RecipeViewModel.dishTypeOptions,
      onChanged: (value) {
        viewModel.updateDishTypeFilter(value);
        viewModel.applyCurrentFilters();
      },
    );

    final Widget dietDropdown = _FilterDropdown(
      label: 'Chế độ ăn',
      selectedValue: viewModel.selectedDiet,
      options: RecipeViewModel.dietOptions,
      onChanged: (value) {
        viewModel.updateDietFilter(value);
        viewModel.applyCurrentFilters();
      },
    );

    final Widget healthDropdown = _FilterDropdown(
      label: 'Sức khỏe/Dị ứng',
      selectedValue: viewModel.selectedHealth,
      options: RecipeViewModel.healthOptions,
      onChanged: (value) {
        viewModel.updateHealthFilter(value);
        viewModel.applyCurrentFilters();
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        children: <Widget>[
          _buildTwoColumnRow(mealTypeDropdown, dishTypeDropdown),
          const SizedBox(height: 8),
          _buildTwoColumnRow(dietDropdown, healthDropdown),
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow(Widget left, Widget right) {
    return Row(
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(value: null, child: Text('Tất cả')),
        ...options.map(
          (String item) =>
              DropdownMenuItem<String>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.pantryMatch,
    required this.onTap,
    required this.onQuickAdd,
  });

  final Recipe recipe;
  final PantryMatchResult pantryMatch;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final List<String> missingIngredients = pantryMatch.missingIngredients;

    return LongPressDraggable<RecipeDragPayload>(
      data: RecipeDragPayload(
        recipe: recipe,
        missingIngredients: missingIngredients,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 320,
          child: _buildRecipeCardBody(context, missingIngredients),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: _buildRecipeCardBody(context, missingIngredients),
      ),
      child: _buildRecipeCardBody(context, missingIngredients),
    );
  }

  Widget _buildRecipeCardBody(
    BuildContext context,
    List<String> missingIngredients,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 104,
              child: recipe.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.restaurant, size: 48),
                    )
                  : Image.network(
                      recipe.imageUrl,
                      alignment: Alignment.topCenter,
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const ColoredBox(
                              color: Colors.black12,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => const ColoredBox(
                            color: Colors.black12,
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final Widget metaChips = Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: <Widget>[
                              if (recipe.readyInMinutes != null &&
                                  recipe.readyInMinutes! > 0)
                                _MetaChip(
                                  icon: Icons.schedule,
                                  text: '${recipe.readyInMinutes} phút',
                                ),
                              if (recipe.servings != null)
                                _MetaChip(
                                  icon: Icons.people,
                                  text: '${recipe.servings} khẩu phần',
                                ),
                            ],
                          );

                          final Widget quickAddButton = FilledButton.tonalIcon(
                            onPressed: onQuickAdd,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: const Size(60, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          );

                          final bool compactLayout = constraints.maxWidth < 220;
                          if (compactLayout) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                metaChips,
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: quickAddButton,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: <Widget>[
                              Expanded(child: metaChips),
                              const SizedBox(width: 8),
                              quickAddButton,
                            ],
                          );
                        },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off, size: 46),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
