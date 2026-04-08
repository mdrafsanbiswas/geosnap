class CameraSyncUiText {
  const CameraSyncUiText._();

  static const cameraUnavailable = 'Camera is unavailable.';
  static const retryCamera = 'Retry Camera';
  static const captureBeforeUpload = 'Capture photos before uploading.';

  static String offlineQueued(int queuedCount) =>
      'Offline: $queuedCount ${_uploadWord(queuedCount)} queued';
  static String uploadingProgress(int uploadingCount, int queuedCount) =>
      'Uploading $uploadingCount of $queuedCount queued ${_itemWord(queuedCount)}';
  static String queuedPending(int queuedCount) =>
      '$queuedCount ${_uploadWord(queuedCount)} pending in queue';

  static String uploadBatch(int count) => 'Upload Batch ($count)';

  static const uploadManagerTitle = 'Upload Manager';
  static const queuedUploadPreviewTitle = 'Queued Upload Preview';
  static const startNewUploadBatch = 'Start New Upload Batch';

  static const emptyUploadsTitle = 'No uploads yet';
  static const emptyUploadsOnlineBody =
      'New uploads will appear here and start syncing automatically.';
  static const emptyUploadsOfflineBody =
      'You are offline. Captured photos will queue here and auto-resume once internet is back.';

  static const batchSyncProgress = 'Batch Sync Progress';
  static const online = 'Online';
  static const offline = 'Offline';
  static String progressLine(int uploaded, int total, int pending) =>
      '$uploaded/$total uploaded • $pending pending';
  static String lastSync(DateTime dateTime) =>
      'Last sync: ${dateTime.toLocal()}';

  static const currentBatchTitle = 'Current Batch';
  static const noCapturedPhotos = 'No captured photos in this batch yet.';
  static const batchPreviewTitle = 'Batch Preview';

  static const imagePreviewTitle = 'Image Preview';
  static const noImageAvailable = 'No image available.';
  static const unableToLoadImage = 'Unable to load this image.';

  static String _uploadWord(int count) => count == 1 ? 'upload' : 'uploads';
  static String _itemWord(int count) => count == 1 ? 'item' : 'items';
}
