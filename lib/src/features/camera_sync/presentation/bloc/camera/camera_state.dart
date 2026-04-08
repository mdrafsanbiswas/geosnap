import 'package:camera/camera.dart';
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
    this.isFlashEnabled = false,
    this.zoomPresets = const [1],
    this.capturedPhotoPaths = const [],
    this.focusPoint,
    this.focusMarkerId = 0,
    this.selectedLensDirection = CameraLensDirection.back,
    this.hasFrontLens = false,
    this.hasBackLens = false,
    this.message,
  });

  final CameraViewStatus status;
  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final bool isFlashEnabled;
  final List<double> zoomPresets;
  final List<String> capturedPhotoPaths;
  final Offset? focusPoint;
  final int focusMarkerId;
  final CameraLensDirection selectedLensDirection;
  final bool hasFrontLens;
  final bool hasBackLens;
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
    bool? isFlashEnabled,
    List<double>? zoomPresets,
    List<String>? capturedPhotoPaths,
    Offset? focusPoint,
    int? focusMarkerId,
    CameraLensDirection? selectedLensDirection,
    bool? hasFrontLens,
    bool? hasBackLens,
    String? message,
    bool clearFocusPoint = false,
    bool clearMessage = false,
  }) {
    return CameraState(
      status: status ?? this.status,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      isFlashEnabled: isFlashEnabled ?? this.isFlashEnabled,
      zoomPresets: zoomPresets ?? this.zoomPresets,
      capturedPhotoPaths: capturedPhotoPaths ?? this.capturedPhotoPaths,
      focusPoint: clearFocusPoint ? null : focusPoint ?? this.focusPoint,
      focusMarkerId: focusMarkerId ?? this.focusMarkerId,
      selectedLensDirection:
          selectedLensDirection ?? this.selectedLensDirection,
      hasFrontLens: hasFrontLens ?? this.hasFrontLens,
      hasBackLens: hasBackLens ?? this.hasBackLens,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    minZoom,
    maxZoom,
    currentZoom,
    isFlashEnabled,
    zoomPresets,
    capturedPhotoPaths,
    focusPoint,
    focusMarkerId,
    selectedLensDirection,
    hasFrontLens,
    hasBackLens,
    message,
  ];
}
