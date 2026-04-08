import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

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
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _singlePositionLocationSettings,
      );
      if (_isFreshPosition(initialPosition) &&
          _hasTrackableAccuracy(initialPosition)) {
        return initialPosition;
      }

      if (lastKnownPosition != null &&
          _isFreshPosition(lastKnownPosition) &&
          _hasTrackableAccuracy(lastKnownPosition) &&
          lastKnownPosition.accuracy <= initialPosition.accuracy) {
        return lastKnownPosition;
      }

      return _resolveStableCurrentPosition(initialPosition);
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

    Position? previousAcceptedPosition;
    final recentAcceptedPositions = <Position>[];
    await for (final position in Geolocator.getPositionStream(
      locationSettings: _streamLocationSettings,
    )) {
      if (!_isFreshPosition(position) || !_hasTrackableAccuracy(position)) {
        continue;
      }

      if (_isOutlierJump(position, previousAcceptedPosition)) {
        continue;
      }

      previousAcceptedPosition = position;
      recentAcceptedPositions.add(position);
      if (recentAcceptedPositions.length >
          AppConstants.locationSmoothingWindowSize) {
        recentAcceptedPositions.removeAt(0);
      }

      yield _buildSmoothedPosition(recentAcceptedPositions);
    }
  }

  Future<Position> _resolveStableCurrentPosition(
    Position initialPosition,
  ) async {
    final samples = <Position>[
      if (_isFreshPosition(initialPosition)) initialPosition,
    ];
    try {
      final additionalSamples =
          await Geolocator.getPositionStream(
                locationSettings: _singlePositionLocationSettings,
              )
              .where(_isFreshPosition)
              .take(
                AppConstants.locationStabilizationSampleCount - samples.length,
              )
              .timeout(
                AppConstants.locationStabilizationTimeout,
                onTimeout: (sink) => sink.close(),
              )
              .toList();
      samples.addAll(additionalSamples);
    } catch (_) {
      // Keep the current best sample when the stabilization window closes early.
    }

    if (samples.isEmpty) {
      return initialPosition;
    }

    final stableSampleIndex = await _pickStableSampleIndex(samples);
    return samples[stableSampleIndex];
  }

  Future<int> _pickStableSampleIndex(List<Position> samples) async {
    if (samples.length <= 1) {
      return 0;
    }

    final serializedSamples = samples
        .map(
          (sample) => [
            sample.latitude,
            sample.longitude,
            sample.accuracy.clamp(1.0, 5000.0),
          ],
        )
        .toList(growable: false);

    return Isolate.run(() => _pickStablePositionIndex(serializedSamples));
  }

  bool _hasTrackableAccuracy(Position position) {
    return position.accuracy <= AppConstants.maxTrackingAccuracyInMeters;
  }

  bool _isFreshPosition(Position position) {
    return DateTime.now().difference(position.timestamp).abs() <=
        AppConstants.staleLocationThreshold;
  }

  bool _isOutlierJump(Position current, Position? previous) {
    if (previous == null) {
      return false;
    }

    final distanceInMeters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    if (distanceInMeters <= AppConstants.locationDistanceFilterInMeters) {
      return false;
    }

    final currentTimestamp = current.timestamp;
    final previousTimestamp = previous.timestamp;
    final elapsedInSeconds = math.max(
      1,
      currentTimestamp.difference(previousTimestamp).inMilliseconds.abs() /
          Duration.millisecondsPerSecond,
    );
    final speedMetersPerSecond = distanceInMeters / elapsedInSeconds;

    return speedMetersPerSecond >
            AppConstants.maxLocationJumpSpeedMetersPerSecond &&
        current.accuracy > AppConstants.targetCurrentFixAccuracyInMeters;
  }

  Position _buildSmoothedPosition(List<Position> samples) {
    final latest = samples.last;
    if (samples.length <= 1) {
      return latest;
    }

    double weightedLatitude = 0;
    double weightedLongitude = 0;
    double weightedAccuracy = 0;
    double totalWeight = 0;

    for (var index = 0; index < samples.length; index++) {
      final sample = samples[index];
      final recencyWeight = (index + 1) / samples.length;
      final accuracyWeight = 1 / sample.accuracy.clamp(3.0, 200.0);
      final weight = recencyWeight * accuracyWeight;
      weightedLatitude += sample.latitude * weight;
      weightedLongitude += sample.longitude * weight;
      weightedAccuracy += sample.accuracy * weight;
      totalWeight += weight;
    }

    final smoothedAccuracy = weightedAccuracy / totalWeight;
    return Position(
      latitude: weightedLatitude / totalWeight,
      longitude: weightedLongitude / totalWeight,
      timestamp: latest.timestamp,
      accuracy: smoothedAccuracy,
      altitude: latest.altitude,
      altitudeAccuracy: latest.altitudeAccuracy,
      heading: latest.heading,
      headingAccuracy: latest.headingAccuracy,
      speed: latest.speed,
      speedAccuracy: latest.speedAccuracy,
      floor: latest.floor,
      isMocked: latest.isMocked,
    );
  }

  LocationSettings get _singlePositionLocationSettings {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: AppConstants.locationUpdateInterval,
        forceLocationManager: false,
        timeLimit: AppConstants.currentLocationTimeout,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        timeLimit: AppConstants.currentLocationTimeout,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: AppConstants.currentLocationTimeout,
    );
  }

  LocationSettings get _streamLocationSettings {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: AppConstants.locationDistanceFilterInMeters,
        intervalDuration: AppConstants.locationUpdateInterval,
        forceLocationManager: false,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: AppConstants.locationDistanceFilterInMeters,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: AppConstants.locationDistanceFilterInMeters,
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

int _pickStablePositionIndex(List<List<double>> samples) {
  if (samples.length <= 1) {
    return 0;
  }

  double weightedLatitude = 0;
  double weightedLongitude = 0;
  double totalWeight = 0;

  for (final sample in samples) {
    final accuracy = sample[2].abs().clamp(1.0, 5000.0);
    final weight = 1 / accuracy;
    weightedLatitude += sample[0] * weight;
    weightedLongitude += sample[1] * weight;
    totalWeight += weight;
  }

  final centroidLatitude = weightedLatitude / totalWeight;
  final centroidLongitude = weightedLongitude / totalWeight;

  var bestIndex = 0;
  var bestScore = double.infinity;

  for (var index = 0; index < samples.length; index++) {
    final sample = samples[index];
    final distanceToCentroid = _haversineDistanceInMeters(
      latitude1: sample[0],
      longitude1: sample[1],
      latitude2: centroidLatitude,
      longitude2: centroidLongitude,
    );
    final score = distanceToCentroid + (sample[2] * 0.7);
    if (score < bestScore) {
      bestScore = score;
      bestIndex = index;
    }
  }

  return bestIndex;
}

double _haversineDistanceInMeters({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  const earthRadiusInMeters = 6371000.0;
  final latitudeDelta = _toRadians(latitude2 - latitude1);
  final longitudeDelta = _toRadians(longitude2 - longitude1);

  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(_toRadians(latitude1)) *
          math.cos(_toRadians(latitude2)) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusInMeters * c;
}

double _toRadians(double value) => value * (math.pi / 180);
