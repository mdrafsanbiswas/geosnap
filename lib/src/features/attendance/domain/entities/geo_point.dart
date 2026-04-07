import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyInMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyInMeters;

  @override
  List<Object?> get props => [latitude, longitude, accuracyInMeters];
}
