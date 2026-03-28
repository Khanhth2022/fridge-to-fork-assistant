import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../view_models/pantry_view_model.dart';
import '../models/pantry_item_model.dart';

class PantryScreen extends StatelessWidget {
    Widget _buildExpiryAlert(PantryViewModel viewModel) {
      final now = DateTime.now();
      final expiringItems = viewModel.items.where((item) {
        final daysLeft = item.expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        return daysLeft >= 0 && daysLeft <= 2;
      }).toList();
      if (expiringItems.isEmpty) return SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFE3F2FD), // Xanh nhạt
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF90CAF9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notifications_active, color: Colors.black54, size: 20),
                SizedBox(width: 8),
                Text('Cảnh báo hạn sử dụng', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            ...expiringItems.map((item) {
              final daysLeft = item.expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.name} sẽ hết hạn trong $daysLeft ngày.'),
                  TextButton(
                    onPressed: () {
                      // TODO: Điều hướng sang màn hình gợi ý món ăn với nguyên liệu này
                    },
                    child: const Text('Tìm món'),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      );
    }
  const PantryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PantryViewModel>(context);
    // Khởi tạo dữ liệu mẫu nếu danh sách rỗng
    viewModel.initMockData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tủ bếp'),
        backgroundColor: Color(0xFF9575CD),
      ),
      body: viewModel.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/empty.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 16),
                  const Text('Chưa có nguyên liệu nào!', style: TextStyle(fontSize: 18, color: Colors.black45)),
                ],
              ),
            )
            : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: viewModel.items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildExpiryAlert(viewModel);
                }
                final item = viewModel.items[index - 1];
                // ...existing code...
                final now = DateTime.now();
                final daysLeft = item.expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                final isExpired = daysLeft < 0;
                final isExpiringSoon = daysLeft >= 0 && daysLeft <= 2;
                Color color;
                if (daysLeft < 0) {
                  color = Colors.red;
                } else if (daysLeft < 3) {
                  color = Colors.orange;
                } else {
                  color = Colors.black45;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: isExpired
                      ? Colors.red[50]
                      : isExpiringSoon
                          ? Colors.orange[50]
                          : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isExpired
                        ? const BorderSide(color: Colors.red, width: 1)
                        : isExpiringSoon
                            ? const BorderSide(color: Colors.orange, width: 1)
                            : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text('Số lượng: ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.black38),
                                const SizedBox(width: 2),
                                Text('Ngày mua: ${PantryScreen.formatDate(item.purchaseDate)}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                                  tooltip: 'Cập nhật',
                                  onPressed: () async {
                                    final updated = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (sheetContext) => AddItemBottomSheet(
                                        initialItem: item,
                                        onAdd: (updatedItem) {
                                          Navigator.pop(sheetContext, updatedItem);
                                        },
                                      ),
                                    );
                                    if (updated != null) {
                                      final realIndex = viewModel.items.indexOf(item);
                                      if (realIndex != -1) {
                                        viewModel.updateItem(realIndex, updated);
                                      }
                                    }
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    final realIndex = viewModel.items.indexOf(item);
                                    if (realIndex == -1) return;
                                    if (value == 'half') {
                                      final current = viewModel.items[realIndex];
                                      double newQty = (current.quantity / 2);
                                      // Làm tròn 1 chữ số thập phân nếu cần
                                      if (newQty % 1 == 0) {
                                        newQty = newQty.toInt().toDouble();
                                      } else {
                                        newQty = double.parse(newQty.toStringAsFixed(1));
                                      }
                                      if (newQty > 0) {
                                        viewModel.updateItem(realIndex, PantryItemModel(
                                          name: current.name,
                                          quantity: newQty,
                                          unit: current.unit,
                                          purchaseDate: current.purchaseDate,
                                          expiryDate: current.expiryDate,
                                        ));
                                      } else {
                                        viewModel.deleteItem(realIndex);
                                      }
                                    } else if (value == 'all') {
                                      viewModel.deleteItem(realIndex);
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Xác nhận'),
                                          content: Text('Bạn có chắc muốn xóa nguyên liệu "${item.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        viewModel.deleteItem(realIndex);
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'half',
                                      child: Text('Dùng một nửa'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'all',
                                      child: Text('Dùng hết'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text('HSD: ${PantryScreen.formatDate(item.expiryDate)}', style: TextStyle(
                              fontSize: 11,
                              color: isExpired ? Colors.red : Colors.black45,
                              fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                            )),
                            if (isExpired)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF9575CD),
        onPressed: () async {
          final added = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetContext) => AddItemBottomSheet(
              onAdd: (item) {
                Navigator.pop(sheetContext, item);
              },
            ),
          );
          if (added != null) {
            viewModel.addItem(added);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}

class AddItemBottomSheet extends StatefulWidget {
  final PantryItemModel? initialItem;
  final Function(PantryItemModel)? onAdd;
  const AddItemBottomSheet({Key? key, this.initialItem, this.onAdd}) : super(key: key);

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  String? _expiryDateError;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity != null
          ? (item!.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString())
          : ''
    );
    _unitController = TextEditingController(text: item?.unit ?? '');
    _purchaseDate = item?.purchaseDate ?? DateTime.now();
    _expiryDate = item?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Thêm/Cập nhật mặt hàng', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên nguyên liệu'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Số lượng'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^(?!0(?![.]))[0-9]*\.?[0-9]*')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nhập số lượng';
                  if (v.contains(' ') || v.contains('-')) return 'Chỉ nhập số dương, không dấu cách';
                  final d = double.tryParse(v);
                  if (d == null) return 'Nhập số hợp lệ';
                  if (d <= 0) return 'Số lượng phải > 0';
                  return null;
                },
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Đơn vị'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[A-Za-zÀ-ỹà-ỹ\s]+')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nhập đơn vị';
                  if (v.startsWith(' ')) return 'Không nhập khoảng trắng ở đầu';
                  if (!RegExp(r'^[A-Za-zÀ-ỹà-ỹ\s]+$').hasMatch(v)) return 'Chỉ nhập chữ và khoảng trắng';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Ngày mua:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _purchaseDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _purchaseDate = picked);
                    },
                    child: Text(_purchaseDate != null ? PantryScreen.formatDate(_purchaseDate!) : 'Chọn'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('HSD:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        if (_purchaseDate != null && picked.isBefore(_purchaseDate!)) {
                          setState(() {
                            _expiryDateError = 'Hạn sử dụng phải sau hoặc bằng ngày mua!';
                            _expiryDate = null;
                          });
                        } else {
                          setState(() {
                            _expiryDate = picked;
                            _expiryDateError = null;
                          });
                        }
                      }
                    },
                    child: Text(_expiryDate != null ? PantryScreen.formatDate(_expiryDate!) : 'Chọn'),
                  ),
                ],
              ),
              if (_expiryDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _expiryDateError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() != true) return;
                  if (_purchaseDate == null || _expiryDate == null) return;
                  if (_expiryDateError != null) return;
                  // Validate lại trước khi lưu (phòng trường hợp sửa ngày mua hoặc HSD)
                  if (_expiryDate!.isBefore(_purchaseDate!)) {
                    setState(() {
                      _expiryDateError = 'Hạn sử dụng phải sau hoặc bằng ngày mua!';
                    });
                    return;
                  }
                  final item = PantryItemModel(
                    name: _nameController.text.trim(),
                    quantity: double.parse(_quantityController.text),
                    unit: _unitController.text.trim(),
                    purchaseDate: _purchaseDate!,
                    expiryDate: _expiryDate!,
                  );
                  widget.onAdd?.call(item);
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
