enum UploadStatus {
  pending,
  uploading,
  uploaded,
  failed,
  waitingForNetwork,
}

extension UploadStatusX on UploadStatus {
  String get label {
    switch (this) {
      case UploadStatus.pending:
        return 'Pending';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.uploaded:
        return 'Uploaded';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.waitingForNetwork:
        return 'Waiting for network';
    }
  }

  bool get canRetry {
    return this == UploadStatus.pending ||
        this == UploadStatus.failed ||
        this == UploadStatus.waitingForNetwork;
  }
}
