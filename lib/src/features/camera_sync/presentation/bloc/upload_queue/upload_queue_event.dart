import 'package:equatable/equatable.dart';

import '../../../domain/entities/upload_item.dart';

sealed class UploadQueueEvent extends Equatable {
  const UploadQueueEvent();

  @override
  List<Object?> get props => [];
}

class UploadQueueInitialized extends UploadQueueEvent {
  const UploadQueueInitialized();
}

class UploadQueueBatchEnqueued extends UploadQueueEvent {
  const UploadQueueBatchEnqueued({
    required this.filePaths,
    this.startUpload = true,
  });

  final List<String> filePaths;
  final bool startUpload;

  @override
  List<Object?> get props => [filePaths, startUpload];
}

class UploadQueueProcessRequested extends UploadQueueEvent {
  const UploadQueueProcessRequested({
    this.silent = false,
    this.fromAutoRetry = false,
  });

  final bool silent;
  final bool fromAutoRetry;

  @override
  List<Object?> get props => [silent, fromAutoRetry];
}

class UploadQueueItemsUpdated extends UploadQueueEvent {
  const UploadQueueItemsUpdated(this.items);

  final List<UploadItem> items;

  @override
  List<Object?> get props => [items];
}

class UploadQueueNetworkChanged extends UploadQueueEvent {
  const UploadQueueNetworkChanged(this.isOnline);

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}

class UploadQueueRefreshed extends UploadQueueEvent {
  const UploadQueueRefreshed();
}

class UploadQueueAppResumed extends UploadQueueEvent {
  const UploadQueueAppResumed();
}

class UploadQueueMessageCleared extends UploadQueueEvent {
  const UploadQueueMessageCleared();
}
