import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/meal_plan_model.dart';
import '../view_models/meal_planner_view_model.dart';
import '../../pantry/models/pantry_item_model.dart';
import '../../pantry/pantry_repository.dart';
import '../widgets/planner_footer.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MealPlannerView(title: 'Lên menu');
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MealPlannerView(title: 'Lên menu');
  }
}

class _MealPlannerView extends StatefulWidget {
  const _MealPlannerView({required this.title});

  final String title;

  @override
  State<_MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<_MealPlannerView> {
  late final TextEditingController _recipeNameController;
  late final TextEditingController _ingredientsController;

  @override
  void initState() {
    super.initState();
    _recipeNameController = TextEditingController();
    _ingredientsController = TextEditingController();
  }

  @override
  void dispose() {
    _recipeNameController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MealPlannerViewModel viewModel = context
        .watch<MealPlannerViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          viewModel.selectedDayLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _CustomRecipeForm(
                    recipeNameController: _recipeNameController,
                    ingredientsController: _ingredientsController,
                    onSubmit: () => _submitCustomRecipe(context, viewModel),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<Box<PantryItemModel>>(
                    valueListenable: Hive.box<PantryItemModel>(
                      PantryRepository.boxName,
                    ).listenable(),
                    builder: (context, pantryBox, _) {
                      final Set<String> pantryIndex = pantryBox.values
                          .where(
                            (PantryItemModel item) =>
                                item.deletedAtUtcMs == null,
                          )
                          .map((PantryItemModel item) => item.name)
                          .where((String name) => name.trim().isNotEmpty)
                          .map(_normalizeText)
                          .toSet();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: <Widget>[
                          if (viewModel.selectedDayRecipes.isEmpty)
                            const _EmptyPlanState()
                          else
                            ...viewModel.selectedDayRecipes.map(
                              (PlannedRecipe recipe) => _PlannedRecipeTile(
                                recipe: recipe,
                                pantryIndex: pantryIndex,
                                onRemove: () => viewModel
                                    .removeRecipeFromSelectedDate(
                                      recipe.recipeId,
                                    ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const PlannerFooter(currentIndex: 2),
    );
  }

  Future<void> _submitCustomRecipe(
    BuildContext context,
    MealPlannerViewModel viewModel,
  ) async {
    final String recipeName = _recipeNameController.text.trim();
    final List<String> ingredientNames = _parseIngredients(
      _ingredientsController.text,
    );

    if (recipeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên món ăn.')),
      );
      return;
    }

    final PantryRepository pantryRepository = PantryRepository();
    final List<PantryItemModel> pantryItems = await pantryRepository
        .getAllItems();
    final List<String> pantryNames = pantryItems
        .map((PantryItemModel item) => item.name.trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    final bool added = await viewModel.addCustomRecipeToSelectedDate(
      title: recipeName,
      ingredientNames: ingredientNames,
      pantryIngredients: pantryNames,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Đã thêm món ăn $recipeName vào ngày ${viewModel.selectedDayLabel} thành công'
              : 'Không thể thêm món ăn này vào ngày ${viewModel.selectedDayLabel}.',
        ),
      ),
    );

    if (added) {
      _recipeNameController.clear();
      _ingredientsController.clear();
    }
  }

  List<String> _parseIngredients(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  static String _normalizeText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _CustomRecipeForm extends StatelessWidget {
  const _CustomRecipeForm({
    required this.recipeNameController,
    required this.ingredientsController,
    required this.onSubmit,
  });

  final TextEditingController recipeNameController;
  final TextEditingController ingredientsController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Thêm món ăn thủ công',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: recipeNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên món ăn',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ingredientsController,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Tên nguyên liệu',
                hintText: 'Ngăn cách bằng dấu phẩy hoặc xuống dòng',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                child: const Text('Thêm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedRecipeTile extends StatelessWidget {
  const _PlannedRecipeTile({
    required this.recipe,
    required this.pantryIndex,
    required this.onRemove,
  });

  final PlannedRecipe recipe;
  final Set<String> pantryIndex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: recipe.imageUrl.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: Colors.black12,
                  child: const Icon(Icons.restaurant),
                )
              : Image.network(
                  recipe.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(recipe.title),
        subtitle: Text(
          _buildSubtitle(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          tooltip: 'Xóa món',
        ),
      ),
    );
  }

  String _buildSubtitle() {
    if (recipe.shoppingIngredients.isEmpty) {
      return 'Không có nguyên liệu thiếu';
    }

    final List<String> missing = recipe.shoppingIngredients
        .where(
          (ShoppingIngredientSnapshot item) =>
              !_isIngredientInPantry(item.name, pantryIndex),
        )
        .map((ShoppingIngredientSnapshot item) => item.name)
        .toList();

    if (missing.isEmpty) {
      return 'Không có nguyên liệu thiếu';
    }

    return 'Thiếu: ${missing.join(', ')}';
  }

  bool _isIngredientInPantry(String ingredient, Set<String> pantryIndex) {
    final String normalizedIngredient = _normalizeText(ingredient);
    for (final String pantryItem in pantryIndex) {
      if (normalizedIngredient.contains(pantryItem) ||
          pantryItem.contains(normalizedIngredient)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeText(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.event_note_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            'Chưa có món nào trong ngày này.',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
