import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class CameraInitialized extends CameraEvent {
  const CameraInitialized();
}

class CameraRetried extends CameraEvent {
  const CameraRetried();
}

class CameraZoomChanged extends CameraEvent {
  const CameraZoomChanged(this.zoomLevel);

  final double zoomLevel;

  @override
  List<Object?> get props => [zoomLevel];
}

class CameraZoomPresetSelected extends CameraEvent {
  const CameraZoomPresetSelected(this.zoomLevel);

  final double zoomLevel;

  @override
  List<Object?> get props => [zoomLevel];
}

class CameraFocusPointRequested extends CameraEvent {
  const CameraFocusPointRequested({
    required this.tapPosition,
    required this.previewSize,
  });

  final Offset tapPosition;
  final Size previewSize;

  @override
  List<Object?> get props => [tapPosition, previewSize];
}

class CameraFocusIndicatorCleared extends CameraEvent {
  const CameraFocusIndicatorCleared(this.markerId);

  final int markerId;

  @override
  List<Object?> get props => [markerId];
}

class CameraCaptureRequested extends CameraEvent {
  const CameraCaptureRequested();
}

class CameraPhotoRemoved extends CameraEvent {
  const CameraPhotoRemoved(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class CameraBatchCleared extends CameraEvent {
  const CameraBatchCleared({this.deleteFiles = false});

  final bool deleteFiles;

  @override
  List<Object?> get props => [deleteFiles];
}

class CameraMessageCleared extends CameraEvent {
  const CameraMessageCleared();
}
