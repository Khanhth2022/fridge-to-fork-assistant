import 'package:hive/hive.dart';
import 'models/pantry_item_model.dart';

class PantryRepository {
  static const String boxName = 'pantry_items';

  Future<Box<PantryItemModel>> _openBox() async {
    return await Hive.openBox<PantryItemModel>(boxName);
  }

  Future<List<PantryItemModel>> getAllItems() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> addItem(PantryItemModel item) async {
    final box = await _openBox();
    await box.add(item);
  }

  Future<void> updateItem(int index, PantryItemModel item) async {
    final box = await _openBox();
    await box.putAt(index, item);
  }

  Future<void> deleteItem(int index) async {
    final box = await _openBox();
    await box.deleteAt(index);
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
