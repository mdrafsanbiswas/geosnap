import '../entities/upload_item.dart';
import '../repositories/upload_queue_repository.dart';

class EnqueueUploadBatchUseCase {
  const EnqueueUploadBatchUseCase(this._uploadQueueRepository);

  final UploadQueueRepository _uploadQueueRepository;

  Future<List<UploadItem>> call(List<String> filePaths) {
    return _uploadQueueRepository.enqueueBatch(filePaths);
  }
}
