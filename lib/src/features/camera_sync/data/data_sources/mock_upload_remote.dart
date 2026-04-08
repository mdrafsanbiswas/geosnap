import 'dart:async';
import 'dart:io';

abstract class UploadRemoteDataSource {
  Future<void> uploadFile({
    required UploadFileRequest request,
    required FutureOr<void> Function(double progress) onProgress,
  });
}

class UploadFileRequest {
  const UploadFileRequest({
    required this.filePath,
    required this.itemId,
    required this.batchId,
    required this.createdAt,
  });

  final String filePath;
  final String itemId;
  final String batchId;
  final DateTime createdAt;
}

class MockUploadException implements Exception {
  const MockUploadException(this.message);

  final String message;

  @override
  String toString() => 'MockUploadException(message: $message)';
}

class MockUploadRemoteDataSource implements UploadRemoteDataSource {
  const MockUploadRemoteDataSource();

  @override
  Future<void> uploadFile({
    required UploadFileRequest request,
    required FutureOr<void> Function(double progress) onProgress,
  }) async {
    final file = File(request.filePath);
    if (!await file.exists()) {
      throw const MockUploadException('Captured file is no longer available.');
    }

    const totalChunks = 6;
    for (var chunk = 1; chunk <= totalChunks; chunk++) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await onProgress(chunk / totalChunks);
    }
  }
}
