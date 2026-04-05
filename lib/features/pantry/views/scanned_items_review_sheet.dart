import 'package:flutter/material.dart';

import '../models/pantry_item_model.dart';

class ScannedItemsReviewSheet extends StatefulWidget {
  const ScannedItemsReviewSheet({super.key, required this.ingredients});

  final List<String> ingredients;

  @override
  State<ScannedItemsReviewSheet> createState() =>
      _ScannedItemsReviewSheetState();
}

class _ScannedItemsReviewSheetState extends State<ScannedItemsReviewSheet> {
  late DateTime _purchaseDate;
  late DateTime _expiryDate;
  late final List<_DraftIngredient> _drafts;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _purchaseDate = DateTime(now.year, now.month, now.day);
    _expiryDate = _purchaseDate.add(const Duration(days: 7));

    _drafts = widget.ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet()
        .map(
          (name) => _DraftIngredient(name: name, quantity: '1', unit: 'phần'),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Xác nhận nguyên liệu từ ảnh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Chỉnh lại thông tin trước khi lưu vào kho',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text('Ngày mua: ${_formatDate(_purchaseDate)}'),
                    onPressed: _pickPurchaseDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text('HSD: ${_formatDate(_expiryDate)}'),
                    onPressed: _pickExpiryDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _drafts.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có nguyên liệu hợp lệ từ kết quả quét.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: _drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _buildDraftCard(_drafts[index]);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Lưu vào kho'),
                onPressed: _saveAll,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(_DraftIngredient draft) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: draft.selected,
                  onChanged: (value) {
                    setState(() {
                      draft.selected = value ?? false;
                    });
                  },
                ),
                const Text('Chọn'),
                const Spacer(),
                IconButton(
                  tooltip: 'Bỏ mục này',
                  onPressed: () {
                    setState(() {
                      draft.selected = false;
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
            TextFormField(
              initialValue: draft.name,
              decoration: const InputDecoration(
                labelText: 'Tên nguyên liệu',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => draft.name = value,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: draft.quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => draft.quantity = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: draft.unit,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => draft.unit = value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _purchaseDate = picked;
      if (_expiryDate.isBefore(_purchaseDate)) {
        _expiryDate = _purchaseDate.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate.isBefore(_purchaseDate)
          ? _purchaseDate.add(const Duration(days: 7))
          : _expiryDate,
      firstDate: _purchaseDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _expiryDate = picked;
    });
  }

  void _saveAll() {
    final selected = _drafts.where((draft) => draft.selected).toList();
    if (selected.isEmpty) {
      _showMessage('Bạn chưa chọn nguyên liệu nào để lưu.');
      return;
    }

    final items = <PantryItemModel>[];
    for (final draft in selected) {
      final name = draft.name.trim();
      final unit = draft.unit.trim();
      final quantity = double.tryParse(draft.quantity.trim());

      if (name.isEmpty || unit.isEmpty || quantity == null || quantity <= 0) {
        _showMessage('Vui lòng kiểm tra lại tên, số lượng và đơn vị.');
        return;
      }

      items.add(
        PantryItemModel(
          name: name,
          quantity: quantity,
          unit: unit,
          purchaseDate: _purchaseDate,
          expiryDate: _expiryDate,
        ),
      );
    }

    Navigator.of(context).pop(items);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _DraftIngredient {
  _DraftIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  String name;
  String quantity;
  String unit;
  bool selected = true;
}
