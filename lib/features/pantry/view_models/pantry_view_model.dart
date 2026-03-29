import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';
import '../pantry_repository.dart';

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
		       final exists = items.any((e) => e.name.trim().toLowerCase() == normalizedName);
		       if (exists) {
			       return false;
		       }
		       await _repository.addItem(item);
		       await loadItems();
		       return true;
	       }

	Future<void> updateItem(int index, PantryItemModel newItem) async {
		await _repository.updateItem(index, newItem);
		await loadItems();
	}

	Future<void> deleteItem(int index) async {
		await _repository.deleteItem(index);
		await loadItems();
	}

	Future<void> clearAll() async {
		await _repository.clearAll();
		await loadItems();
	}
}
