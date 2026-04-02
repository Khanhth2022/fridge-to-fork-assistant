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

  @override
  void initState() {
    super.initState();
    _viewModel = RecipeViewModel(
      apiClient: RecipeApiClient(
        appId: ApiConfig.edamamAppId,
        appKey: ApiConfig.edamamAppKey,
      ),
    );

    final List<String> seedIngredients =
        widget.pantryIngredients ?? const <String>[];
    if (seedIngredients.isNotEmpty) {
      _viewModel.updateMockPantryIngredients(seedIngredients);
      _viewModel.updateReferencePantryIngredients(seedIngredients);
      _viewModel.fetchRecipes(pantryIngredients: seedIngredients);
    } else {
      _loadPantryIngredientsForMatching();
      _viewModel.loadInitialSuggestions();
    }
  }

  Future<void> _loadPantryIngredientsForMatching() async {
    final PantryRepository pantryRepository = PantryRepository();
    final List<PantryItemModel> items = await pantryRepository.getAllItems();
    final List<String> pantryNames = items
        .map((PantryItemModel item) => item.name.trim())
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (!mounted) {
      return;
    }

    _viewModel.updateReferencePantryIngredients(pantryNames);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isPantrySuggestionWindow
        ? 'Bạn nấu được gì với các nguyên liệu sẵn có ?'
        : 'Gợi ý món ăn';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (BuildContext context, _) {
          return Column(
            children: <Widget>[
              _PantryIngredientsBar(
                viewModel: _viewModel,
                allowManualEdit: !widget.isPantrySuggestionWindow,
                isPantrySuggestionWindow: widget.isPantrySuggestionWindow,
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
          : const PlannerFooter(currentIndex: 1, showCalendar: false),
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
        itemCount: _viewModel.recipes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: widget.isPantrySuggestionWindow ? 324 : 304,
        ),
        itemBuilder: (BuildContext context, int index) {
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
              final bool added = await plannerViewModel.addRecipeToSelectedDate(
                recipe,
                missingIngredients: pantryMatch.missingIngredients,
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
}

class _PantryIngredientsBar extends StatelessWidget {
  const _PantryIngredientsBar({
    required this.viewModel,
    required this.allowManualEdit,
    required this.isPantrySuggestionWindow,
  });

  final RecipeViewModel viewModel;
  final bool allowManualEdit;
  final bool isPantrySuggestionWindow;

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
                      _showEditIngredientsDialog(context, viewModel),
                  icon: Icon(
                    viewModel.mockPantryIngredients.isEmpty
                        ? Icons.add
                        : Icons.edit,
                    size: 16,
                  ),
                  label: Text(
                    viewModel.mockPantryIngredients.isEmpty ? 'Thêm' : 'Sửa',
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: viewModel.mockPantryIngredients
                .map(
                  (String ingredient) => Chip(
                    label: Text(ingredient),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showEditIngredientsDialog(BuildContext context, RecipeViewModel vm) {
    final TextEditingController controller = TextEditingController(
      text: vm.mockPantryIngredients.join(', '),
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
                vm.updateMockPantryIngredients(ingredients);
                vm.fetchRecipes(pantryIngredients: ingredients);
                Navigator.of(context).pop();
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
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
    final bool fullMatch = pantryMatch.isFullMatch;
    final int total = pantryMatch.totalIngredientCount;
    final int used = pantryMatch.availableIngredientCount;
    final int missing = pantryMatch.missingIngredientCount;
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
          child: _buildRecipeCardBody(
            context,
            fullMatch,
            total,
            used,
            missing,
            missingIngredients,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: _buildRecipeCardBody(
          context,
          fullMatch,
          total,
          used,
          missing,
          missingIngredients,
        ),
      ),
      child: _buildRecipeCardBody(
        context,
        fullMatch,
        total,
        used,
        missing,
        missingIngredients,
      ),
    );
  }

  Widget _buildRecipeCardBody(
    BuildContext context,
    bool fullMatch,
    int total,
    int used,
    int missing,
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
              padding: const EdgeInsets.all(10),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: fullMatch
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: fullMatch
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Text(
                      fullMatch
                          ? 'Đủ nguyên liệu: Bạn có $used/$total nguyên liệu cho món này.'
                          : missingIngredients.isNotEmpty
                          ? 'Gần đủ: Bạn có $used/$total nguyên liệu, chỉ cần mua thêm ${missingIngredients.take(2).join(', ')}${missingIngredients.length > 2 ? '...' : ''}.'
                          : 'Gần đủ: Bạn có $used/$total nguyên liệu, cần mua thêm $missing nguyên liệu.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: fullMatch
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!fullMatch && missingIngredients.isNotEmpty)
                    Text(
                      'Thiếu: ${missingIngredients.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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
