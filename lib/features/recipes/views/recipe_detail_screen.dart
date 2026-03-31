import 'package:flutter/material.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';
import 'package:fridge_to_fork_assistant/features/recipes/view_models/recipe_view_model.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.recipeTitle,
    this.viewModel,
  });

  final int recipeId;
  final String? recipeTitle;
  final RecipeViewModel? viewModel;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final RecipeViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel =
        widget.viewModel ?? RecipeViewModel(apiClient: RecipeApiClient());
    _viewModel.fetchRecipeDetail(widget.recipeId);
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipeTitle ?? 'Chi tiet mon an')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (BuildContext context, _) {
          final Recipe? recipe = _viewModel.selectedRecipe;

          if (_viewModel.isDetailLoading && recipe == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null && recipe == null) {
            return _DetailErrorState(
              message: _viewModel.errorMessage!,
              onRetry: () => _viewModel.fetchRecipeDetail(widget.recipeId),
            );
          }

          if (recipe == null) {
            return const Center(
              child: Text('Khong tim thay thong tin mon an.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _viewModel.fetchRecipeDetail(widget.recipeId),
            child: ListView(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: recipe.imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.restaurant, size: 56),
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          if (recipe.readyInMinutes != null)
                            _DetailChip(
                              icon: Icons.schedule,
                              text: '${recipe.readyInMinutes} phut',
                            ),
                          if (recipe.servings != null)
                            _DetailChip(
                              icon: Icons.people,
                              text: '${recipe.servings} khau phan',
                            ),
                          if (recipe.isVegan)
                            const _DetailChip(
                              icon: Icons.energy_savings_leaf,
                              text: 'Vegan',
                            ),
                          if (recipe.isVegetarian && !recipe.isVegan)
                            const _DetailChip(
                              icon: Icons.eco,
                              text: 'Vegetarian',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Tom tat',
                        child: Text(
                          _stripHtmlTags(recipe.summary ?? 'Dang cap nhat...'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Nguyen lieu',
                        child: recipe.ingredients.isEmpty
                            ? const Text('Khong co danh sach nguyen lieu.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recipe.ingredients
                                    .map(
                                      (RecipeIngredient ingredient) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Text('• '),
                                            Expanded(
                                              child: Text(
                                                ingredient.original.isNotEmpty
                                                    ? ingredient.original
                                                    : ingredient.name,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Huong dan',
                        child: Text(
                          _stripHtmlTags(
                            recipe.instructions ??
                                'Dang cap nhat huong dan nau an.',
                          ),
                        ),
                      ),
                      if (recipe.sourceUrl != null &&
                          recipe.sourceUrl!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Nguon cong thuc',
                          child: SelectableText(recipe.sourceUrl!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _stripHtmlTags(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 8),
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
