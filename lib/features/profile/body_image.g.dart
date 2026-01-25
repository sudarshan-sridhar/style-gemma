// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyImageAdapter extends TypeAdapter<BodyImage> {
  @override
  final int typeId = 2;

  @override
  BodyImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyImage(
      position: fields[0] as BodyImagePosition,
      localPath: fields[1] as String,
      remoteUrl: fields[2] as String?,
      uploadState: fields[3] as BodyUploadState?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyImage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.position)
      ..writeByte(1)
      ..write(obj.localPath)
      ..writeByte(2)
      ..write(obj.remoteUrl)
      ..writeByte(3)
      ..write(obj.uploadState);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BodyImagePositionAdapter extends TypeAdapter<BodyImagePosition> {
  @override
  final int typeId = 3;

  @override
  BodyImagePosition read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BodyImagePosition.front;
      case 1:
        return BodyImagePosition.side;
      case 2:
        return BodyImagePosition.back;
      default:
        return BodyImagePosition.front;
    }
  }

  @override
  void write(BinaryWriter writer, BodyImagePosition obj) {
    switch (obj) {
      case BodyImagePosition.front:
        writer.writeByte(0);
        break;
      case BodyImagePosition.side:
        writer.writeByte(1);
        break;
      case BodyImagePosition.back:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyImagePositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BodyUploadStateAdapter extends TypeAdapter<BodyUploadState> {
  @override
  final int typeId = 7;

  @override
  BodyUploadState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BodyUploadState.localOnly;
      case 1:
        return BodyUploadState.uploading;
      case 2:
        return BodyUploadState.uploaded;
      case 3:
        return BodyUploadState.failed;
      default:
        return BodyUploadState.localOnly;
    }
  }

  @override
  void write(BinaryWriter writer, BodyUploadState obj) {
    switch (obj) {
      case BodyUploadState.localOnly:
        writer.writeByte(0);
        break;
      case BodyUploadState.uploading:
        writer.writeByte(1);
        break;
      case BodyUploadState.uploaded:
        writer.writeByte(2);
        break;
      case BodyUploadState.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyUploadStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
