import 'package:equatable/equatable.dart';

import '../../domain/entities/geo_point.dart';

sealed class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceInitialized extends AttendanceEvent {
  const AttendanceInitialized();
}

class OfficeLocationRequested extends AttendanceEvent {
  const OfficeLocationRequested();
}

class OfficeLocationResetRequested extends AttendanceEvent {
  const OfficeLocationResetRequested();
}

class LocationTrackingRetried extends AttendanceEvent {
  const LocationTrackingRetried();
}

class AttendanceMarked extends AttendanceEvent {
  const AttendanceMarked();
}

class MessageCleared extends AttendanceEvent {
  const MessageCleared();
}

class CurrentLocationUpdated extends AttendanceEvent {
  const CurrentLocationUpdated(this.currentLocation);

  final GeoPoint currentLocation;

  @override
  List<Object?> get props => [currentLocation];
}

class LocationTrackingFailed extends AttendanceEvent {
  const LocationTrackingFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
