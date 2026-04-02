import 'package:hive/hive.dart';
import 'models/pantry_item_model.dart';

class PantryRepository {
  static const String boxName = 'pantry_items';

  Future<Box<PantryItemModel>> _openBox() async {
    return await Hive.openBox<PantryItemModel>(boxName);
  }

  Future<List<PantryItemModel>> getAllItems() async {
    final box = await _openBox();
    // Filter out soft-deleted items
    return box.values.where((item) => item.deletedAtUtcMs == null).toList();
  }

  Future<void> addItem(PantryItemModel item) async {
    final box = await _openBox();
    // Mark as dirty since it's a new local item
    final newItem = item.copyWith(isDirty: true);
    await box.add(newItem);
  }

  Future<void> updateItem(String itemId, PantryItemModel item) async {
    final box = await _openBox();
    final allItems = box.values.toList();

    final index = allItems.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      final updatedItem = item.copyWith(
        isDirty: true,
        updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      );
      await box.putAt(index, updatedItem);
    }
  }

  // Soft delete - mark as deleted but keep in Hive
  Future<void> deleteItem(String itemId) async {
    final box = await _openBox();
    final allItems = box.values.toList();

    final index = allItems.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      final item = box.getAt(index)!;
      final deletedItem = item.copyWith(
        deletedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
        updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
        isDirty: true,
      );
      await box.putAt(index, deletedItem);
    }
  }

  // Hard delete (for cleanup)
  Future<void> hardDeleteItem(String itemId) async {
    final box = await _openBox();
    final allItems = box.values.toList();

    final index = allItems.indexWhere((i) => i.itemId == itemId);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  // Get item by ID
  Future<PantryItemModel?> getItemById(String itemId) async {
    final box = await _openBox();
    final items = box.values.toList();

    try {
      return items.firstWhere(
        (item) => item.itemId == itemId && item.deletedAtUtcMs == null,
      );
    } catch (e) {
      return null;
    }
  }

  // Count dirty items (not synced)
  Future<int> getDirtyItemCount() async {
    final box = await _openBox();
    return box.values.where((item) => item.isDirty).length;
  }
}
