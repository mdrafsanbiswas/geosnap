import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

enum CameraViewStatus {
  initial,
  loading,
  ready,
  captureInProgress,
  permissionDenied,
  error,
}

class CameraState extends Equatable {
  const CameraState({
    this.status = CameraViewStatus.initial,
    this.minZoom = 1,
    this.maxZoom = 1,
    this.currentZoom = 1,
    this.zoomPresets = const [1],
    this.capturedPhotoPaths = const [],
    this.focusPoint,
    this.focusMarkerId = 0,
    this.message,
  });

  final CameraViewStatus status;
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final List<double> zoomPresets;
  final List<String> capturedPhotoPaths;
  final Offset? focusPoint;
  final int focusMarkerId;
  final String? message;

  bool get isReady =>
      status == CameraViewStatus.ready ||
      status == CameraViewStatus.captureInProgress;

  bool get canCapture => status == CameraViewStatus.ready;

  CameraState copyWith({
    CameraViewStatus? status,
    double? minZoom,
    double? maxZoom,
    double? currentZoom,
    List<double>? zoomPresets,
    List<String>? capturedPhotoPaths,
    Offset? focusPoint,
    int? focusMarkerId,
    String? message,
    bool clearFocusPoint = false,
    bool clearMessage = false,
  }) {
    return CameraState(
      status: status ?? this.status,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      zoomPresets: zoomPresets ?? this.zoomPresets,
      capturedPhotoPaths: capturedPhotoPaths ?? this.capturedPhotoPaths,
      focusPoint: clearFocusPoint ? null : focusPoint ?? this.focusPoint,
      focusMarkerId: focusMarkerId ?? this.focusMarkerId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    minZoom,
    maxZoom,
    currentZoom,
    zoomPresets,
    capturedPhotoPaths,
    focusPoint,
    focusMarkerId,
    message,
  ];
}
