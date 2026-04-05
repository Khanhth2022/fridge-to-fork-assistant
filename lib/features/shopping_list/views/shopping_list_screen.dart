import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/top_right_notification.dart';
import '../../meal_planner/view_models/meal_planner_view_model.dart';
import '../../meal_planner/widgets/planner_footer.dart';
import '../models/shopping_item_model.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  static const List<String> _defaultUnits = <String>[
    'g',
    'kg',
    'ml',
    'lít',
    'quả',
    'hộp',
    'gói',
    'chai',
    'lon',
    'bó',
    'củ',
    'muỗng',
    'muỗng cà phê',
    'muỗng canh',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  final Set<String> _selectedItemIds = <String>{};

  bool get _isSelectionMode => _selectedItemIds.isNotEmpty;

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
    final List<ShoppingItemModel> items = viewModel.selectedDayShoppingItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? 'Đã chọn ${_selectedItemIds.length} mục'
              : 'Danh sách mua sắm',
        ),
        actions: _isSelectionMode
            ? <Widget>[
                IconButton(
                  tooltip: 'Thêm vào tủ bếp',
                  icon: const Icon(Icons.kitchen_outlined),
                  onPressed: () => _addSelectedItemsToPantry(viewModel),
                ),
                IconButton(
                  tooltip: 'Xóa mục đã chọn',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeSelectedItems(viewModel),
                ),
                IconButton(
                  tooltip: 'Bỏ chọn',
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
              ]
            : null,
      ),
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
          Expanded(
            child: items.isEmpty
                ? const _EmptyShoppingState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (BuildContext context, int index) {
                      final ShoppingItemModel item = items[index];
                      final bool isSelected = _selectedItemIds.contains(
                        item.itemId,
                      );
                      return Card(
                        child: ListTile(
                          onLongPress: () => _toggleItemSelection(item.itemId),
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleItemSelection(item.itemId);
                              return;
                            }
                            _showItemActions(context, viewModel, item);
                          },
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleItemSelection(item.itemId),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            item.displayQuantity.isEmpty
                                ? 'Tự động thêm từ công thức'
                                : item.displayQuantity,
                          ),
                          trailing: _isSelectionMode
                              ? null
                              : IconButton(
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
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddItemDialog(viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
      bottomNavigationBar: const PlannerFooter(
        currentIndex: 2,
        showCalendar: false,
      ),
    );
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedItemIds.isEmpty) {
      return;
    }
    setState(_selectedItemIds.clear);
  }

  Future<void> _addSelectedItemsToPantry(MealPlannerViewModel viewModel) async {
    final List<String> selectedIds = List<String>.from(_selectedItemIds);
    if (selectedIds.isEmpty) {
      return;
    }

    int successCount = 0;
    for (final String itemId in selectedIds) {
      final bool added = await viewModel.addShoppingItemToPantry(
        viewModel.selectedDate,
        itemId,
      );
      if (added) {
        successCount++;
      }
    }

    if (!mounted) {
      return;
    }

    _clearSelection();
    final int failedCount = selectedIds.length - successCount;
    showTopRightNotification(
      context,
      failedCount == 0
          ? 'Đã thêm $successCount mục vào tủ bếp.'
          : 'Đã thêm $successCount mục, thất bại $failedCount mục.',
    );
  }

  Future<void> _removeSelectedItems(MealPlannerViewModel viewModel) async {
    final List<String> selectedIds = List<String>.from(_selectedItemIds);
    if (selectedIds.isEmpty) {
      return;
    }

    int removedCount = 0;
    for (final String itemId in selectedIds) {
      final bool removed = await viewModel.removeShoppingItem(
        viewModel.selectedDate,
        itemId,
      );
      if (removed) {
        removedCount++;
      }
    }

    if (!mounted) {
      return;
    }

    _clearSelection();
    showTopRightNotification(context, 'Đã xóa $removedCount mục khỏi danh sách.');
  }

  Future<void> _showAddItemDialog(MealPlannerViewModel viewModel) async {
    _nameController.clear();
    _quantityController.clear();
    _unitController.clear();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thêm nguyên liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Thêm nguyên liệu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      menuMaxHeight: 220,
                      initialValue: null,
                      decoration: const InputDecoration(
                        labelText: 'Đơn vị',
                        border: OutlineInputBorder(),
                      ),
                      items: _unitOptionsFor('')
                          .map(
                            (String unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        _unitController.text = (value ?? '').trim();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final double? quantity = double.tryParse(_quantityController.text.trim());
    final bool added = await viewModel.addCustomShoppingItem(
      viewModel.selectedDate,
      name: _nameController.text,
      quantity: quantity ?? 1,
      unit: _unitController.text,
    );

    if (!mounted) {
      return;
    }

    showTopRightNotification(
      context,
      added
          ? 'Đã thêm vào danh sách mua sắm.'
          : 'Vui lòng nhập tên nguyên liệu hợp lệ.',
    );
  }

  Future<void> _showEditItemDialog(
    MealPlannerViewModel viewModel,
    ShoppingItemModel item,
  ) async {
    _nameController.text = item.name;
    _quantityController.text = _formatQuantityForInput(item.quantity);
    _unitController.text = item.unit;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa nguyên liệu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nguyên liệu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      menuMaxHeight: 220,
                      initialValue: _unitController.text.trim().isEmpty
                          ? null
                          : _unitController.text.trim(),
                      decoration: const InputDecoration(
                        labelText: 'Đơn vị',
                        border: OutlineInputBorder(),
                      ),
                      items: _unitOptionsFor(_unitController.text)
                          .map(
                            (String unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        _unitController.text = (value ?? '').trim();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final double? quantity = double.tryParse(_quantityController.text.trim());
    final bool updated = await viewModel.updateShoppingItem(
      viewModel.selectedDate,
      item.itemId,
      name: _nameController.text,
      quantity: quantity ?? item.quantity,
      unit: _unitController.text,
    );

    if (!mounted) {
      return;
    }

    showTopRightNotification(
      context,
      updated
          ? 'Đã cập nhật "${item.name}".'
          : 'Không thể cập nhật mục này.',
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
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Chỉnh sửa'),
                    onTap: () =>
                        Navigator.of(context).pop(_ShoppingItemAction.edit),
                  ),
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

    if (action == _ShoppingItemAction.edit) {
      await _showEditItemDialog(viewModel, item);
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
      showTopRightNotification(
        context,
        added
            ? 'Đã thêm "${item.name}" vào tủ bếp.'
            : 'Không thể thêm vào tủ bếp.',
      );
      return;
    }

    await viewModel.removeShoppingItem(viewModel.selectedDate, item.itemId);
    if (context.mounted) {
      showTopRightNotification(context, 'Đã xóa "${item.name}" khỏi danh sách.');
    }
  }

  String _formatQuantityForInput(double value) {
    final double rounded = value.roundToDouble();
    if (rounded == value) {
      return rounded.toInt().toString();
    }
    String text = value.toStringAsFixed(2);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  List<String> _unitOptionsFor(String currentUnit) {
    final String cleaned = currentUnit.trim();
    if (cleaned.isEmpty || _defaultUnits.contains(cleaned)) {
      return _defaultUnits;
    }
    return <String>[..._defaultUnits, cleaned];
  }
}

enum _ShoppingItemAction { edit, addToPantry, delete }

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
