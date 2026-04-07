import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/usecases/calculate_distance.dart';
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
    required GetCurrentLocationUseCase getCurrentLocation,
    required WatchCurrentLocationUseCase watchCurrentLocation,
    required CalculateDistanceUseCase calculateDistance,
  }) : _getSavedOfficeLocation = getSavedOfficeLocation,
       _saveOfficeLocation = saveOfficeLocation,
       _getCurrentLocation = getCurrentLocation,
       _watchCurrentLocation = watchCurrentLocation,
       _calculateDistance = calculateDistance,
       super(const AttendanceState()) {
    on<AttendanceInitialized>(_onInitialized);
    on<OfficeLocationRequested>(_onOfficeLocationRequested);
    on<LocationTrackingRetried>(_onLocationTrackingRetried);
    on<AttendanceMarked>(_onAttendanceMarked);
    on<MessageCleared>(_onMessageCleared);
    on<CurrentLocationUpdated>(_onCurrentLocationUpdated);
    on<LocationTrackingFailed>(_onLocationTrackingFailed);
  }

  final GetSavedOfficeLocationUseCase _getSavedOfficeLocation;
  final SaveOfficeLocationUseCase _saveOfficeLocation;
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

    if (savedOfficeLocation != null) {
      await _refreshLocationTracking(savedOfficeLocation, emit);
    }
  }

  Future<void> _onOfficeLocationRequested(
    OfficeLocationRequested event,
    Emitter<AttendanceState> emit,
  ) async {
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
      _emitLocationError(error, emit);
    }
  }

  Future<void> _onLocationTrackingRetried(
    LocationTrackingRetried event,
    Emitter<AttendanceState> emit,
  ) async {
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

    await _refreshLocationTracking(officeLocation, emit);
  }

  void _onAttendanceMarked(
    AttendanceMarked event,
    Emitter<AttendanceState> emit,
  ) {
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

  Future<void> _refreshLocationTracking(
    GeoPoint officeLocation,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final currentLocation = await _getCurrentLocation();
      _updateDistance(
        officeLocation: officeLocation,
        currentLocation: currentLocation,
        emit: emit,
      );

      emit(
        state.copyWith(
          status: AttendanceViewStatus.ready,
          clearLocationErrorType: true,
        ),
      );

      await _subscribeToLocationUpdates(officeLocation);
    } on LocationException catch (error) {
      _emitLocationError(error, emit);
    }
  }

  Future<void> _subscribeToLocationUpdates(GeoPoint officeLocation) async {
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

  void _emitLocationError(LocationException error, Emitter<AttendanceState> emit) {
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
