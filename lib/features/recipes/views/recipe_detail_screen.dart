import 'package:flutter/material.dart';
import 'package:fridge_to_fork_assistant/core/config/api_config.dart';
import 'package:fridge_to_fork_assistant/core/widgets/top_right_notification.dart';
import 'package:fridge_to_fork_assistant/features/meal_planner/view_models/meal_planner_view_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/models/recipe_model.dart';
import 'package:fridge_to_fork_assistant/features/recipes/repositories/recipe_api_client.dart';
import 'package:fridge_to_fork_assistant/features/recipes/view_models/recipe_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    this.recipeTitle,
    this.viewModel,
    this.pantryIngredients = const <String>[],
  });

  final int recipeId;
  final String? recipeTitle;
  final RecipeViewModel? viewModel;
  final List<String> pantryIngredients;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final RecipeViewModel _viewModel;
  late final bool _ownsViewModel;
  late final RecipeApiClient _translationClient;
  late final Set<String> _normalizedPantryIngredients;
  late final Set<String> _pantryTokens;
  int? _translatedRecipeId;
  bool _isTranslatingIngredients = false;
  Map<String, String> _translatedIngredients = <String, String>{};

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _normalizedPantryIngredients = widget.pantryIngredients
        .map(_normalizeText)
        .where((String value) => value.isNotEmpty)
        .toSet();
    _pantryTokens = widget.pantryIngredients
        .expand(_extractTokens)
        .where((String token) => token.isNotEmpty)
        .toSet();
    _viewModel =
        widget.viewModel ??
        RecipeViewModel(
          apiClient: RecipeApiClient(
            appId: ApiConfig.edamamAppId,
            appKey: ApiConfig.edamamAppKey,
          ),
        );
    _translationClient = RecipeApiClient();
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
      appBar: AppBar(title: Text(widget.recipeTitle ?? 'Chi tiết món ăn')),
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
              child: Text('Không tìm thấy thông tin món ăn.'),
            );
          }

          _ensureIngredientTranslations(recipe);

          final String detailImageUrl = recipe.imageUrl.isNotEmpty
              ? recipe.imageUrl
              : '';

          return RefreshIndicator(
            onRefresh: () => _viewModel.fetchRecipeDetail(widget.recipeId),
            child: ListView(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: detailImageUrl.isEmpty
                      ? const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.restaurant, size: 56),
                        )
                      : Image.network(
                          detailImageUrl,
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
                          if (recipe.readyInMinutes != null &&
                              recipe.readyInMinutes! > 0)
                            _DetailChip(
                              icon: Icons.schedule,
                              text: '${recipe.readyInMinutes} phút',
                            ),
                          if (recipe.servings != null)
                            _DetailChip(
                              icon: Icons.people,
                              text: '${recipe.servings} khẩu phần',
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
                        title: 'Tóm tắt',
                        child: Text(
                          _stripHtmlTags(recipe.summary ?? 'Đang cập nhật...'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Nguyên liệu',
                        child: recipe.ingredients.isEmpty
                            ? const Text('Không có danh sách nguyên liệu.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: recipe.ingredients
                                    .map(
                                      (RecipeIngredient ingredient) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _IngredientRow(
                                          text: _translatedIngredientText(
                                            ingredient,
                                          ),
                                          isAvailable: _isIngredientAvailable(
                                            ingredient,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      if (_isTranslatingIngredients) ...<Widget>[
                        const SizedBox(height: 8),
                        const Row(
                          children: <Widget>[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Đang dịch nguyên liệu sang tiếng Việt...'),
                          ],
                        ),
                      ],
                      if (_missingIngredientNames(recipe).isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _addMissingIngredientsToShopping(
                            recipe,
                          ),
                          icon: const Icon(Icons.playlist_add),
                          label: Text(
                            'Thêm ${_missingIngredientNames(recipe).length} nguyên liệu thiếu vào mua sắm',
                          ),
                        ),
                      ],
                      if (recipe.videoUrl != null &&
                          recipe.videoUrl!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Video',
                          child: SelectableText(recipe.videoUrl!),
                        ),
                      ],
                      if (recipe.sourceUrl != null &&
                          recipe.sourceUrl!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Nguồn công thức',
                          child: FilledButton.icon(
                            onPressed: () => _openSourceUrl(recipe.sourceUrl!),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Xem hướng dẫn trên website'),
                          ),
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

  bool _isIngredientAvailable(RecipeIngredient ingredient) {
    final String ingredientName = _normalizeText(ingredient.name);
    final String ingredientOriginal = _normalizeText(ingredient.original);
    final String ingredientTranslated = _normalizeText(
      _translatedIngredientText(ingredient),
    );
    final Set<String> ingredientTokens = <String>{
      ..._extractTokens(ingredient.name),
      ..._extractTokens(ingredient.original),
      ..._extractTokens(_translatedIngredientText(ingredient)),
    };

    for (final String pantryItem in _normalizedPantryIngredients) {
      if (pantryItem.isEmpty) {
        continue;
      }
      if (ingredientName.contains(pantryItem) ||
          pantryItem.contains(ingredientName)) {
        return true;
      }
      if (ingredientOriginal.contains(pantryItem) ||
          pantryItem.contains(ingredientOriginal)) {
        return true;
      }
      if (ingredientTranslated.contains(pantryItem) ||
          pantryItem.contains(ingredientTranslated)) {
        return true;
      }
    }

    if (ingredientTokens.isNotEmpty && _pantryTokens.isNotEmpty) {
      for (final String token in ingredientTokens) {
        if (_pantryTokens.contains(token)) {
          return true;
        }
      }
    }

    return false;
  }

  List<String> _missingIngredientNames(Recipe recipe) {
    return recipe.ingredients
        .where((RecipeIngredient ingredient) => !_isIngredientAvailable(ingredient))
        .map(
          (RecipeIngredient ingredient) => ingredient.name.trim().isNotEmpty
              ? ingredient.name.trim()
              : ingredient.original.trim(),
        )
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _addMissingIngredientsToShopping(Recipe recipe) async {
    final MealPlannerViewModel plannerViewModel = context
        .read<MealPlannerViewModel>();
    final List<String> missingItems = _missingIngredientNames(recipe);

    if (missingItems.isEmpty) {
      return;
    }

    int addedCount = 0;
    for (final String ingredient in missingItems) {
      final bool added = await plannerViewModel.addCustomShoppingItem(
        plannerViewModel.selectedDate,
        name: ingredient,
        quantity: 1,
        unit: '',
      );
      if (added) {
        addedCount++;
      }
    }

    if (!mounted) {
      return;
    }

    showTopRightNotification(
      context,
      addedCount == 0
          ? 'Các nguyên liệu thiếu đã có trong danh sách mua sắm của ${plannerViewModel.selectedDayLabel}.'
          : 'Đã thêm $addedCount nguyên liệu thiếu vào danh sách mua sắm của ${plannerViewModel.selectedDayLabel}.',
    );
  }

  String _normalizeText(String value) {
    final String normalized = _stripVietnameseAccents(value.toLowerCase());
    return normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _stripVietnameseAccents(String input) {
    const Map<String, String> replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    final StringBuffer output = StringBuffer();
    for (final String char in input.split('')) {
      output.write(replacements[char] ?? char);
    }
    return output.toString();
  }

  Set<String> _extractTokens(String input) {
    final String normalized = _normalizeText(input);
    if (normalized.isEmpty) {
      return <String>{};
    }

    final Set<String> stopWords = <String>{
      'and',
      'or',
      'of',
      'the',
      'a',
      'an',
      'fresh',
      'large',
      'small',
      'to',
      'taste',
      'cup',
      'cups',
      'tbsp',
      'tsp',
      'oz',
      'g',
      'kg',
      'ml',
      'l',
      'optional',
    };

    return normalized.split(' ').map((String token) => token.trim()).where((
      String token,
    ) {
      if (token.length < 3) {
        return false;
      }
      if (RegExp(r'^\d+$').hasMatch(token)) {
        return false;
      }
      return !stopWords.contains(token);
    }).toSet();
  }

  Future<void> _openSourceUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final bool opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      showTopRightNotification(context, 'Không mở được liên kết nguồn công thức.');
    }
  }

  void _ensureIngredientTranslations(Recipe recipe) {
    if (_translatedRecipeId == recipe.id) {
      return;
    }
    if (_isTranslatingIngredients) {
      return;
    }

    _translatedRecipeId = recipe.id;
    _translatedIngredients = <String, String>{};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _translateRecipeIngredients(recipe);
    });
  }

  Future<void> _translateRecipeIngredients(Recipe recipe) async {
    if (!mounted) {
      return;
    }

    final List<String> ingredientTexts = recipe.ingredients
        .map((RecipeIngredient ingredient) {
          final String source = ingredient.original.trim().isNotEmpty
              ? ingredient.original.trim()
              : ingredient.name.trim();
          return source;
        })
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (ingredientTexts.isEmpty) {
      return;
    }

    setState(() {
      _isTranslatingIngredients = true;
    });

    final int requestRecipeId = recipe.id;
    final Map<String, String> translated =
        await _translationClient.translateToVietnamese(ingredientTexts);

    if (!mounted || _translatedRecipeId != requestRecipeId) {
      return;
    }

    setState(() {
      _translatedIngredients = translated;
      _isTranslatingIngredients = false;
    });
  }

  String _translatedIngredientText(RecipeIngredient ingredient) {
    final String source = ingredient.original.trim().isNotEmpty
        ? ingredient.original.trim()
        : ingredient.name.trim();
    if (source.isEmpty) {
      return source;
    }
    return _translatedIngredients[source] ?? source;
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.text, required this.isAvailable});

  final String text;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final Color background = isAvailable
        ? Colors.green.shade50
        : Colors.orange.shade50;
    final Color border = isAvailable
        ? Colors.green.shade300
        : Colors.orange.shade300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isAvailable ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isAvailable ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(text),
                const SizedBox(height: 4),
                Text(
                  isAvailable ? 'Đã có trong kho' : 'Chưa có trong kho',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
