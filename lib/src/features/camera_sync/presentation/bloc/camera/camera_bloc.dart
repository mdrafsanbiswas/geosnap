import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
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
    on<CameraPhotoRemoved>(_onPhotoRemoved);
    on<CameraBatchCleared>(_onBatchCleared);
    on<CameraMessageCleared>(_onMessageCleared);
  }

  CameraController? _cameraController;

  CameraController? get cameraController => _cameraController;

  Future<void> _onInitialized(
    CameraInitialized event,
    Emitter<CameraState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CameraViewStatus.loading,
        clearMessage: true,
      ),
    );

    await _disposeController();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        emit(
          state.copyWith(
            status: CameraViewStatus.error,
            message: 'No camera hardware was found on this device.',
          ),
        );
        return;
      }

      final selectedCamera = cameras
              .where((camera) => camera.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.first;

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

      emit(
        state.copyWith(
          status: CameraViewStatus.ready,
          minZoom: minZoom,
          maxZoom: maxZoom,
          currentZoom: initialZoom,
          zoomPresets: _buildZoomPresets(minZoom, maxZoom),
          clearMessage: true,
        ),
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

    try {
      await controller.setFocusPoint(normalizedPoint);
      try {
        await controller.setExposurePoint(normalizedPoint);
      } catch (_) {
        // Exposure point controls can be unsupported on some devices.
      }

      final markerId = state.focusMarkerId + 1;
      emit(
        state.copyWith(
          focusPoint: event.tapPosition,
          focusMarkerId: markerId,
        ),
      );

      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!isClosed) {
            add(CameraFocusIndicatorCleared(markerId));
          }
        }),
      );
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
          message: 'Photo added to the batch (${nextBatch.length}).',
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

    emit(
      state.copyWith(
        capturedPhotoPaths: const [],
        clearFocusPoint: true,
      ),
    );
  }

  void _onMessageCleared(CameraMessageCleared event, Emitter<CameraState> emit) {
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

    final clampedZoom = requestedZoom.clamp(state.minZoom, state.maxZoom);
    final nextZoom = clampedZoom is double
        ? clampedZoom
        : (clampedZoom as num).toDouble();

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

  Future<String> _persistCapturedFile(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(p.join(directory.path, 'captured_batches'));
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
    final candidates = [0.5, 1, 2, 3, 5]
        .where((zoom) => zoom >= minZoom && zoom <= maxZoom)
        .toSet();

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
