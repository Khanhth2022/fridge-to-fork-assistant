import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../view_models/pantry_view_model.dart';
import '../models/pantry_item_model.dart';
import 'add_item_bottom_sheet.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tủ bếp'),
        backgroundColor: const Color(0xFF9575CD),
      ),
      body: viewModel.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inbox, size: 80, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có nguyên liệu nào!',
                    style: TextStyle(fontSize: 18, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
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
                final now = DateTime.now();
                final daysLeft = item.expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
                final isExpired = daysLeft < 0;
                final isExpiringSoon = daysLeft >= 0 && daysLeft <= 2;
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
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (sheetContext) => AddItemBottomSheet(
                                        initialItem: item,
                                        onAdd: (updatedItem) async {
                                          final realIndex = viewModel.items.indexOf(item);
                                          if (realIndex != -1) {
                                            return await viewModel.updateItem(realIndex, updatedItem);
                                          }
                                          return false;
                                        },
                                      ),
                                    );
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
                                      if (newQty % 1 == 0) {
                                        newQty = newQty.toInt().toDouble();
                                      } else {
                                        newQty = double.parse(newQty.toStringAsFixed(1));
                                      }
                                      if (newQty > 0) {
                                        await viewModel.updateItem(realIndex, PantryItemModel(
                                          name: current.name,
                                          quantity: newQty,
                                          unit: current.unit,
                                          purchaseDate: current.purchaseDate,
                                          expiryDate: current.expiryDate,
                                        ));
                                      } else {
                                        await viewModel.deleteItem(realIndex);
                                      }
                                    } else if (value == 'all') {
                                      await viewModel.deleteItem(realIndex);
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
                                        await viewModel.deleteItem(realIndex);
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
        backgroundColor: const Color(0xFF9575CD),
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (sheetContext) => AddItemBottomSheet(
              onAdd: (item) async {
                final success = await viewModel.addItem(item);
                return success;
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}

