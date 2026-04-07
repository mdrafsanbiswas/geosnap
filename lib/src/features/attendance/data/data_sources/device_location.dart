import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';

abstract class DeviceLocationDataSource {
  Future<Position> getCurrentPosition();

  Stream<Position> watchPosition();
}

class GeolocatorDeviceLocationDataSource implements DeviceLocationDataSource {
  const GeolocatorDeviceLocationDataSource();

  @override
  Future<Position> getCurrentPosition() async {
    await _ensureLocationAccess();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: AppConstants.currentLocationTimeout,
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        type: LocationErrorType.timeout,
        message: 'Fetching your location took too long. Please try again.',
      );
    } catch (_) {
      throw const LocationException(
        type: LocationErrorType.unavailable,
        message: 'Unable to fetch your current location right now.',
      );
    }
  }

  @override
  Stream<Position> watchPosition() async* {
    await _ensureLocationAccess();

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: AppConstants.locationDistanceFilterInMeters,
      ),
    );
  }

  Future<void> _ensureLocationAccess() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const LocationException(
        type: LocationErrorType.serviceDisabled,
        message: 'Location services are disabled. Please turn GPS on.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        type: LocationErrorType.permissionDenied,
        message: 'Location permission was denied. Please allow access.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        type: LocationErrorType.permissionDeniedForever,
        message:
            'Location permission is permanently denied. Update it in settings.',
      );
    }
  }
}
