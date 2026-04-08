import 'package:equatable/equatable.dart';

import 'upload_status.dart';

class UploadItem extends Equatable {
  const UploadItem({
    required this.id,
    required this.batchId,
    required this.filePath,
    required this.status,
    required this.progress,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });

  final String id;
  final String batchId;
  final String filePath;
  final UploadStatus status;
  final double progress;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;

  UploadItem copyWith({
    String? id,
    String? batchId,
    String? filePath,
    UploadStatus? status,
    double? progress,
    int? retryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return UploadItem(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    batchId,
    filePath,
    status,
    progress,
    retryCount,
    createdAt,
    updatedAt,
    errorMessage,
  ];
}
