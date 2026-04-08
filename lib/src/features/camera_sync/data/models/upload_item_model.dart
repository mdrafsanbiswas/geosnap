import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';

class UploadItemModel extends UploadItem {
  const UploadItemModel({
    required super.id,
    required super.batchId,
    required super.filePath,
    required super.status,
    required super.progress,
    required super.retryCount,
    required super.createdAt,
    required super.updatedAt,
    super.errorMessage,
  });

  factory UploadItemModel.fromEntity(UploadItem item) {
    return UploadItemModel(
      id: item.id,
      batchId: item.batchId,
      filePath: item.filePath,
      status: item.status,
      progress: item.progress,
      retryCount: item.retryCount,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      errorMessage: item.errorMessage,
    );
  }

  factory UploadItemModel.fromMap(Map<String, dynamic> map) {
    return UploadItemModel(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      filePath: map['file_path'] as String,
      status: _statusFromValue(map['status'] as String?),
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      retryCount: (map['retry_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'file_path': filePath,
      'status': status.name,
      'progress': progress,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'error_message': errorMessage,
    };
  }

  UploadItem toEntity() {
    return UploadItem(
      id: id,
      batchId: batchId,
      filePath: filePath,
      status: status,
      progress: progress,
      retryCount: retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      errorMessage: errorMessage,
    );
  }

  static UploadStatus _statusFromValue(String? value) {
    return UploadStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => UploadStatus.pending,
    );
  }
}
