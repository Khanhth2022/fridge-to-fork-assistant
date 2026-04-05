import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';
import '../pantry_repository.dart';
import '../../../core/services/notification/expiry_notification_service.dart';

class PantryViewModel extends ChangeNotifier {
  final PantryRepository _repository = PantryRepository();
  List<PantryItemModel> items = [];

  static const double _epsilon = 1e-6;

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
    final String itemId = items[index].itemId;
    final PantryItemModel updatedItem = newItem.copyWith(
      itemId: itemId,
      updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      isDirty: true,
    );
    await _repository.updateItem(itemId, updatedItem);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  Future<void> deleteItem(int index) async {
    final String itemId = items[index].itemId;
    await _repository.deleteItem(itemId);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
  }

  Future<bool> consumeItemQuantity({
    required int index,
    required double amount,
    String? amountUnit,
  }) async {
    if (index < 0 || index >= items.length || amount <= 0) {
      return false;
    }

    final PantryItemModel current = items[index];
    final String currentUnit = _normalizeUnit(current.unit);
    final String consumeUnit = _normalizeUnit(amountUnit ?? current.unit);

    double remainingQuantity;
    String remainingUnit = current.unit;

    if (_isMassUnit(currentUnit) && _isMassUnit(consumeUnit)) {
      final double currentInGrams = _toGrams(current.quantity, currentUnit);
      final double consumeInGrams = _toGrams(amount, consumeUnit);

      if (consumeInGrams > currentInGrams + _epsilon) {
        return false;
      }

      final double remainingInGrams = currentInGrams - consumeInGrams;
      if (remainingInGrams <= _epsilon) {
        await deleteItem(index);
        return true;
      }

      if (currentUnit == 'kg') {
        final double remainingInKg = remainingInGrams / 1000;
        if (remainingInKg < 1) {
          remainingQuantity = _roundQuantity(remainingInGrams, decimals: 2);
          remainingUnit = 'g';
        } else {
          remainingQuantity = _roundQuantity(remainingInKg, decimals: 3);
          remainingUnit = 'kg';
        }
      } else {
        remainingQuantity = _roundQuantity(remainingInGrams, decimals: 2);
        remainingUnit = 'g';
      }
    } else if (_isVolumeUnit(currentUnit) && _isVolumeUnit(consumeUnit)) {
      final double currentInMl = _toMilliliters(current.quantity, currentUnit);
      final double consumeInMl = _toMilliliters(amount, consumeUnit);

      if (consumeInMl > currentInMl + _epsilon) {
        return false;
      }

      final double remainingInMl = currentInMl - consumeInMl;
      if (remainingInMl <= _epsilon) {
        await deleteItem(index);
        return true;
      }

      if (currentUnit == 'lít') {
        final double remainingInLiters = remainingInMl / 1000;
        if (remainingInLiters < 1) {
          remainingQuantity = _roundQuantity(remainingInMl, decimals: 1);
          remainingUnit = 'ml';
        } else {
          remainingQuantity = _roundQuantity(remainingInLiters, decimals: 3);
          remainingUnit = 'lít';
        }
      } else {
        remainingQuantity = _roundQuantity(remainingInMl, decimals: 1);
        remainingUnit = 'ml';
      }
    } else {
      if (consumeUnit != currentUnit) {
        return false;
      }

      remainingQuantity = current.quantity - amount;
      if (remainingQuantity <= _epsilon) {
        await deleteItem(index);
        return true;
      }
      remainingQuantity = _roundQuantity(remainingQuantity, decimals: 3);
    }

    final PantryItemModel updated = current.copyWith(
      quantity: remainingQuantity,
      unit: remainingUnit,
      updatedAtUtcMs: DateTime.now().millisecondsSinceEpoch,
      isDirty: true,
    );

    await _repository.updateItem(current.itemId, updated);
    await loadItems();
    await ExpiryNotificationService.checkAndNotifyExpiringItems();
    return true;
  }

  bool _isMassUnit(String unit) {
    return unit == 'kg' || unit == 'g';
  }

  bool _isVolumeUnit(String unit) {
    return unit == 'ml' ||
        unit == 'lít' ||
        unit == 'tsp' ||
        unit == 'tbsp' ||
        unit == 'cup' ||
        unit == 'muỗng cà phê' ||
        unit == 'muỗng canh' ||
        unit == 'muỗng';
  }

  String _normalizeUnit(String rawUnit) {
    final String unit = rawUnit.trim().toLowerCase();
    switch (unit) {
      case 'l':
      case 'lit':
      case 'lít':
      case 'liter':
      case 'liters':
        return 'lít';
      case 'muong ca phe':
      case 'muỗng cà phê':
        return 'tsp';
      case 'muong canh':
      case 'muỗng canh':
      case 'muong':
      case 'muỗng':
        return 'tbsp';
      case 'teaspoon':
      case 'teaspoons':
        return 'tsp';
      case 'tablespoon':
      case 'tablespoons':
        return 'tbsp';
      default:
        return unit;
    }
  }

  double _toGrams(double amount, String unit) {
    if (unit == 'kg') {
      return amount * 1000;
    }
    return amount;
  }

  double _toMilliliters(double amount, String unit) {
    switch (unit) {
      case 'lít':
        return amount * 1000;
      case 'tsp':
        return amount * 5;
      case 'tbsp':
        return amount * 15;
      case 'cup':
        return amount * 240;
      default:
        return amount;
    }
  }

  double _roundQuantity(double value, {required int decimals}) {
    final String fixed = value.toStringAsFixed(decimals);
    return double.parse(fixed);
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadItems();
  }
}
