import 'package:hive/hive.dart';

part 'pantry_item_model.g.dart';

@HiveType(typeId: 0)
class PantryItemModel {
  @HiveField(0)
  String name;
  @HiveField(1)
  double quantity;
  @HiveField(2)
  String unit;
  @HiveField(3)
  DateTime purchaseDate;
  @HiveField(4)
  DateTime expiryDate;

  PantryItemModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    required this.expiryDate,
  });
}
