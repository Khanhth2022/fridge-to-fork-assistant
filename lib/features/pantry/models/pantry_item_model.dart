class PantryItemModel {
  String name;
  double quantity;
  String unit;
  DateTime purchaseDate;
  DateTime expiryDate;

  PantryItemModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    required this.expiryDate,
  });
}
