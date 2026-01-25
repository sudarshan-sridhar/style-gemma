// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wardrobe_photo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WardrobePhotoAdapter extends TypeAdapter<WardrobePhoto> {
  @override
  final int typeId = 5;

  @override
  WardrobePhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WardrobePhoto(
      localPath: fields[0] as String,
      remoteUrl: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WardrobePhoto obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.localPath)
      ..writeByte(1)
      ..write(obj.remoteUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardrobePhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
