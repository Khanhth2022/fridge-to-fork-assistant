import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/pantry_view_model.dart';
import '../models/pantry_item_model.dart';
import 'add_item_bottom_sheet.dart';
import 'scanned_items_review_sheet.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/services/scanner/scanner_service.dart';
import '../../../core/services/sync/sync_service.dart';
import 'receipt_scanner_screen.dart';
import '../../../features/auth/view_models/auth_view_model.dart';
import '../../../features/auth/views/login_screen.dart';
import '../../../features/recipes/views/recipe_list_screen.dart';

class PantryScreen extends StatelessWidget {
  Future<RestoreConflictResolution?> _askConflictResolution(
    BuildContext context,
    int conflictCount,
  ) async {
    return showDialog<RestoreConflictResolution>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Phát hiện xung đột dữ liệu'),
          content: Text(
            'Có $conflictCount mục khác nhau giữa máy và Firebase. Bạn muốn ưu tiên nguồn nào khi khôi phục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(RestoreConflictResolution.preferLocal),
              child: const Text('Giữ dữ liệu local'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(RestoreConflictResolution.preferCloud),
              child: const Text('Lấy dữ liệu Firebase'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runSyncAction({
    required BuildContext context,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    bool isDialogOpen = false;
    try {
      isDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await action();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (context.mounted) {
        String message = e.toString();
        if (message.toLowerCase().contains('not authenticated')) {
          message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (isDialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

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
        existingItemNames: viewModel.items.map((e) => e.name).toList(),
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
    final List<String> normalizedIngredients = ingredients
        .map((String ingredient) => ingredient.trim())
        .where((String ingredient) => ingredient.isNotEmpty)
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

    final List<PantryItemModel>? items =
        await showModalBottomSheet<List<PantryItemModel>>(
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
    for (final PantryItemModel item in items) {
      final bool success = await viewModel.addItem(item);
      if (success) {
        addedCount++;
      } else {
        duplicateCount++;
      }
    }

    if (!context.mounted) {
      return;
    }

    final String message = duplicateCount > 0
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

  Widget _buildExpiryAlert(BuildContext context, PantryViewModel viewModel) {
    final now = DateTime.now();
    final expiringItems = viewModel.items.where((item) {
      final daysLeft = item.expiryDate
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      return daysLeft >= 0 && daysLeft <= 2;
    }).toList();
    if (expiringItems.isEmpty) return const SizedBox.shrink();

    Future<void> showExpiringItemsSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nguyên liệu sắp hết hạn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: expiringItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final item = expiringItems[index];
                        final daysLeft = item.expiryDate
                            .difference(DateTime(now.year, now.month, now.day))
                            .inDays;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            daysLeft == 0
                                ? 'Hết hạn hôm nay'
                                : 'Còn $daysLeft ngày đến hạn',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD), // Xanh nhạt
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF90CAF9)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: showExpiringItemsSheet,
        child: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.black54, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cảnh báo hạn sử dụng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PantryViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final List<String> pantryNames = viewModel.items
        .map((PantryItemModel e) => e.name)
        .where((String name) => name.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tủ bếp'),
        backgroundColor: const Color(0xFF9575CD),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Tài khoản',
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.account_circle_outlined),
                if (authViewModel.isLoggedIn)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
            onSelected: (value) async {
              if (value == 'login') {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else if (value == 'logout') {
                await authViewModel.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
                }
              } else if (value == 'backup') {
                if (!authViewModel.isLoggedIn) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng đăng nhập để sao lưu dữ liệu'),
                      ),
                    );
                  }
                  return;
                }

                final SyncService syncService = context.read<SyncService>();
                await _runSyncAction(
                  context: context,
                  action: () async {
                    await syncService.backupNow();
                    await syncService.backupMealPlansNow();
                    await syncService.backupShoppingListsNow();
                  },
                  successMessage: 'Sao lưu Firebase thành công',
                );
              } else if (value == 'restore') {
                if (!authViewModel.isLoggedIn) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vui lòng đăng nhập để khôi phục dữ liệu',
                        ),
                      ),
                    );
                  }
                  return;
                }

                final SyncService syncService = context.read<SyncService>();
                final conflicts = await syncService.getRestoreConflicts();
                RestoreConflictResolution? resolution;

                if (conflicts.isNotEmpty) {
                  if (!context.mounted) {
                    return;
                  }
                  resolution = await _askConflictResolution(
                    context,
                    conflicts.length,
                  );

                  if (resolution == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã hủy khôi phục dữ liệu'),
                        ),
                      );
                    }
                    return;
                  }
                }

                if (!context.mounted) {
                  return;
                }

                await _runSyncAction(
                  context: context,
                  action: () async {
                    await syncService.restoreFromCloud(
                      conflictResolution:
                          resolution ?? RestoreConflictResolution.preferLocal,
                    );
                    await syncService.restoreMealPlansFromCloud();
                    await syncService.restoreShoppingListsFromCloud();
                    await viewModel.loadItems();
                  },
                  successMessage: 'Khôi phục dữ liệu từ Firebase thành công',
                );
              }
            },
            itemBuilder: (context) {
              if (authViewModel.isLoggedIn) {
                return [
                  PopupMenuItem<String>(
                    enabled: false,
                    value: 'email',
                    child: Text(authViewModel.userEmail ?? 'Đã đăng nhập'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'backup',
                    child: Text('Sao lưu lên Firebase'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'restore',
                    child: Text('Khôi phục từ Firebase'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Đăng xuất'),
                  ),
                ];
              }

              return const [
                PopupMenuItem<String>(
                  value: 'login',
                  child: Text('Đăng nhập / Đăng ký'),
                ),
              ];
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
                  return _buildExpiryAlert(context, viewModel);
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
                                            existingItemNames: viewModel.items
                                                .map((e) => e.name)
                                                .toList(),
                                            onAdd: (updatedItem) async {
                                              final realIndex = viewModel.items
                                                  .indexOf(item);
                                              if (realIndex != -1) {
                                                return await viewModel
                                                    .updateItem(
                                                      realIndex,
                                                      updatedItem,
                                                    );
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
                                    final realIndex = viewModel.items.indexOf(
                                      item,
                                    );
                                    if (realIndex == -1) return;
                                    if (value == 'half') {
                                      final current =
                                          viewModel.items[realIndex];
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
                                          realIndex,
                                          PantryItemModel(
                                            name: current.name,
                                            quantity: newQty,
                                            unit: current.unit,
                                            purchaseDate: current.purchaseDate,
                                            expiryDate: current.expiryDate,
                                          ),
                                        );
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'recipe_suggestion_fab',
              backgroundColor: const Color(0xFF4CAF50),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => RecipeListScreen(
                      pantryIngredients: pantryNames,
                      isPantrySuggestionWindow: true,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.lightbulb_outline),
            ),
            FloatingActionButton(
              heroTag: 'add_ingredient_fab',
              backgroundColor: const Color(0xFF9575CD),
              onPressed: () async {
                await _showAddOptions(context, viewModel);
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}
