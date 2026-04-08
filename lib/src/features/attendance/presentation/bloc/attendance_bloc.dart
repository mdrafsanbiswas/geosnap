import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/calculate_distance.dart';
import '../../domain/usecases/clear_saved_office_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_saved_office_location.dart';
import '../../domain/usecases/save_office_location.dart';
import '../../domain/usecases/watch_current_location.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc({
    required GetSavedOfficeLocationUseCase getSavedOfficeLocation,
    required SaveOfficeLocationUseCase saveOfficeLocation,
    required ClearSavedOfficeLocationUseCase clearSavedOfficeLocation,
    required GetCurrentLocationUseCase getCurrentLocation,
    required WatchCurrentLocationUseCase watchCurrentLocation,
    required CalculateDistanceUseCase calculateDistance,
  }) : _getSavedOfficeLocation = getSavedOfficeLocation,
       _saveOfficeLocation = saveOfficeLocation,
       _clearSavedOfficeLocation = clearSavedOfficeLocation,
       _getCurrentLocation = getCurrentLocation,
       _watchCurrentLocation = watchCurrentLocation,
       _calculateDistance = calculateDistance,
       super(const AttendanceState()) {
    on<AttendanceInitialized>(_onInitialized);
    on<OfficeLocationRequested>(_onOfficeLocationRequested);
    on<OfficeLocationResetRequested>(_onOfficeLocationResetRequested);
    on<LocationTrackingRetried>(_onLocationTrackingRetried);
    on<AttendanceMarked>(_onAttendanceMarked);
    on<MessageCleared>(_onMessageCleared);
    on<CurrentLocationUpdated>(_onCurrentLocationUpdated);
    on<LocationTrackingFailed>(_onLocationTrackingFailed);
  }

  final GetSavedOfficeLocationUseCase _getSavedOfficeLocation;
  final SaveOfficeLocationUseCase _saveOfficeLocation;
  final ClearSavedOfficeLocationUseCase _clearSavedOfficeLocation;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final WatchCurrentLocationUseCase _watchCurrentLocation;
  final CalculateDistanceUseCase _calculateDistance;

  StreamSubscription<GeoPoint>? _locationSubscription;

  Future<void> _onInitialized(
    AttendanceInitialized event,
    Emitter<AttendanceState> emit,
  ) async {
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

    await _refreshLocationTracking(
      officeLocation: savedOfficeLocation,
      emit: emit,
    );
  }

  Future<void> _onOfficeLocationRequested(
    OfficeLocationRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.officeLocation != null) {
      emit(
        state.copyWith(
          message: 'Office location is locked. Use reset to change it.',
          feedbackType: AttendanceFeedbackType.error,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AttendanceViewStatus.loading,
        clearMessage: true,
        clearLocationErrorType: true,
      ),
    );

    try {
      final currentLocation =
          state.currentLocation ?? await _getCurrentLocation();
      await _saveOfficeLocation(currentLocation);

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          officeLocation: currentLocation,
          currentLocation: currentLocation,
          distanceInMeters: 0,
          clearLocationErrorType: true,
          clearAttendanceMarkedAt: true,
          clearAttendanceMarkStatus: true,
          message: 'Office location saved. You can now mark attendance nearby.',
          feedbackType: AttendanceFeedbackType.success,
        ),
      );

      await _subscribeToLocationUpdates();
    } on LocationException catch (error) {
      _emitLocationError(error, emit);
    }
  }

  Future<void> _onOfficeLocationResetRequested(
    OfficeLocationResetRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(status: AttendanceViewStatus.loading, clearMessage: true),
    );

    await _clearSavedOfficeLocation();

    emit(
      state.copyWith(
        status: AttendanceViewStatus.ready,
        clearOfficeLocation: true,
        clearDistance: true,
        clearLocationErrorType: true,
        clearAttendanceMarkedAt: true,
        clearAttendanceMarkStatus: true,
        message: 'Office location reset. Set it again when ready.',
        feedbackType: AttendanceFeedbackType.success,
      ),
    );

    if (state.currentLocation == null) {
      await _refreshLocationTracking(officeLocation: null, emit: emit);
    }
  }

  Future<void> _onLocationTrackingRetried(
    LocationTrackingRetried event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceViewStatus.loading,
        clearMessage: true,
        clearLocationErrorType: true,
      ),
    );

    await _refreshLocationTracking(
      officeLocation: state.officeLocation,
      emit: emit,
    );
  }

  void _onAttendanceMarked(
    AttendanceMarked event,
    Emitter<AttendanceState> emit,
  ) {
    if (!state.canMarkAttendance) {
      emit(
        state.copyWith(
          message:
              'Move within ${AppConstants.attendanceRadiusInMeters.toInt()} meters of office to mark attendance.',
          feedbackType: AttendanceFeedbackType.error,
        ),
      );
      return;
    }

    final markedAt = DateTime.now();
    final attendanceMarkStatus = _resolveAttendanceMarkStatus(markedAt);
    final statusText = attendanceMarkStatus == AttendanceMarkStatus.late
        ? 'late'
        : 'on time';

    emit(
      state.copyWith(
        attendanceMarkedAt: markedAt,
        attendanceMarkStatus: attendanceMarkStatus,
        message: 'Attendance marked at ${_formatTime(markedAt)} ($statusText).',
        feedbackType: AttendanceFeedbackType.success,
      ),
    );
  }

  void _onMessageCleared(MessageCleared event, Emitter<AttendanceState> emit) {
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

  void _onCurrentLocationUpdated(
    CurrentLocationUpdated event,
    Emitter<AttendanceState> emit,
  ) {
    final officeLocation = state.officeLocation;
    if (officeLocation == null) {
      final previousCurrentLocation = state.currentLocation;
      if (previousCurrentLocation != null) {
        final deltaInMeters = _calculateDistance(
          origin: previousCurrentLocation,
          destination: event.currentLocation,
        );
        if (deltaInMeters < AppConstants.minDistanceDeltaForUiUpdateInMeters &&
            state.locationErrorType == null) {
          return;
        }
      }

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          currentLocation: event.currentLocation,
          clearLocationErrorType: true,
        ),
      );
      return;
    }

    _updateDistance(
      officeLocation: officeLocation,
      currentLocation: event.currentLocation,
      emit: emit,
    );
  }

  void _onLocationTrackingFailed(
    LocationTrackingFailed event,
    Emitter<AttendanceState> emit,
  ) {
    if (event.error is LocationException) {
      _emitLocationError(event.error as LocationException, emit);
      return;
    }

    _emitLocationError(
      const LocationException(
        type: LocationErrorType.unavailable,
        message: 'Unable to keep tracking your location right now.',
      ),
      emit,
    );
  }

  Future<void> _refreshLocationTracking({
    required GeoPoint? officeLocation,
    required Emitter<AttendanceState> emit,
  }) async {
    try {
      final currentLocation = await _getCurrentLocation();
      if (officeLocation == null) {
        emit(
          state.copyWith(
            status: AttendanceViewStatus.ready,
            currentLocation: currentLocation,
            clearLocationErrorType: true,
          ),
        );
      } else {
        _updateDistance(
          officeLocation: officeLocation,
          currentLocation: currentLocation,
          emit: emit,
        );
      }

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          clearLocationErrorType: true,
        ),
      );

      await _subscribeToLocationUpdates();
    } on LocationException catch (error) {
      _emitLocationError(error, emit);
    }
  }

  Future<void> _subscribeToLocationUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = _watchCurrentLocation().listen(
      (currentLocation) {
        add(CurrentLocationUpdated(currentLocation));
      },
      onError: (Object error, StackTrace stackTrace) {
        add(LocationTrackingFailed(error));
      },
    );
  }

  void _updateDistance({
    required GeoPoint officeLocation,
    required GeoPoint currentLocation,
    required Emitter<AttendanceState> emit,
  }) {
    final rawDistanceInMeters = _calculateDistance(
      origin: officeLocation,
      destination: currentLocation,
    );
    final distanceInMeters = _applyNearDistanceCompensation(
      rawDistanceInMeters: rawDistanceInMeters,
      officeLocation: officeLocation,
      currentLocation: currentLocation,
    );
    final hasDistanceDeltaBelowThreshold =
        state.distanceInMeters != null &&
        (distanceInMeters - state.distanceInMeters!).abs() <
            AppConstants.minDistanceDeltaForUiUpdateInMeters;
    final previousInRange = state.isInRange;
    final nextInRange =
        distanceInMeters <= AppConstants.attendanceRadiusInMeters;
    if (hasDistanceDeltaBelowThreshold &&
        previousInRange == nextInRange &&
        state.locationErrorType == null) {
      return;
    }

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

  double _applyNearDistanceCompensation({
    required double rawDistanceInMeters,
    required GeoPoint officeLocation,
    required GeoPoint currentLocation,
  }) {
    if (rawDistanceInMeters >
        AppConstants.nearDistanceCompensationThresholdInMeters) {
      return rawDistanceInMeters;
    }

    final officeAccuracy =
        officeLocation.accuracyInMeters ??
        AppConstants.fallbackLocationAccuracyInMeters;
    final currentAccuracy =
        currentLocation.accuracyInMeters ??
        AppConstants.fallbackLocationAccuracyInMeters;
    final normalizedOfficeAccuracy = officeAccuracy.clamp(2, 40);
    final normalizedCurrentAccuracy = currentAccuracy.clamp(2, 40);
    final compensationInMeters = math.min(
      (normalizedOfficeAccuracy + normalizedCurrentAccuracy) *
          AppConstants.nearDistanceCompensationFactor,
      AppConstants.maxNearDistanceCompensationInMeters,
    );

    return math.max(0, rawDistanceInMeters - compensationInMeters);
  }

  AttendanceMarkStatus _resolveAttendanceMarkStatus(DateTime markedAt) {
    final windowStart = DateTime(
      markedAt.year,
      markedAt.month,
      markedAt.day,
      AppConstants.attendanceStartHour,
      AppConstants.attendanceStartMinute,
    );
    final windowEnd = DateTime(
      markedAt.year,
      markedAt.month,
      markedAt.day,
      AppConstants.attendanceEndHour,
      AppConstants.attendanceEndMinute,
    );
    final isWithinWindow =
        !markedAt.isBefore(windowStart) && !markedAt.isAfter(windowEnd);

    return isWithinWindow
        ? AttendanceMarkStatus.onTime
        : AttendanceMarkStatus.late;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final safeHour = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$safeHour:$minute $suffix';
  }

  void _emitLocationError(
    LocationException error,
    Emitter<AttendanceState> emit,
  ) {
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
