import '../repositories/upload_queue_repository.dart';

class HasNetworkAccessUseCase {
  const HasNetworkAccessUseCase(this._uploadQueueRepository);

  final UploadQueueRepository _uploadQueueRepository;

  Future<bool> call() => _uploadQueueRepository.hasNetworkAccess();
}
