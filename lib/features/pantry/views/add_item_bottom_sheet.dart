import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item_model.dart';
import '../view_models/pantry_view_model.dart';

class AddItemBottomSheet extends StatefulWidget {
  final Future<bool> Function(PantryItemModel) onAdd;
  final PantryItemModel? initialItem;
  const AddItemBottomSheet({Key? key, required this.onAdd, this.initialItem})
    : super(key: key);

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _expiryDateController;
  String? _quantityError;
  String? _unitError;
  String? _purchaseDateError;
  String? _expiryDateError;
  bool _isValid = false;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.initialItem?.quantity.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: widget.initialItem?.unit ?? '',
    );
    _purchaseDate = widget.initialItem?.purchaseDate;
    _expiryDate = widget.initialItem?.expiryDate;
    _nameController.addListener(_validate);

    _purchaseDateController = TextEditingController(
      text: _purchaseDate != null ? _formatDate(_purchaseDate!) : '',
    );
    _expiryDateController = TextEditingController(
      text: _expiryDate != null ? _formatDate(_expiryDate!) : '',
    );
  }

  void _validate() {
    final name = _nameController.text.trim();
    final quantityText = _quantityController.text.trim();
    final unit = _unitController.text.trim();
    final quantity = double.tryParse(quantityText) ?? 0;
    _nameError = null;
    _quantityError = null;
    _unitError = null;
    _purchaseDateError = null;
    _expiryDateError = null;

    if (name.isEmpty) {
      _nameError = 'Vui lòng nhập tên nguyên liệu';
    } else {
      // Validate trùng tên khi nhập
      final pantryViewModel = context.read<PantryViewModel>();
      final exists = pantryViewModel.items.any((e) {
        final isSameName = e.name.trim().toLowerCase() == name.toLowerCase();
        // Nếu đang edit, bỏ qua chính nó
        if (widget.initialItem != null &&
            e.name.trim().toLowerCase() ==
                widget.initialItem!.name.trim().toLowerCase()) {
          return false;
        }
        return isSameName;
      });
      if (exists) {
        _nameError = 'Nguyên liệu này đã tồn tại!';
      }
    }
    if (quantityText.isEmpty) {
      _quantityError = 'Vui lòng nhập số lượng';
    } else if (!RegExp(r'^(0|[1-9]\d*)(\.[0-9]+)?$').hasMatch(quantityText) ||
        quantity <= 0) {
      _quantityError =
          'Chỉ nhập số dương lớn hơn 0, có thể là số thập phân, không dấu cách, không dấu trừ';
    }
    if (unit.isEmpty) {
      _unitError = 'Vui lòng nhập đơn vị';
    }
    final now = DateTime.now();
    if (_purchaseDate == null) {
      _purchaseDateError = 'Chọn ngày mua';
    } else if (_purchaseDate!.isAfter(DateTime(now.year, now.month, now.day))) {
      _purchaseDateError = 'Ngày mua không hợp lệ';
    }
    if (_expiryDate == null) {
      _expiryDateError = 'Chọn hạn sử dụng';
    } else if (_purchaseDate != null && _expiryDate!.isBefore(_purchaseDate!)) {
      _expiryDateError = 'HSD phải sau ngày mua';
    }
    _isValid =
        _nameError == null &&
        _quantityError == null &&
        _unitError == null &&
        _purchaseDateError == null &&
        _expiryDateError == null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_validate);
    _quantityController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _purchaseDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.initialItem != null;
    // Cập nhật controller khi ngày thay đổi
    _purchaseDateController.text = _purchaseDate != null
        ? _formatDate(_purchaseDate!)
        : '';
    _expiryDateController.text = _expiryDate != null
        ? _formatDate(_expiryDate!)
        : '';
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isUpdate ? 'Cập nhật nguyên liệu' : 'Thêm nguyên liệu',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên nguyên liệu',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[0-9]*\.?[0-9]*'),
                      ),
                      FilteringTextInputFormatter.deny(RegExp(r'[\s-]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      border: const OutlineInputBorder(),
                      errorText: _quantityError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      labelText: 'Đơn vị',
                      border: const OutlineInputBorder(),
                      errorText: _unitError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _purchaseDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _purchaseDate = picked;
                          _purchaseDateController.text = _formatDate(picked);
                        });
                        _validate();
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _purchaseDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Ngày mua',
                          border: const OutlineInputBorder(),
                          errorText: _purchaseDateError,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _expiryDate ?? (_purchaseDate ?? DateTime.now()),
                        firstDate: _purchaseDate ?? DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _expiryDate = picked;
                          _expiryDateController.text = _formatDate(picked);
                        });
                        _validate();
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _expiryDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Hạn sử dụng',
                          border: const OutlineInputBorder(),
                          errorText: _expiryDateError,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF9575CD),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final quantityText = _quantityController.text.trim();
                  final quantity = double.tryParse(quantityText) ?? 0;
                  if (quantityText.isEmpty ||
                      !RegExp(
                        r'^(?:[1-9]\d*|0)?(?:\.[0-9]+)?$',
                      ).hasMatch(quantityText) ||
                      quantity <= 0) {
                    setState(() {
                      _quantityError =
                          'Chỉ nhập số dương lớn hơn 0, không dấu cách, không dấu trừ';
                    });
                    return;
                  }
                  setState(() {
                    _quantityError = null;
                  });
                  _validate();
                  if (_isValid) {
                    final item = PantryItemModel(
                      name: _nameController.text.trim(),
                      quantity: quantity,
                      unit: _unitController.text.trim(),
                      purchaseDate: _purchaseDate!,
                      expiryDate: _expiryDate!,
                    );
                    final result = await widget.onAdd(item);
                    if (result == true) {
                      Navigator.pop(context, item);
                    } else {
                      setState(() {
                        _nameError = 'Nguyên liệu này đã tồn tại!';
                      });
                    }
                  }
                },
                child: Text(isUpdate ? 'Cập nhật' : 'Thêm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
