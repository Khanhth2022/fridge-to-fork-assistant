import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
  @HiveField(5)
  String itemId; // Unique identifier for sync
  @HiveField(6)
  int updatedAtUtcMs; // Timestamp of last update in milliseconds UTC
  @HiveField(7)
  int? deletedAtUtcMs; // Soft delete timestamp, null if not deleted
  @HiveField(8)
  String? deviceId; // Device that made the last change
  @HiveField(9)
  bool isDirty; // Not yet synced to cloud

  PantryItemModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    required this.expiryDate,
    String? itemId,
    int? updatedAtUtcMs,
    this.deletedAtUtcMs,
    this.deviceId,
    this.isDirty = true,
  }) : itemId = itemId ?? const Uuid().v4(),
       updatedAtUtcMs = updatedAtUtcMs ?? DateTime.now().millisecondsSinceEpoch;

  // Create a copy with updated fields
  PantryItemModel copyWith({
    String? name,
    double? quantity,
    String? unit,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? itemId,
    int? updatedAtUtcMs,
    int? deletedAtUtcMs,
    String? deviceId,
    bool? isDirty,
  }) {
    return PantryItemModel(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      itemId: itemId ?? this.itemId,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      deviceId: deviceId ?? this.deviceId,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
