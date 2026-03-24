
import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';


class AddItemBottomSheet extends StatefulWidget {
	final void Function(PantryItemModel) onAdd;
	final PantryItemModel? initialItem;
	const AddItemBottomSheet({Key? key, required this.onAdd, this.initialItem}) : super(key: key);

	@override
	State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
	late final TextEditingController _nameController;
	late final TextEditingController _quantityController;

	bool _isValid = false;
	DateTime? _purchaseDate;
	DateTime? _expiryDate;

	@override
	void initState() {
		super.initState();
		_nameController = TextEditingController(text: widget.initialItem?.name ?? '');
		_quantityController = TextEditingController(text: widget.initialItem != null ? widget.initialItem!.quantity.toString() : '');
		_purchaseDate = widget.initialItem?.purchaseDate;
		_expiryDate = widget.initialItem?.expiryDate;
		_nameController.addListener(_validate);
		_quantityController.addListener(_validate);
		_validate();
	}

	void _validate() {
		final name = _nameController.text.trim();
		final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
		final now = DateTime.now();
		final validPurchase = _purchaseDate != null && !_purchaseDate!.isAfter(DateTime(now.year, now.month, now.day));
		final validExpiry = _expiryDate != null && _purchaseDate != null && !_expiryDate!.isBefore(_purchaseDate!);
		_isValid = name.isNotEmpty && quantity > 0 && validPurchase && validExpiry;
		// ignore: invalid_use_of_protected_member
		if (mounted) setState(() {});
	}

	@override
	void dispose() {
		_nameController.removeListener(_validate);
		_quantityController.removeListener(_validate);
		_nameController.dispose();
		_quantityController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final isUpdate = widget.initialItem != null;
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
							decoration: const InputDecoration(
								labelText: 'Tên nguyên liệu',
								border: OutlineInputBorder(),
							),
						),
						const SizedBox(height: 12),
						TextField(
							controller: _quantityController,
							keyboardType: TextInputType.number,
							decoration: const InputDecoration(
								labelText: 'Số lượng',
								border: OutlineInputBorder(),
							),
						),
						const SizedBox(height: 12),
						Row(
							children: [
								Expanded(
									child: OutlinedButton(
										onPressed: () async {
											final now = DateTime.now();
											final picked = await showDatePicker(
												context: context,
												initialDate: _purchaseDate ?? now,
												firstDate: DateTime(now.year - 5),
												lastDate: now,
												helpText: 'Chọn ngày mua',
												locale: const Locale('vi', 'VN'),
											);
											if (picked != null) {
												_purchaseDate = picked;
												_validate();
											}
										},
										child: Text(_purchaseDate == null ? 'Chọn ngày mua' : 'Ngày mua: ${_formatDate(_purchaseDate!)}'),
									),
								),
								const SizedBox(width: 8),
								Expanded(
									child: OutlinedButton(
										onPressed: () async {
											final now = DateTime.now();
											final picked = await showDatePicker(
												context: context,
												initialDate: _expiryDate ?? (_purchaseDate ?? now),
												firstDate: _purchaseDate ?? now,
												lastDate: DateTime(now.year + 10),
												helpText: 'Chọn hạn sử dụng',
												locale: const Locale('vi', 'VN'),
											);
											if (picked != null) {
												_expiryDate = picked;
												_validate();
											}
										},
										child: Text(_expiryDate == null ? 'Chọn HSD' : 'HSD: ${_formatDate(_expiryDate!)}'),
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
									textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
								),
								onPressed: _isValid
										? () {
												final name = _nameController.text.trim();
												final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
												widget.onAdd(PantryItemModel(
													name: name,
													quantity: quantity,
													unit: widget.initialItem?.unit ?? '',
													purchaseDate: _purchaseDate!,
													expiryDate: _expiryDate!,
												));
												Navigator.pop(context);
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(
														content: Text(isUpdate ? 'Cập nhật thành công!' : 'Thêm nguyên liệu thành công!'),
														duration: const Duration(seconds: 2),
													),
												);
											}
										: null,
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
