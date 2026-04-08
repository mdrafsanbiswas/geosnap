import '../entities/geo_point.dart';

abstract class AttendanceRepository {
  Future<GeoPoint?> getSavedOfficeLocation();

  Future<void> saveOfficeLocation(GeoPoint location);

  Future<void> clearSavedOfficeLocation();

  Future<GeoPoint> getCurrentLocation();

  Stream<GeoPoint> watchCurrentLocation();

  double calculateDistanceInMeters({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}
