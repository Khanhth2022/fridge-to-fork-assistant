import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';
import '../pantry_repository.dart';
import '../../../core/services/notification/expiry_notification_service.dart';

class PantryViewModel extends ChangeNotifier {
  final PantryRepository _repository = PantryRepository();
  List<PantryItemModel> items = [];
  bool _isSyncing = false;

  PantryViewModel() {
    loadItems();
  }

  bool get isSyncing => _isSyncing;

  Future<void> loadItems() async {
    items = await _repository.getAllItems();
    notifyListeners();
  }

  Future<bool> addItem(PantryItemModel item) async {
    // Kiểm tra trùng tên (không phân biệt hoa thường, loại bỏ khoảng trắng)
    final normalizedName = item.name.trim().toLowerCase();
    final exists = items.any(
      (e) => e.name.trim().toLowerCase() == normalizedName,
    );
    if (exists) {
      return false;
    }

    // Create new item with current timestamp
    final newItem = item.copyWith(
      updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      isDirty: true,
    );

    await _repository.addItem(newItem);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  Future<bool> updateItem(String itemId, PantryItemModel newItem) async {
    final normalizedName = newItem.name.trim().toLowerCase();
    // Bỏ qua chính item đang sửa
    final exists = items.any(
      (item) =>
          item.itemId != itemId &&
          item.name.trim().toLowerCase() == normalizedName,
    );
    if (exists) {
      return false;
    }

    // Update with new timestamp
    final updatedItem = newItem.copyWith(
      itemId: itemId,
      updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      isDirty: true,
    );

    await _repository.updateItem(itemId, updatedItem);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteItem(itemId);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadItems();
  }

  // Get number of items not yet synced
  Future<int> getDirtyItemCount() async {
    return await _repository.getDirtyItemCount();
  }

  // Set syncing state
  void setSyncingState(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  // Mark all items as synced after successful backup
  Future<void> markItemsAsSynced() async {
    // Syncing is handled by SyncService
    // Just reload items after sync completes
    await loadItems();
  }
}
