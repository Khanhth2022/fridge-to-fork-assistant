import 'package:flutter/material.dart';
import '../models/pantry_item_model.dart';

class PantryViewModel extends ChangeNotifier {
		void updateItem(int index, PantryItemModel newItem) {
			if (index >= 0 && index < items.length) {
				items[index] = newItem;
				notifyListeners();
			}
		}
	List<PantryItemModel> items = [];

	void initMockData() {
		if (items.isEmpty) {
			final now = DateTime.now();
			items = [
				PantryItemModel(
					name: 'Trứng',
					quantity: 10,
					unit: 'quả',
					purchaseDate: now.subtract(const Duration(days: 2)),
					expiryDate: now.add(const Duration(days: 5)),
				),
				PantryItemModel(
					name: 'Sữa',
					quantity: 2,
					unit: 'hộp',
					purchaseDate: now.subtract(const Duration(days: 1)),
					expiryDate: now.add(const Duration(days: 3)),
				),
			];
			notifyListeners();
		}
	}

	void addItem(PantryItemModel item) {
		items.add(item);
		notifyListeners();
	}

	void deleteItem(int index) {
		items.removeAt(index);
		notifyListeners();
	}
}
