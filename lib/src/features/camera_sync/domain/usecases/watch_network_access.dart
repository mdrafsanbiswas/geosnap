import '../repositories/upload_queue_repository.dart';

class WatchNetworkAccessUseCase {
  const WatchNetworkAccessUseCase(this._uploadQueueRepository);

  final UploadQueueRepository _uploadQueueRepository;

  Stream<bool> call() => _uploadQueueRepository.watchNetworkAccess();
}
