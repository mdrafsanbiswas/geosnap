import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/device_location.dart';
import '../datasources/office_location_local.dart';
import '../models/location_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  const AttendanceRepositoryImpl({
    required DeviceLocationDataSource deviceLocationDataSource,
    required OfficeLocationLocalDataSource officeLocationLocalDataSource,
  }) : _deviceLocationDataSource = deviceLocationDataSource,
       _officeLocationLocalDataSource = officeLocationLocalDataSource;

  final DeviceLocationDataSource _deviceLocationDataSource;
  final OfficeLocationLocalDataSource _officeLocationLocalDataSource;

  @override
  double calculateDistanceInMeters({
    required GeoPoint origin,
    required GeoPoint destination,
  }) {
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  @override
  Future<GeoPoint> getCurrentLocation() async {
    final position = await _deviceLocationDataSource.getCurrentPosition();

    return LocationModel.fromPosition(position);
  }

  @override
  Future<GeoPoint?> getSavedOfficeLocation() {
    return _officeLocationLocalDataSource.getSavedOfficeLocation();
  }

  @override
  Future<void> saveOfficeLocation(GeoPoint location) {
    return _officeLocationLocalDataSource.saveOfficeLocation(
      LocationModel(latitude: location.latitude, longitude: location.longitude),
    );
  }

  @override
  Stream<GeoPoint> watchCurrentLocation() {
    return _deviceLocationDataSource.watchPosition().map(
      LocationModel.fromPosition,
    );
  }
}
