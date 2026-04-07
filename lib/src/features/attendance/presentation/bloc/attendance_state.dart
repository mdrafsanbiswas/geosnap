import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';

enum AttendanceViewStatus { initial, loading, ready }

enum AttendanceFeedbackType { neutral, success, error }

class AttendanceState extends Equatable {
  const AttendanceState({
    this.status = AttendanceViewStatus.initial,
    this.officeLocation,
    this.currentLocation,
    this.distanceInMeters,
    this.locationErrorType,
    this.message,
    this.feedbackType = AttendanceFeedbackType.neutral,
    this.attendanceMarkedAt,
  });

  final AttendanceViewStatus status;
  final GeoPoint? officeLocation;
  final GeoPoint? currentLocation;
  final double? distanceInMeters;
  final LocationErrorType? locationErrorType;
  final String? message;
  final AttendanceFeedbackType feedbackType;
  final DateTime? attendanceMarkedAt;

  bool get hasSavedOfficeLocation => officeLocation != null;

  bool get isInRange =>
      (distanceInMeters ?? double.infinity) <=
      AppConstants.attendanceRadiusInMeters;

  bool get canMarkAttendance =>
      hasSavedOfficeLocation &&
      currentLocation != null &&
      locationErrorType == null &&
      isInRange;

  AttendanceState copyWith({
    AttendanceViewStatus? status,
    GeoPoint? officeLocation,
    GeoPoint? currentLocation,
    double? distanceInMeters,
    LocationErrorType? locationErrorType,
    String? message,
    AttendanceFeedbackType? feedbackType,
    DateTime? attendanceMarkedAt,
    bool clearOfficeLocation = false,
    bool clearCurrentLocation = false,
    bool clearDistance = false,
    bool clearLocationErrorType = false,
    bool clearMessage = false,
    bool clearAttendanceMarkedAt = false,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      officeLocation: clearOfficeLocation
          ? null
          : officeLocation ?? this.officeLocation,
      currentLocation: clearCurrentLocation
          ? null
          : currentLocation ?? this.currentLocation,
      distanceInMeters: clearDistance
          ? null
          : distanceInMeters ?? this.distanceInMeters,
      locationErrorType: clearLocationErrorType
          ? null
          : locationErrorType ?? this.locationErrorType,
      message: clearMessage ? null : message ?? this.message,
      feedbackType: feedbackType ?? this.feedbackType,
      attendanceMarkedAt: clearAttendanceMarkedAt
          ? null
          : attendanceMarkedAt ?? this.attendanceMarkedAt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    officeLocation,
    currentLocation,
    distanceInMeters,
    locationErrorType,
    message,
    feedbackType,
    attendanceMarkedAt,
  ];
}
