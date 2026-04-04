import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../meal_planner/view_models/meal_planner_view_model.dart';
import '../../meal_planner/widgets/planner_footer.dart';
import '../models/shopping_item_model.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _unitController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MealPlannerViewModel viewModel = context
        .watch<MealPlannerViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách mua sắm')),
      body: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wideLayout = constraints.maxWidth >= 700;

                final Widget nameField = TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Thêm nguyên liệu',
                    border: OutlineInputBorder(),
                  ),
                );

                final Widget quantityField = _CompactInputField(
                  controller: _quantityController,
                  labelText: 'Số lượng',
                  keyboardType: TextInputType.number,
                  width: wideLayout ? 96 : null,
                );

                final Widget unitField = _CompactInputField(
                  controller: _unitController,
                  labelText: 'Đơn vị',
                  width: wideLayout ? 96 : null,
                );

                final Widget addButton = SizedBox(
                  width: wideLayout ? null : double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final double? quantity = double.tryParse(
                        _quantityController.text.trim(),
                      );
                      final bool added = await viewModel.addCustomShoppingItem(
                        viewModel.selectedDate,
                        name: _nameController.text,
                        quantity: quantity ?? 1,
                        unit: _unitController.text,
                      );
                      if (added && context.mounted) {
                        _nameController.clear();
                        _quantityController.clear();
                        _unitController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm vào danh sách mua sắm.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Thêm'),
                  ),
                );

                if (wideLayout) {
                  return Row(
                    children: <Widget>[
                      Expanded(flex: 3, child: nameField),
                      const SizedBox(width: 8),
                      quantityField,
                      const SizedBox(width: 8),
                      unitField,
                      const SizedBox(width: 8),
                      addButton,
                    ],
                  );
                }

                return Column(
                  children: <Widget>[
                    nameField,
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(child: quantityField),
                        const SizedBox(width: 8),
                        Expanded(child: unitField),
                      ],
                    ),
                    const SizedBox(height: 8),
                    addButton,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: viewModel.selectedDayShoppingItems.isEmpty
                ? const _EmptyShoppingState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (BuildContext context, int index) {
                      final item = viewModel.selectedDayShoppingItems[index];
                      return Card(
                        child: ListTile(
                          onTap: () =>
                              _showItemActions(context, viewModel, item),
                          title: Text(item.name),
                          subtitle: Text(
                            item.displayQuantity.isEmpty
                                ? 'Tự động thêm từ công thức'
                                : item.displayQuantity,
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                _showItemActions(context, viewModel, item),
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'Tùy chọn',
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 8),
                    itemCount: viewModel.selectedDayShoppingItems.length,
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const PlannerFooter(
        currentIndex: 2,
        showCalendar: false,
      ),
    );
  }

  Future<void> _showItemActions(
    BuildContext context,
    MealPlannerViewModel viewModel,
    ShoppingItemModel item,
  ) async {
    final _ShoppingItemAction? action =
        await showModalBottomSheet<_ShoppingItemAction>(
          context: context,
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.kitchen_outlined),
                    title: const Text('Thêm vào tủ bếp'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(_ShoppingItemAction.addToPantry),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Xóa khỏi danh sách'),
                    onTap: () =>
                        Navigator.of(context).pop(_ShoppingItemAction.delete),
                  ),
                ],
              ),
            );
          },
        );

    if (action == null || !context.mounted) {
      return;
    }

    if (action == _ShoppingItemAction.addToPantry) {
      final bool added = await viewModel.addShoppingItemToPantry(
        viewModel.selectedDate,
        item.itemId,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Đã thêm "${item.name}" vào tủ bếp.'
                : 'Không thể thêm vào tủ bếp.',
          ),
        ),
      );
      return;
    }

    await viewModel.removeShoppingItem(viewModel.selectedDate, item.itemId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa "${item.name}" khỏi danh sách.')),
      );
    }
  }
}

enum _ShoppingItemAction { addToPantry, delete }

class _EmptyShoppingState extends StatelessWidget {
  const _EmptyShoppingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.shopping_cart_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Danh sách mua sắm của ngày này đang trống.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInputField extends StatelessWidget {
  const _CompactInputField({
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.width,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final Widget field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );

    if (width == null) {
      return field;
    }

    return SizedBox(width: width, child: field);
  }
}
