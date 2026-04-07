enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class LocationException implements Exception {
  const LocationException({required this.type, required this.message});

  final LocationErrorType type;
  final String message;

  @override
  String toString() => 'LocationException(type: $type, message: $message)';
}
