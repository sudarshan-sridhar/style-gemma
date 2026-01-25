// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wardrobe_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WardrobeCategoryAdapter extends TypeAdapter<WardrobeCategory> {
  @override
  final int typeId = 0;

  @override
  WardrobeCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WardrobeCategory.tops;
      case 1:
        return WardrobeCategory.bottoms;
      case 2:
        return WardrobeCategory.shoes;
      case 3:
        return WardrobeCategory.accessories;
      default:
        return WardrobeCategory.tops;
    }
  }

  @override
  void write(BinaryWriter writer, WardrobeCategory obj) {
    switch (obj) {
      case WardrobeCategory.tops:
        writer.writeByte(0);
        break;
      case WardrobeCategory.bottoms:
        writer.writeByte(1);
        break;
      case WardrobeCategory.shoes:
        writer.writeByte(2);
        break;
      case WardrobeCategory.accessories:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardrobeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
