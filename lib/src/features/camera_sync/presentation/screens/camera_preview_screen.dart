import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_event.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import 'batch_preview_screen.dart';
import 'upload_manager_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  double _baseZoom = 1;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CameraBloc, CameraState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            final message = state.message;
            if (message == null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<CameraBloc>().add(const CameraMessageCleared());
          },
        ),
        BlocListener<UploadQueueBloc, UploadQueueState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            final message = state.message;
            if (message == null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<UploadQueueBloc>().add(
              const UploadQueueMessageCleared(),
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: BlocBuilder<CameraBloc, CameraState>(
            builder: (context, state) {
              final cameraBloc = context.read<CameraBloc>();
              final controller = cameraBloc.cameraController;

              if (state.status == CameraViewStatus.loading ||
                  state.status == CameraViewStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == CameraViewStatus.permissionDenied ||
                  state.status == CameraViewStatus.error ||
                  controller == null ||
                  !controller.value.isInitialized) {
                return _CameraErrorView(
                  message: state.message ?? 'Camera is unavailable.',
                  onRetry: () =>
                      context.read<CameraBloc>().add(const CameraRetried()),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (_) => _baseZoom = state.currentZoom,
                    onScaleUpdate: (details) {
                      context.read<CameraBloc>().add(
                        CameraZoomChanged(_baseZoom * details.scale),
                      );
                    },
                    onTapUp: (details) {
                      context.read<CameraBloc>().add(
                        CameraFocusPointRequested(
                          tapPosition: details.localPosition,
                          previewSize: previewSize,
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(child: CameraPreview(controller)),
                        const Positioned.fill(child: _CameraOverlay()),
                        if (state.focusPoint != null)
                          Positioned(
                            left: state.focusPoint!.dx - 28,
                            top: state.focusPoint!.dy - 28,
                            child: IgnorePointer(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    width: 1.7,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        _TopBar(onOpenUploadManager: _openUploadManager),
                        Positioned(
                          right: 8,
                          top: 110,
                          bottom: 200,
                          child: _ZoomRail(
                            minZoom: state.minZoom,
                            maxZoom: state.maxZoom,
                            currentZoom: state.currentZoom,
                            onChanged: (zoom) => context.read<CameraBloc>().add(
                              CameraZoomChanged(zoom),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 18,
                          child: _BottomControls(
                            state: state,
                            onOpenBatchPreview: _openBatchPreview,
                            onCapture: () => context.read<CameraBloc>().add(
                              const CameraCaptureRequested(),
                            ),
                            onOpenUploadManager: _openUploadManager,
                            onUploadCurrentBatch: () =>
                                _uploadCurrentBatch(state.capturedPhotoPaths),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openBatchPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: this.context.read<CameraBloc>(),
          child: const BatchPreviewScreen(),
        ),
      ),
    );
  }

  void _openUploadManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: this.context.read<UploadQueueBloc>(),
          child: const UploadManagerScreen(),
        ),
      ),
    );
  }

  void _uploadCurrentBatch(List<String> paths) {
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Capture photos before uploading.')),
        );
      return;
    }

    context.read<UploadQueueBloc>().add(
      UploadQueueBatchEnqueued(filePaths: paths),
    );
    context.read<CameraBloc>().add(const CameraBatchCleared());
    _openUploadManager();
  }
}

class _CameraOverlay extends StatelessWidget {
  const _CameraOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.62),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white70,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry Camera')),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenUploadManager});

  final VoidCallback onOpenUploadManager;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: onOpenUploadManager,
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
    );
  }
}

class _ZoomRail extends StatelessWidget {
  const _ZoomRail({
    required this.minZoom,
    required this.maxZoom,
    required this.currentZoom,
    required this.onChanged,
  });

  final double minZoom;
  final double maxZoom;
  final double currentZoom;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: SizedBox(
        width: 180,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: currentZoom.clamp(minZoom, maxZoom),
            min: minZoom,
            max: maxZoom,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.state,
    required this.onOpenBatchPreview,
    required this.onCapture,
    required this.onOpenUploadManager,
    required this.onUploadCurrentBatch,
  });

  final CameraState state;
  final VoidCallback onOpenBatchPreview;
  final VoidCallback onCapture;
  final VoidCallback onOpenUploadManager;
  final VoidCallback onUploadCurrentBatch;

  @override
  Widget build(BuildContext context) {
    final hasBatch = state.capturedPhotoPaths.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: state.zoomPresets
              .map(
                (preset) => ChoiceChip(
                  selected: (state.currentZoom - preset).abs() < 0.2,
                  label: Text(
                    '${preset.toStringAsFixed(preset >= 1 ? 0 : 1)}x',
                  ),
                  onSelected: (_) => context.read<CameraBloc>().add(
                    CameraZoomPresetSelected(preset),
                  ),
                  labelStyle: const TextStyle(color: Colors.white),
                  selectedColor: const Color(0xFF2F6CFF),
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: hasBatch ? onOpenBatchPreview : null,
              child: _GalleryBubble(
                photoPath: hasBatch ? state.capturedPhotoPaths.last : null,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: state.canCapture ? onCapture : null,
              child: Container(
                width: 74,
                height: 74,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.status == CameraViewStatus.captureInProgress
                        ? Colors.white54
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: onOpenUploadManager,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color(0xFF2B79FF),
          ),
          onPressed: onUploadCurrentBatch,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text('Upload Batch (${state.capturedPhotoPaths.length})'),
        ),
      ],
    );
  }
}

class _GalleryBubble extends StatelessWidget {
  const _GalleryBubble({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: photoPath == null
          ? const Icon(Icons.photo_library_outlined, color: Colors.white54)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
    );
  }
}
