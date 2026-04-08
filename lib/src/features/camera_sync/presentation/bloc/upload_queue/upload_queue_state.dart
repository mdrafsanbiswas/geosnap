import 'package:equatable/equatable.dart';

import '../../../domain/entities/upload_item.dart';
import '../../../domain/entities/upload_status.dart';

enum UploadQueueViewStatus { initial, loading, ready, uploading }

class UploadQueueState extends Equatable {
  const UploadQueueState({
    this.status = UploadQueueViewStatus.initial,
    this.items = const [],
    this.isOnline = true,
    this.message,
    this.lastSyncedAt,
  });

  final UploadQueueViewStatus status;
  final List<UploadItem> items;
  final bool isOnline;
  final String? message;
  final DateTime? lastSyncedAt;

  int get totalCount => items.length;

  int get uploadedCount =>
      items.where((item) => item.status == UploadStatus.uploaded).length;

  int get pendingCount =>
      items.where((item) => item.status == UploadStatus.pending).length;

  int get uploadingCount =>
      items.where((item) => item.status == UploadStatus.uploading).length;

  int get failedCount =>
      items.where((item) => item.status == UploadStatus.failed).length;

  int get waitingForNetworkCount =>
      items
          .where((item) => item.status == UploadStatus.waitingForNetwork)
          .length;

  int get retryableCount =>
      items.where((item) => item.status.canRetry).length;

  int get totalBatchCount => items.map((item) => item.batchId).toSet().length;

  double get overallProgress {
    if (items.isEmpty) {
      return 0;
    }

    final progress = items.fold<double>(
      0,
      (sum, item) => sum + item.progress.clamp(0, 1),
    );
    return progress / items.length;
  }

  UploadQueueState copyWith({
    UploadQueueViewStatus? status,
    List<UploadItem>? items,
    bool? isOnline,
    String? message,
    DateTime? lastSyncedAt,
    bool clearMessage = false,
  }) {
    return UploadQueueState(
      status: status ?? this.status,
      items: items ?? this.items,
      isOnline: isOnline ?? this.isOnline,
      message: clearMessage ? null : message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [status, items, isOnline, message, lastSyncedAt];
}
