import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';

class LocationModel extends GeoPoint {
  const LocationModel({required super.latitude, required super.longitude});

  factory LocationModel.fromPosition(Position position) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  factory LocationModel.fromStorage({
    required double latitude,
    required double longitude,
  }) {
    return LocationModel(latitude: latitude, longitude: longitude);
  }
}
