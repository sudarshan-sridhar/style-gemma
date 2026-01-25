// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wardrobe_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WardrobeItemAdapter extends TypeAdapter<WardrobeItem> {
  @override
  final int typeId = 1;

  @override
  WardrobeItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WardrobeItem(
      name: fields[0] as String,
      category: fields[1] as WardrobeCategory,
      photos: (fields[2] as List).cast<WardrobePhoto>(),
      uploadState: fields[3] as UploadState?,
      isDeleted: fields[4] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, WardrobeItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.photos)
      ..writeByte(3)
      ..write(obj.uploadState)
      ..writeByte(4)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardrobeItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UploadStateAdapter extends TypeAdapter<UploadState> {
  @override
  final int typeId = 4;

  @override
  UploadState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UploadState.localOnly;
      case 1:
        return UploadState.uploading;
      case 2:
        return UploadState.uploaded;
      case 3:
        return UploadState.failed;
      default:
        return UploadState.localOnly;
    }
  }

  @override
  void write(BinaryWriter writer, UploadState obj) {
    switch (obj) {
      case UploadState.localOnly:
        writer.writeByte(0);
        break;
      case UploadState.uploading:
        writer.writeByte(1);
        break;
      case UploadState.uploaded:
        writer.writeByte(2);
        break;
      case UploadState.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
