import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/upload_item.dart';
import '../../../domain/entities/upload_status.dart';
import '../../../domain/usecases/enqueue_upload_batch.dart';
import '../../../domain/usecases/get_upload_items.dart';
import '../../../domain/usecases/has_network_access.dart';
import '../../../domain/usecases/process_pending_uploads.dart';
import '../../../domain/usecases/watch_network_access.dart';
import 'upload_queue_event.dart';
import 'upload_queue_state.dart';

class UploadQueueBloc extends Bloc<UploadQueueEvent, UploadQueueState> {
  UploadQueueBloc({
    required GetUploadItemsUseCase getUploadItems,
    required EnqueueUploadBatchUseCase enqueueUploadBatch,
    required ProcessPendingUploadsUseCase processPendingUploads,
    required HasNetworkAccessUseCase hasNetworkAccess,
    required WatchNetworkAccessUseCase watchNetworkAccess,
  }) : _getUploadItems = getUploadItems,
       _enqueueUploadBatch = enqueueUploadBatch,
       _processPendingUploads = processPendingUploads,
       _hasNetworkAccess = hasNetworkAccess,
       _watchNetworkAccess = watchNetworkAccess,
       super(const UploadQueueState()) {
    on<UploadQueueInitialized>(_onInitialized);
    on<UploadQueueBatchEnqueued>(_onBatchEnqueued);
    on<UploadQueueProcessRequested>(_onProcessRequested);
    on<UploadQueueItemsUpdated>(_onItemsUpdated);
    on<UploadQueueNetworkChanged>(_onNetworkChanged);
    on<UploadQueueRefreshed>(_onRefreshed);
    on<UploadQueueMessageCleared>(_onMessageCleared);
  }

  final GetUploadItemsUseCase _getUploadItems;
  final EnqueueUploadBatchUseCase _enqueueUploadBatch;
  final ProcessPendingUploadsUseCase _processPendingUploads;
  final HasNetworkAccessUseCase _hasNetworkAccess;
  final WatchNetworkAccessUseCase _watchNetworkAccess;

  StreamSubscription<bool>? _networkSubscription;
  bool _isProcessing = false;

  Future<void> _onInitialized(
    UploadQueueInitialized event,
    Emitter<UploadQueueState> emit,
  ) async {
    emit(
      state.copyWith(status: UploadQueueViewStatus.loading, clearMessage: true),
    );

    final items = await _getUploadItems();
    final isOnline = await _hasNetworkAccess();

    emit(
      state.copyWith(
        status: UploadQueueViewStatus.ready,
        items: List<UploadItem>.unmodifiable(items),
        isOnline: isOnline,
      ),
    );

    await _networkSubscription?.cancel();
    _networkSubscription = _watchNetworkAccess().listen(
      (isNetworkOnline) => add(UploadQueueNetworkChanged(isNetworkOnline)),
    );

    if (isOnline && _hasRetryableItems(items)) {
      add(const UploadQueueProcessRequested(silent: true, fromAutoRetry: true));
    }
  }

  Future<void> _onBatchEnqueued(
    UploadQueueBatchEnqueued event,
    Emitter<UploadQueueState> emit,
  ) async {
    if (event.filePaths.isEmpty) {
      emit(
        state.copyWith(
          message:
              'Capture at least one photo before creating an upload batch.',
        ),
      );
      return;
    }

    final items = await _enqueueUploadBatch(event.filePaths);
    emit(
      state.copyWith(
        status: UploadQueueViewStatus.ready,
        items: List<UploadItem>.unmodifiable(items),
        message: 'Added ${event.filePaths.length} photo(s) to upload queue.',
      ),
    );

    if (event.startUpload) {
      add(const UploadQueueProcessRequested());
    }
  }

  Future<void> _onProcessRequested(
    UploadQueueProcessRequested event,
    Emitter<UploadQueueState> emit,
  ) async {
    if (_isProcessing) {
      return;
    }

    if (state.items.isEmpty) {
      if (!event.silent) {
        emit(state.copyWith(message: 'Upload queue is empty.'));
      }
      return;
    }

    _isProcessing = true;
    emit(
      state.copyWith(
        status: UploadQueueViewStatus.uploading,
        clearMessage: event.silent,
      ),
    );

    try {
      final latestItems = await _processPendingUploads(
        onItemsUpdated: (items) {
          if (!isClosed) {
            add(UploadQueueItemsUpdated(items));
          }
        },
      );

      final isOnline = await _hasNetworkAccess();
      final retryableCount = latestItems
          .where((item) => item.status.canRetry)
          .length;

      emit(
        state.copyWith(
          status: UploadQueueViewStatus.ready,
          items: List<UploadItem>.unmodifiable(latestItems),
          isOnline: isOnline,
          lastSyncedAt: DateTime.now(),
          message: event.silent
              ? null
              : _buildCompletionMessage(isOnline, retryableCount),
          clearMessage: event.silent,
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }

  void _onItemsUpdated(
    UploadQueueItemsUpdated event,
    Emitter<UploadQueueState> emit,
  ) {
    emit(
      state.copyWith(
        status: UploadQueueViewStatus.uploading,
        items: List<UploadItem>.unmodifiable(event.items),
      ),
    );
  }

  Future<void> _onNetworkChanged(
    UploadQueueNetworkChanged event,
    Emitter<UploadQueueState> emit,
  ) async {
    if (event.isOnline == state.isOnline) {
      return;
    }

    emit(
      state.copyWith(
        isOnline: event.isOnline,
        message: event.isOnline
            ? 'Network restored. Retrying pending uploads.'
            : 'Network lost. Uploads will stay in pending queue.',
      ),
    );

    if (!event.isOnline) {
      return;
    }

    final latestItems = await _getUploadItems();
    emit(state.copyWith(items: List<UploadItem>.unmodifiable(latestItems)));

    if (_hasRetryableItems(latestItems)) {
      add(const UploadQueueProcessRequested(silent: true, fromAutoRetry: true));
    }
  }

  Future<void> _onRefreshed(
    UploadQueueRefreshed event,
    Emitter<UploadQueueState> emit,
  ) async {
    final items = await _getUploadItems();
    final isOnline = await _hasNetworkAccess();

    emit(
      state.copyWith(
        status: UploadQueueViewStatus.ready,
        items: List<UploadItem>.unmodifiable(items),
        isOnline: isOnline,
        clearMessage: true,
      ),
    );
  }

  void _onMessageCleared(
    UploadQueueMessageCleared event,
    Emitter<UploadQueueState> emit,
  ) {
    if (state.message == null) {
      return;
    }

    emit(state.copyWith(clearMessage: true));
  }

  bool _hasRetryableItems(List<UploadItem> items) {
    return items.any((item) => item.status.canRetry);
  }

  String _buildCompletionMessage(bool isOnline, int retryableCount) {
    if (!isOnline) {
      return 'No stable network. Pending uploads will retry automatically.';
    }

    if (retryableCount > 0) {
      return 'Some files are still pending and will retry in background.';
    }

    return 'Batch uploaded successfully.';
  }

  @override
  Future<void> close() async {
    await _networkSubscription?.cancel();
    return super.close();
  }
}
