import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';
import '../../domain/repositories/upload_queue_repository.dart';
import '../data_sources/mock_upload_remote.dart';
import '../data_sources/network_checker.dart';
import '../data_sources/upload_queue_local.dart';
import '../models/upload_item_model.dart';

class UploadQueueRepositoryImpl implements UploadQueueRepository {
  const UploadQueueRepositoryImpl({
    required UploadQueueLocalDataSource uploadQueueLocalDataSource,
    required UploadRemoteDataSource uploadRemoteDataSource,
    required NetworkCheckerDataSource networkCheckerDataSource,
  }) : _uploadQueueLocalDataSource = uploadQueueLocalDataSource,
       _uploadRemoteDataSource = uploadRemoteDataSource,
       _networkCheckerDataSource = networkCheckerDataSource;

  final UploadQueueLocalDataSource _uploadQueueLocalDataSource;
  final UploadRemoteDataSource _uploadRemoteDataSource;
  final NetworkCheckerDataSource _networkCheckerDataSource;

  @override
  Future<List<UploadItem>> getUploadItems() async {
    final models = await _uploadQueueLocalDataSource.getUploadItems();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<List<UploadItem>> enqueueBatch(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      return getUploadItems();
    }

    final items = [...await getUploadItems()];
    final batchId = DateTime.now().microsecondsSinceEpoch.toString();

    for (var index = 0; index < filePaths.length; index++) {
      final now = DateTime.now();
      items.add(
        UploadItem(
          id: '${batchId}_$index',
          batchId: batchId,
          filePath: filePaths[index],
          status: UploadStatus.pending,
          progress: 0,
          retryCount: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await _persist(items);
    return items;
  }

  @override
  Future<List<UploadItem>> processPendingUploads({
    UploadItemsListener? onItemsUpdated,
  }) async {
    var items = [...await getUploadItems()];
    if (items.isEmpty) {
      return items;
    }

    final hasNetwork = await hasNetworkAccess();
    if (!hasNetwork) {
      items = _markWaitingForNetwork(items);
      await _persist(items);
      onItemsUpdated?.call(items);
      return items;
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item.status == UploadStatus.uploaded) {
        continue;
      }

      final stillConnected = await hasNetworkAccess();
      if (!stillConnected) {
        items = _markWaitingForNetwork(items);
        await _persist(items);
        onItemsUpdated?.call(items);
        return items;
      }

      items[index] = item.copyWith(
        status: UploadStatus.uploading,
        progress: item.progress.clamp(0, 1),
        updatedAt: DateTime.now(),
        clearErrorMessage: true,
      );
      await _persist(items);
      onItemsUpdated?.call(items);

      try {
        await _uploadRemoteDataSource.uploadFile(
          filePath: item.filePath,
          onProgress: (progress) async {
            items[index] = items[index].copyWith(
              status: UploadStatus.uploading,
              progress: progress.clamp(0, 1),
              updatedAt: DateTime.now(),
              clearErrorMessage: true,
            );
            await _persist(items);
            onItemsUpdated?.call(items);
          },
        );

        items[index] = items[index].copyWith(
          status: UploadStatus.uploaded,
          progress: 1,
          updatedAt: DateTime.now(),
          clearErrorMessage: true,
        );
      } on MockUploadException catch (error) {
        final onlineAfterError = await hasNetworkAccess();
        items[index] = items[index].copyWith(
          status: onlineAfterError
              ? UploadStatus.failed
              : UploadStatus.waitingForNetwork,
          progress: 0,
          retryCount: items[index].retryCount + 1,
          updatedAt: DateTime.now(),
          errorMessage: error.message,
        );
      } catch (_) {
        final onlineAfterError = await hasNetworkAccess();
        items[index] = items[index].copyWith(
          status: onlineAfterError
              ? UploadStatus.failed
              : UploadStatus.waitingForNetwork,
          progress: 0,
          retryCount: items[index].retryCount + 1,
          updatedAt: DateTime.now(),
          errorMessage: 'Unexpected upload failure.',
        );
      }

      await _persist(items);
      onItemsUpdated?.call(items);
    }

    return items;
  }

  @override
  Future<bool> hasNetworkAccess() {
    return _networkCheckerDataSource.hasNetworkAccess();
  }

  @override
  Stream<bool> watchNetworkAccess() {
    return _networkCheckerDataSource.watchNetworkAccess();
  }

  List<UploadItem> _markWaitingForNetwork(List<UploadItem> items) {
    return items
        .map(
          (item) => item.status == UploadStatus.uploaded
              ? item
              : item.copyWith(
                  status: UploadStatus.waitingForNetwork,
                  updatedAt: DateTime.now(),
                ),
        )
        .toList(growable: false);
  }

  Future<void> _persist(List<UploadItem> items) {
    final models = items
        .map(UploadItemModel.fromEntity)
        .toList(growable: false);
    return _uploadQueueLocalDataSource.saveUploadItems(models);
  }
}
