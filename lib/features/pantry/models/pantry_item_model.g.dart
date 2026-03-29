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
      quantity: fields[1] as double,
      unit: fields[2] as String,
      purchaseDate: fields[3] as DateTime,
      expiryDate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PantryItemModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.purchaseDate)
      ..writeByte(4)
      ..write(obj.expiryDate);
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
