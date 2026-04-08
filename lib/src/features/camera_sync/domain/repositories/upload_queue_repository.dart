import '../entities/upload_item.dart';

typedef UploadItemsListener = void Function(List<UploadItem> items);

abstract class UploadQueueRepository {
  Future<List<UploadItem>> getUploadItems();

  Future<List<UploadItem>> enqueueBatch(List<String> filePaths);

  Future<List<UploadItem>> processPendingUploads({
    UploadItemsListener? onItemsUpdated,
  });

  Future<bool> hasNetworkAccess();

  Stream<bool> watchNetworkAccess();
}
