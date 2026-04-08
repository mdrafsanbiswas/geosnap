import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(const CameraState()) {
    on<CameraInitialized>(_onInitialized);
    on<CameraRetried>(_onRetried);
    on<CameraZoomChanged>(_onZoomChanged);
    on<CameraZoomPresetSelected>(_onZoomPresetSelected);
    on<CameraFocusPointRequested>(_onFocusPointRequested);
    on<CameraFocusIndicatorCleared>(_onFocusIndicatorCleared);
    on<CameraCaptureRequested>(_onCaptureRequested);
    on<CameraFlashToggled>(_onFlashToggled);
    on<CameraLensSelected>(_onLensSelected);
    on<CameraPhotoRemoved>(_onPhotoRemoved);
    on<CameraBatchCleared>(_onBatchCleared);
    on<CameraMessageCleared>(_onMessageCleared);
  }

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];

  CameraController? get cameraController => _cameraController;

  Future<void> _onInitialized(
    CameraInitialized event,
    Emitter<CameraState> emit,
  ) async {
    emit(state.copyWith(status: CameraViewStatus.loading, clearMessage: true));

    await _disposeController();

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        emit(
          state.copyWith(
            status: CameraViewStatus.error,
            message: 'No camera hardware was found on this device.',
          ),
        );
        return;
      }

      final selectedCamera =
          _findCameraForDirection(CameraLensDirection.back) ??
          _availableCameras.first;
      await _initializeControllerForCamera(
        selectedCamera,
        emit,
        clearMessage: true,
      );
    } on CameraException catch (error) {
      emit(
        state.copyWith(
          status: _isPermissionError(error)
              ? CameraViewStatus.permissionDenied
              : CameraViewStatus.error,
          message: _messageForCameraError(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CameraViewStatus.error,
          message: 'Unable to initialize camera right now.',
        ),
      );
    }
  }

  Future<void> _onRetried(
    CameraRetried event,
    Emitter<CameraState> emit,
  ) async {
    await _onInitialized(const CameraInitialized(), emit);
  }

  Future<void> _onLensSelected(
    CameraLensSelected event,
    Emitter<CameraState> emit,
  ) async {
    final currentController = _cameraController;
    if (currentController?.value.isTakingPicture ?? false) {
      return;
    }

    if (_availableCameras.isEmpty) {
      return;
    }

    final selectedCamera = _findCameraForDirection(event.lensDirection);
    if (selectedCamera == null) {
      emit(
        state.copyWith(
          message: 'Selected camera lens is not available on this device.',
        ),
      );
      return;
    }

    if (state.selectedLensDirection == selectedCamera.lensDirection &&
        currentController != null &&
        currentController.value.isInitialized) {
      return;
    }

    emit(
      state.copyWith(
        status: CameraViewStatus.loading,
        clearMessage: true,
        clearFocusPoint: true,
      ),
    );

    await _disposeController();

    try {
      await _initializeControllerForCamera(
        selectedCamera,
        emit,
        clearMessage: true,
      );
    } on CameraException catch (error) {
      emit(
        state.copyWith(
          status: _isPermissionError(error)
              ? CameraViewStatus.permissionDenied
              : CameraViewStatus.error,
          message: _messageForCameraError(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CameraViewStatus.error,
          message: 'Unable to switch camera right now.',
        ),
      );
    }
  }

  Future<void> _onZoomChanged(
    CameraZoomChanged event,
    Emitter<CameraState> emit,
  ) async {
    await _setZoom(event.zoomLevel, emit);
  }

  Future<void> _onZoomPresetSelected(
    CameraZoomPresetSelected event,
    Emitter<CameraState> emit,
  ) async {
    await _setZoom(event.zoomLevel, emit);
  }

  Future<void> _onFocusPointRequested(
    CameraFocusPointRequested event,
    Emitter<CameraState> emit,
  ) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final previewWidth = event.previewSize.width;
    final previewHeight = event.previewSize.height;
    if (previewWidth <= 0 || previewHeight <= 0) {
      return;
    }

    final normalizedPoint = Offset(
      (event.tapPosition.dx / previewWidth).clamp(0, 1).toDouble(),
      (event.tapPosition.dy / previewHeight).clamp(0, 1).toDouble(),
    );

    final markerId = state.focusMarkerId + 1;
    emit(
      state.copyWith(
        focusPoint: event.indicatorPosition ?? event.tapPosition,
        focusMarkerId: markerId,
      ),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1300), () {
        if (!isClosed) {
          add(CameraFocusIndicatorCleared(markerId));
        }
      }),
    );

    try {
      await controller.setFocusPoint(normalizedPoint);
      try {
        await controller.setExposurePoint(normalizedPoint);
      } catch (_) {
        // Exposure point controls can be unsupported on some devices.
      }
    } catch (_) {
      // Keep tap-to-focus best-effort and non-blocking for UX.
    }
  }

  void _onFocusIndicatorCleared(
    CameraFocusIndicatorCleared event,
    Emitter<CameraState> emit,
  ) {
    if (event.markerId != state.focusMarkerId) {
      return;
    }

    emit(state.copyWith(clearFocusPoint: true));
  }

  Future<void> _onCaptureRequested(
    CameraCaptureRequested event,
    Emitter<CameraState> emit,
  ) async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        state.status == CameraViewStatus.captureInProgress) {
      return;
    }

    emit(
      state.copyWith(
        status: CameraViewStatus.captureInProgress,
        clearMessage: true,
      ),
    );

    try {
      final capturedFile = await controller.takePicture();
      final persistedPath = await _persistCapturedFile(capturedFile.path);
      final nextBatch = [...state.capturedPhotoPaths, persistedPath];

      emit(
        state.copyWith(
          status: CameraViewStatus.ready,
          capturedPhotoPaths: nextBatch,
          clearMessage: true,
        ),
      );
    } on CameraException catch (error) {
      emit(
        state.copyWith(
          status: CameraViewStatus.ready,
          message: _messageForCameraError(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CameraViewStatus.ready,
          message: 'Capture failed. Please try again.',
        ),
      );
    }
  }

  Future<void> _onFlashToggled(
    CameraFlashToggled event,
    Emitter<CameraState> emit,
  ) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextFlashMode = state.isFlashEnabled
        ? FlashMode.off
        : FlashMode.torch;
    try {
      await controller.setFlashMode(nextFlashMode);
      emit(
        state.copyWith(
          isFlashEnabled: !state.isFlashEnabled,
          clearMessage: true,
        ),
      );
    } on CameraException catch (_) {
      emit(
        state.copyWith(
          message: 'Flash is not available for the current camera lens.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(message: 'Unable to change flash mode right now.'));
    }
  }

  Future<void> _onPhotoRemoved(
    CameraPhotoRemoved event,
    Emitter<CameraState> emit,
  ) async {
    final nextBatch = [...state.capturedPhotoPaths]..remove(event.filePath);
    try {
      final file = File(event.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore file cleanup failures and still keep UI responsive.
    }

    emit(
      state.copyWith(
        capturedPhotoPaths: nextBatch,
        message: 'Photo removed from this batch.',
      ),
    );
  }

  Future<void> _onBatchCleared(
    CameraBatchCleared event,
    Emitter<CameraState> emit,
  ) async {
    if (event.deleteFiles) {
      for (final filePath in state.capturedPhotoPaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // Best-effort cleanup only.
        }
      }
    }

    emit(state.copyWith(capturedPhotoPaths: const [], clearFocusPoint: true));
  }

  void _onMessageCleared(
    CameraMessageCleared event,
    Emitter<CameraState> emit,
  ) {
    if (state.message == null) {
      return;
    }

    emit(state.copyWith(clearMessage: true));
  }

  Future<void> _setZoom(double requestedZoom, Emitter<CameraState> emit) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextZoom = requestedZoom
        .clamp(state.minZoom, state.maxZoom)
        .toDouble();

    if ((nextZoom - state.currentZoom).abs() < 0.01) {
      return;
    }

    try {
      await controller.setZoomLevel(nextZoom);
      emit(state.copyWith(currentZoom: nextZoom));
    } catch (_) {
      // Zoom failures should not crash the camera flow.
    }
  }

  Future<void> _initializeControllerForCamera(
    CameraDescription selectedCamera,
    Emitter<CameraState> emit, {
    bool clearMessage = false,
  }) async {
    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;
    await controller.initialize();

    final minZoom = await controller.getMinZoomLevel();
    final maxZoom = await controller.getMaxZoomLevel();
    final initialZoom = 1.0.clamp(minZoom, maxZoom).toDouble();
    await controller.setZoomLevel(initialZoom);
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {
      // Not all devices expose focus mode controls consistently.
    }
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // Flash mode controls can be unavailable on some lenses/devices.
    }

    final hasFrontLens = _availableCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    final hasBackLens = _availableCameras.any(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    emit(
      state.copyWith(
        status: CameraViewStatus.ready,
        minZoom: minZoom,
        maxZoom: maxZoom,
        currentZoom: initialZoom,
        isFlashEnabled: false,
        zoomPresets: _buildZoomPresets(minZoom, maxZoom),
        selectedLensDirection: selectedCamera.lensDirection,
        hasFrontLens: hasFrontLens,
        hasBackLens: hasBackLens,
        clearFocusPoint: true,
        clearMessage: clearMessage,
      ),
    );
  }

  CameraDescription? _findCameraForDirection(CameraLensDirection direction) {
    return _availableCameras
        .where((camera) => camera.lensDirection == direction)
        .firstOrNull;
  }

  Future<String> _persistCapturedFile(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(
      p.join(directory.path, 'captured_batches'),
    );
    if (!await captureDirectory.exists()) {
      await captureDirectory.create(recursive: true);
    }

    final fileName =
        'img_${DateTime.now().microsecondsSinceEpoch}${p.extension(sourcePath)}';
    final savedPath = p.join(captureDirectory.path, fileName);
    final sourceFile = File(sourcePath);
    final copied = await sourceFile.copy(savedPath);
    return copied.path;
  }

  List<double> _buildZoomPresets(double minZoom, double maxZoom) {
    final candidates = <double>{};
    for (final zoom in [0.5, 1.0, 2.0, 3.0, 5.0]) {
      if (zoom >= minZoom && zoom <= maxZoom) {
        candidates.add(zoom);
      }
    }

    if (candidates.isEmpty) {
      candidates.add(1.0.clamp(minZoom, maxZoom).toDouble());
    }

    return candidates.toList(growable: false)..sort();
  }

  bool _isPermissionError(CameraException error) {
    return error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted';
  }

  String _messageForCameraError(CameraException error) {
    if (_isPermissionError(error)) {
      return 'Camera permission is required to capture attendance photos.';
    }

    return 'Camera error: ${error.description ?? error.code}';
  }

  Future<void> _disposeController() async {
    final existing = _cameraController;
    _cameraController = null;
    if (existing != null) {
      await existing.dispose();
    }
  }

  @override
  Future<void> close() async {
    await _disposeController();
    return super.close();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
