import '../entities/upload_item.dart';
import '../repositories/upload_queue_repository.dart';

class ProcessPendingUploadsUseCase {
  const ProcessPendingUploadsUseCase(this._uploadQueueRepository);

  final UploadQueueRepository _uploadQueueRepository;

  Future<List<UploadItem>> call({
    UploadItemsListener? onItemsUpdated,
  }) {
    return _uploadQueueRepository.processPendingUploads(
      onItemsUpdated: onItemsUpdated,
    );
  }
}
