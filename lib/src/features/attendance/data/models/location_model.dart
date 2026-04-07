import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';

class LocationModel extends GeoPoint {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.accuracyInMeters,
  });

  factory LocationModel.fromPosition(Position position) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyInMeters: position.accuracy,
    );
  }

  factory LocationModel.fromStorage({
    required double latitude,
    required double longitude,
    double? accuracyInMeters,
  }) {
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      accuracyInMeters: accuracyInMeters,
    );
  }
}
