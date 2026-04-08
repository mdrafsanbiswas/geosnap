import '../entities/upload_item.dart';
import '../repositories/upload_queue_repository.dart';

class GetUploadItemsUseCase {
  const GetUploadItemsUseCase(this._uploadQueueRepository);

  final UploadQueueRepository _uploadQueueRepository;

  Future<List<UploadItem>> call() => _uploadQueueRepository.getUploadItems();
}
