import 'package:flutter/material.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';
import 'package:fridge_to_fork_assistant/features/recipes/view_models/recipe_view_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/views/recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late final RecipeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecipeViewModel(apiClient: RecipeApiClient());
    _viewModel.loadInitialSuggestions();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goi y mon an AI')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (BuildContext context, _) {
          return Column(
            children: <Widget>[
              _PantryIngredientsBar(viewModel: _viewModel),
              _FiltersBar(viewModel: _viewModel),
              if (_viewModel.isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _buildContent(context)),
            ],
          );
        },
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
        onRetry: _viewModel.fetchRecipes,
      );
    }

    if (_viewModel.recipes.isEmpty) {
      return const Center(
        child: Text(
          'Khong tim thay cong thuc phu hop voi nguyen lieu hien tai.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.fetchRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        itemCount: _viewModel.recipes.length,
        itemBuilder: (BuildContext context, int index) {
          final Recipe recipe = _viewModel.recipes[index];
          return _RecipeCard(
            recipe: recipe,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecipeDetailScreen(
                    recipeId: recipe.id,
                    recipeTitle: recipe.title,
                    viewModel: _viewModel,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PantryIngredientsBar extends StatelessWidget {
  const _PantryIngredientsBar({required this.viewModel});

  final RecipeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Nguyen lieu de test API',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEditIngredientsDialog(context, viewModel),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Sua'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: -8,
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
          title: const Text('Cap nhat nguyen lieu'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Vi du: chicken, tomato, egg, garlic',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () {
                final List<String> ingredients = controller.text
                    .split(',')
                    .map((String value) => value.trim())
                    .where((String value) => value.isNotEmpty)
                    .toList();
                vm.updateMockPantryIngredients(ingredients);
                vm.fetchRecipes();
                Navigator.of(context).pop();
              },
              child: const Text('Luu'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _FilterDropdown(
              label: 'Diet',
              selectedValue: viewModel.selectedDiet,
              options: RecipeViewModel.dietOptions,
              onChanged: viewModel.updateDietFilter,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDropdown(
              label: 'Cuisine',
              selectedValue: viewModel.selectedCuisine,
              options: RecipeViewModel.cuisineOptions,
              onChanged: viewModel.updateCuisineFilter,
            ),
          ),
          const SizedBox(width: 8),
          _TimeFilterChip(viewModel: viewModel),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: viewModel.fetchRecipes,
            child: const Text('Loc'),
          ),
        ],
      ),
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
      value: selectedValue,
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
        const DropdownMenuItem<String>(value: null, child: Text('Tat ca')),
        ...options.map(
          (String item) =>
              DropdownMenuItem<String>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  const _TimeFilterChip({required this.viewModel});

  final RecipeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final String label = viewModel.maxReadyTime == null
        ? 'Thoi gian'
        : '<= ${viewModel.maxReadyTime}p';

    return ActionChip(
      label: Text(label),
      onPressed: () => _showTimeDialog(context),
    );
  }

  void _showTimeDialog(BuildContext context) {
    double tempValue = (viewModel.maxReadyTime ?? 30).toDouble();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Gioi han thoi gian nau'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Slider(
                    min: 10,
                    max: 120,
                    divisions: 11,
                    value: tempValue,
                    label: '${tempValue.round()} phut',
                    onChanged: (double value) {
                      setState(() {
                        tempValue = value;
                      });
                    },
                  ),
                  Text('${tempValue.round()} phut'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    viewModel.updateMaxReadyTime(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Xoa'),
                ),
                FilledButton(
                  onPressed: () {
                    viewModel.updateMaxReadyTime(tempValue.round());
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ap dung'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: recipe.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.restaurant, size: 48),
                    )
                  : Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      if (recipe.readyInMinutes != null)
                        _MetaChip(
                          icon: Icons.schedule,
                          text: '${recipe.readyInMinutes} phut',
                        ),
                      if (recipe.servings != null)
                        _MetaChip(
                          icon: Icons.people,
                          text: '${recipe.servings} khau phan',
                        ),
                      if (recipe.isVegetarian)
                        const _MetaChip(icon: Icons.eco, text: 'Vegetarian'),
                    ],
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
