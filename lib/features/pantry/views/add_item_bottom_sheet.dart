import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pantry_item_model.dart';

class AddItemBottomSheet extends StatefulWidget {
  final Future<bool> Function(PantryItemModel) onAdd;
  final PantryItemModel? initialItem;
  final List<String> existingItemNames;

  const AddItemBottomSheet({
    super.key,
    required this.onAdd,
    this.initialItem,
    this.existingItemNames = const <String>[],
  });

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
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

  late final TextEditingController _purchaseDateController;
  late final TextEditingController _expiryDateController;
  String? _quantityError;
  String? _unitError;
  String? _purchaseDateError;
  String? _expiryDateError;
  bool _isValid = false;
  bool _showValidationErrors = false;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  String? _nameError;

  List<String> get _unitOptions {
    final String existingUnit = widget.initialItem?.unit.trim() ?? '';
    if (existingUnit.isEmpty || _defaultUnits.contains(existingUnit)) {
      return _defaultUnits;
    }
    return <String>[..._defaultUnits, existingUnit];
  }

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
      final String normalizedName = name.toLowerCase();
      final String? normalizedInitialName = widget.initialItem?.name
          .trim()
          .toLowerCase();
      final exists = widget.existingItemNames.any((existingName) {
        final normalizedExistingName = existingName.trim().toLowerCase();
        if (normalizedExistingName != normalizedName) {
          return false;
        }

        // Nếu đang sửa và tên giữ nguyên thì không tính là trùng.
        return normalizedInitialName == null ||
            normalizedExistingName != normalizedInitialName;
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
                errorText: _showValidationErrors ? _nameError : null,
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
                      errorText: _showValidationErrors ? _quantityError : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    menuMaxHeight: 220,
                    initialValue: _unitController.text.trim().isEmpty
                        ? null
                        : _unitController.text.trim(),
                    decoration: InputDecoration(
                      labelText: 'Đơn vị',
                      border: const OutlineInputBorder(),
                      errorText: _showValidationErrors ? _unitError : null,
                    ),
                    items: _unitOptions
                        .map(
                          (String unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      _unitController.text = (value ?? '').trim();
                      _validate();
                    },
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
                          errorText: _showValidationErrors
                              ? _purchaseDateError
                              : null,
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
                          errorText: _showValidationErrors
                              ? _expiryDateError
                              : null,
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
                  setState(() {
                    _showValidationErrors = true;
                  });
                  _validate();
                  if (!_isValid) {
                    return;
                  }

                  final quantity =
                      double.tryParse(_quantityController.text.trim()) ?? 0;
                  if (_isValid) {
                    final item = PantryItemModel(
                      name: _nameController.text.trim(),
                      quantity: quantity,
                      unit: _unitController.text.trim(),
                      purchaseDate: _purchaseDate!,
                      expiryDate: _expiryDate!,
                    );
                    try {
                      final result = await widget.onAdd(item);
                      if (!context.mounted) {
                        return;
                      }

                      if (result == true) {
                        Navigator.pop(context, item);
                        return;
                      }

                      setState(() {
                        _nameError = 'Nguyên liệu này đã tồn tại!';
                        _isValid = false;
                      });
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Không thể thêm nguyên liệu. Vui lòng thử lại.',
                          ),
                        ),
                      );
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
