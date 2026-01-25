import 'package:hive/hive.dart';

part 'body_image.g.dart';

@HiveType(typeId: 2)
class BodyImage {
  @HiveField(0)
  final BodyImagePosition position;

  @HiveField(1)
  final String localPath;

  @HiveField(2)
  final String? remoteUrl;

  @HiveField(3)
  final BodyUploadState uploadState;

  BodyImage({
    required this.position,
    required this.localPath,
    this.remoteUrl,
    BodyUploadState? uploadState,
  }) : uploadState = uploadState ?? BodyUploadState.localOnly;

  BodyImage copyWith({
    String? localPath,
    String? remoteUrl,
    BodyUploadState? uploadState,
  }) {
    return BodyImage(
      position: position,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      uploadState: uploadState ?? this.uploadState,
    );
  }
}

@HiveType(typeId: 3)
enum BodyImagePosition {
  @HiveField(0)
  front,
  @HiveField(1)
  side,
  @HiveField(2)
  back,
}

// FIXED: unique typeId
@HiveType(typeId: 7)
enum BodyUploadState {
  @HiveField(0)
  localOnly,
  @HiveField(1)
  uploading,
  @HiveField(2)
  uploaded,
  @HiveField(3)
  failed,
}
