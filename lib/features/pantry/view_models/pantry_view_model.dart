import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';
import '../pantry_repository.dart';
import '../../../core/services/notification/expiry_notification_service.dart';

class PantryViewModel extends ChangeNotifier {
  final PantryRepository _repository = PantryRepository();
  List<PantryItemModel> items = [];

  PantryViewModel() {
    loadItems();
  }

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
    await _repository.addItem(item);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  Future<bool> updateItem(int index, PantryItemModel newItem) async {
    final normalizedName = newItem.name.trim().toLowerCase();
    // Bỏ qua chính item đang sửa
    final exists = items.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.name.trim().toLowerCase() == normalizedName,
    );
    if (exists) {
      return false;
    }
    await _repository.updateItem(index, newItem);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  Future<void> deleteItem(int index) async {
    await _repository.deleteItem(index);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadItems();
  }
}
