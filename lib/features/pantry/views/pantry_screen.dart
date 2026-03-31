import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../view_models/pantry_view_model.dart';
import '../models/pantry_item_model.dart';
import 'add_item_bottom_sheet.dart';
import 'scanned_items_review_sheet.dart';
import '../../../core/widgets/notification_test_screen.dart';
import '../../../core/services/scanner/scanner_service.dart';
import 'receipt_scanner_screen.dart';
import '../../../features/auth/view_models/auth_view_model.dart';
import '../../../features/auth/views/login_screen.dart';
import '../../../core/services/sync/sync_service.dart';

class PantryScreen extends StatelessWidget {
  Future<void> _openManualAddSheet(
    BuildContext context,
    PantryViewModel viewModel,
  ) async {
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
  }

  Future<void> _openReceiptScanner(
    BuildContext context,
    PantryViewModel viewModel,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Provider<ScannerService>(
          create: (_) => ScannerService(),
          child: ReceiptScannerScreen(
            onApplyIngredients: (ingredients) async {
              await _handleScannedIngredients(context, viewModel, ingredients);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleScannedIngredients(
    BuildContext context,
    PantryViewModel viewModel,
    List<String> ingredients,
  ) async {
    final normalizedIngredients = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedIngredients.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nguyên liệu hợp lệ từ ảnh.')),
      );
      return;
    }

    final items = await showModalBottomSheet<List<PantryItemModel>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          ScannedItemsReviewSheet(ingredients: normalizedIngredients),
    );

    if (!context.mounted || items == null || items.isEmpty) {
      return;
    }

    int addedCount = 0;
    int duplicateCount = 0;
    for (final item in items) {
      final success = await viewModel.addItem(item);
      if (success) {
        addedCount++;
      } else {
        duplicateCount++;
      }
    }

    if (!context.mounted) {
      return;
    }

    final message = duplicateCount > 0
        ? 'Đã thêm $addedCount nguyên liệu, bỏ qua $duplicateCount mục trùng tên.'
        : 'Đã thêm $addedCount nguyên liệu vào kho.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddOptions(
    BuildContext context,
    PantryViewModel viewModel,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: const Text('Thêm thủ công'),
                subtitle: const Text('Nhập nguyên liệu bằng form'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openManualAddSheet(context, viewModel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Quét hóa đơn'),
                subtitle: const Text('OCR + Barcode để gợi ý nguyên liệu'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openReceiptScanner(context, viewModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpiryAlert(PantryViewModel viewModel) {
    final now = DateTime.now();
    final expiringItems = viewModel.items.where((item) {
      final daysLeft = item.expiryDate
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
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
              Text(
                'Cảnh báo hạn sử dụng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...expiringItems.map((item) {
            final daysLeft = item.expiryDate
                .difference(DateTime(now.year, now.month, now.day))
                .inDays;
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

  Future<void> _showAccountMenu(
    BuildContext context,
    AuthViewModel authViewModel,
    SyncService syncService,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            if (authVM.isLoggedIn) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tài khoản',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Email: ${authVM.userEmail ?? ""}'),
                          const SizedBox(height: 4),
                          Text('Trạng thái: Đã đăng nhập'),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: const Text('Sao lưu ngay'),
                      subtitle: const Text('Đẩy dữ liệu lên cloud'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        _performBackup(context, syncService);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: const Text('Khôi phục từ cloud'),
                      subtitle: const Text('Kéo dữ liệu từ cloud về'),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        _performRestore(context, syncService);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận đăng xuất'),
                            content: const Text(
                              'Dữ liệu local vẫn được lưu giữ. Bạn có chắc muốn đăng xuất?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await authVM.logout();
                        }
                      },
                    ),
                  ],
                ),
              );
            } else {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Đăng nhập / Đăng ký'),
                      subtitle: const Text('Sao lưu dữ liệu lên cloud'),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _performBackup(
    BuildContext context,
    SyncService syncService,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đang sao lưu...')));

      await syncService.backupNow();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Sao lưu thành công'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi sao lưu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _performRestore(
    BuildContext context,
    SyncService syncService,
  ) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đang khôi phục...')));

      await syncService.restoreFromCloud();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Khôi phục thành công'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khôi phục: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PantryViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final syncService = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tủ bếp'),
        backgroundColor: const Color(0xFF9575CD),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Tài khoản',
                icon: const Icon(Icons.account_circle),
                onPressed: () {
                  _showAccountMenu(context, authViewModel, syncService);
                },
              ),
              if (authViewModel.isLoggedIn)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Test notification',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationTestScreen(),
                ),
              );
            },
          ),
        ],
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
                final daysLeft = item.expiryDate
                    .difference(DateTime(now.year, now.month, now.day))
                    .inDays;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Số lượng: ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.black38,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Ngày mua: ${PantryScreen.formatDate(item.purchaseDate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                    size: 18,
                                  ),
                                  tooltip: 'Cập nhật',
                                  onPressed: () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (sheetContext) =>
                                          AddItemBottomSheet(
                                            initialItem: item,
                                            onAdd: (updatedItem) async {
                                              return await viewModel.updateItem(
                                                item.itemId,
                                                updatedItem,
                                              );
                                            },
                                          ),
                                    );
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    if (value == 'half') {
                                      final current = item;
                                      double newQty = (current.quantity / 2);
                                      if (newQty % 1 == 0) {
                                        newQty = newQty.toInt().toDouble();
                                      } else {
                                        newQty = double.parse(
                                          newQty.toStringAsFixed(1),
                                        );
                                      }
                                      if (newQty > 0) {
                                        await viewModel.updateItem(
                                          item.itemId,
                                          PantryItemModel(
                                            name: current.name,
                                            quantity: newQty,
                                            unit: current.unit,
                                            purchaseDate: current.purchaseDate,
                                            expiryDate: current.expiryDate,
                                            itemId: item.itemId,
                                          ),
                                        );
                                      } else {
                                        await viewModel.deleteItem(item.itemId);
                                      }
                                    } else if (value == 'all') {
                                      await viewModel.deleteItem(item.itemId);
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Xác nhận'),
                                          content: Text(
                                            'Bạn có chắc muốn xóa nguyên liệu "${item.name}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text(
                                                'Xóa',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await viewModel.deleteItem(item.itemId);
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
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'HSD: ${PantryScreen.formatDate(item.expiryDate)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isExpired ? Colors.red : Colors.black45,
                                fontWeight: isExpired
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isExpired)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 14,
                                ),
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
          await _showAddOptions(context, viewModel);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
