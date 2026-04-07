import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/calculate_distance_use_case.dart';
import '../../domain/usecases/get_current_location_use_case.dart';
import '../../domain/usecases/get_saved_office_location_use_case.dart';
import '../../domain/usecases/save_office_location_use_case.dart';
import '../../domain/usecases/watch_current_location_use_case.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit({
    required GetSavedOfficeLocationUseCase getSavedOfficeLocation,
    required SaveOfficeLocationUseCase saveOfficeLocation,
    required GetCurrentLocationUseCase getCurrentLocation,
    required WatchCurrentLocationUseCase watchCurrentLocation,
    required CalculateDistanceUseCase calculateDistance,
  }) : _getSavedOfficeLocation = getSavedOfficeLocation,
       _saveOfficeLocation = saveOfficeLocation,
       _getCurrentLocation = getCurrentLocation,
       _watchCurrentLocation = watchCurrentLocation,
       _calculateDistance = calculateDistance,
       super(const AttendanceState());

  final GetSavedOfficeLocationUseCase _getSavedOfficeLocation;
  final SaveOfficeLocationUseCase _saveOfficeLocation;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final WatchCurrentLocationUseCase _watchCurrentLocation;
  final CalculateDistanceUseCase _calculateDistance;

  StreamSubscription<GeoPoint>? _locationSubscription;

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: AttendanceViewStatus.loading,
        clearMessage: true,
        clearLocationErrorType: true,
      ),
    );

    final savedOfficeLocation = await _getSavedOfficeLocation();

    emit(
      state.copyWith(
        status: AttendanceViewStatus.ready,
        officeLocation: savedOfficeLocation,
        clearLocationErrorType: true,
      ),
    );

    if (savedOfficeLocation != null) {
      await _refreshLocationTracking(savedOfficeLocation);
    }
  }

  Future<void> setOfficeLocation() async {
    emit(
      state.copyWith(
        status: AttendanceViewStatus.loading,
        clearMessage: true,
        clearLocationErrorType: true,
      ),
    );

    try {
      final currentLocation = await _getCurrentLocation();
      await _saveOfficeLocation(currentLocation);

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          officeLocation: currentLocation,
          currentLocation: currentLocation,
          distanceInMeters: 0,
          clearLocationErrorType: true,
          clearAttendanceMarkedAt: true,
          message: 'Office location saved successfully.',
          feedbackType: AttendanceFeedbackType.success,
        ),
      );

      await _subscribeToLocationUpdates(currentLocation);
    } on LocationException catch (error) {
      _emitLocationError(error);
    }
  }

  Future<void> retryLocationTracking() async {
    final officeLocation = state.officeLocation;
    if (officeLocation == null) {
      return;
    }

    emit(
      state.copyWith(
        status: AttendanceViewStatus.loading,
        clearMessage: true,
        clearLocationErrorType: true,
      ),
    );

    await _refreshLocationTracking(officeLocation);
  }

  Future<void> markAttendance() async {
    if (!state.canMarkAttendance) {
      emit(
        state.copyWith(
          message:
              'Move within ${AppConstants.attendanceRadiusInMeters.toInt()} meters of the office to mark attendance.',
          feedbackType: AttendanceFeedbackType.error,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        attendanceMarkedAt: DateTime.now(),
        message: 'Attendance marked successfully.',
        feedbackType: AttendanceFeedbackType.success,
      ),
    );
  }

  void clearMessage() {
    if (state.message == null) {
      return;
    }

    emit(
      state.copyWith(
        clearMessage: true,
        feedbackType: AttendanceFeedbackType.neutral,
      ),
    );
  }

  Future<void> _refreshLocationTracking(GeoPoint officeLocation) async {
    try {
      final currentLocation = await _getCurrentLocation();
      _updateDistance(
        officeLocation: officeLocation,
        currentLocation: currentLocation,
      );

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          clearLocationErrorType: true,
        ),
      );

      await _subscribeToLocationUpdates(officeLocation);
    } on LocationException catch (error) {
      _emitLocationError(error);
    }
  }

  Future<void> _subscribeToLocationUpdates(GeoPoint officeLocation) async {
    await _locationSubscription?.cancel();
    _locationSubscription = _watchCurrentLocation().listen(
      (currentLocation) {
        _updateDistance(
          officeLocation: officeLocation,
          currentLocation: currentLocation,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (error is LocationException) {
          _emitLocationError(error);
          return;
        }

        _emitLocationError(
          const LocationException(
            type: LocationErrorType.unavailable,
            message: 'Unable to keep tracking your location right now.',
          ),
        );
      },
    );
  }

  void _updateDistance({
    required GeoPoint officeLocation,
    required GeoPoint currentLocation,
  }) {
    final distanceInMeters = _calculateDistance(
      origin: officeLocation,
      destination: currentLocation,
    );

    emit(
      state.copyWith(
        status: AttendanceViewStatus.ready,
        officeLocation: officeLocation,
        currentLocation: currentLocation,
        distanceInMeters: distanceInMeters,
        clearLocationErrorType: true,
      ),
    );
  }

  void _emitLocationError(LocationException error) {
    emit(
      state.copyWith(
        status: AttendanceViewStatus.ready,
        locationErrorType: error.type,
        message: error.message,
        feedbackType: AttendanceFeedbackType.error,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _locationSubscription?.cancel();
    return super.close();
  }
}
