// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PantryItemModelAdapter extends TypeAdapter<PantryItemModel> {
  @override
  final int typeId = 0;

  @override
  PantryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PantryItemModel(
      name: fields[0] as String,
      quantity: (fields[1] as num).toDouble(),
      unit: fields[2] as String,
      purchaseDate: fields[3] as DateTime,
      expiryDate: fields[4] as DateTime,
      itemId: fields[5] as String?,
      updatedAtUtcMs: fields[6] as int?,
      deletedAtUtcMs: fields[7] as int?,
      deviceId: fields[8] as String?,
      isDirty: (fields[9] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, PantryItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.purchaseDate)
      ..writeByte(4)
      ..write(obj.expiryDate)
      ..writeByte(5)
      ..write(obj.itemId)
      ..writeByte(6)
      ..write(obj.updatedAtUtcMs)
      ..writeByte(7)
      ..write(obj.deletedAtUtcMs)
      ..writeByte(8)
      ..write(obj.deviceId)
      ..writeByte(9)
      ..write(obj.isDirty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PantryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
