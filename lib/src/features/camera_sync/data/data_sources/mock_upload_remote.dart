import 'dart:async';
import 'dart:io';
import 'dart:math';

abstract class UploadRemoteDataSource {
  Future<void> uploadFile({
    required String filePath,
    required FutureOr<void> Function(double progress) onProgress,
  });
}

class MockUploadException implements Exception {
  const MockUploadException(this.message);

  final String message;

  @override
  String toString() => 'MockUploadException(message: $message)';
}

class MockUploadRemoteDataSource implements UploadRemoteDataSource {
  MockUploadRemoteDataSource({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<void> uploadFile({
    required String filePath,
    required FutureOr<void> Function(double progress) onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const MockUploadException('Captured file is no longer available.');
    }

    const totalChunks = 6;
    for (var chunk = 1; chunk <= totalChunks; chunk++) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      await onProgress(chunk / totalChunks);
    }

    final shouldFail = _random.nextDouble() < 0.28;
    if (shouldFail) {
      throw const MockUploadException(
        'Server rejected the upload. Will retry later.',
      );
    }
  }
}
