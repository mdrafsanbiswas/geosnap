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
import '../../domain/entities/upload_status.dart';
import 'batch_preview_screen.dart';
import 'upload_manager_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  double _baseZoom = 1;
  final GlobalKey _previewKey = GlobalKey();

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

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (_) => _baseZoom = state.currentZoom,
                onScaleUpdate: (details) {
                  context.read<CameraBloc>().add(
                    CameraZoomChanged(_baseZoom * details.scale),
                  );
                },
                onTapDown: (details) {
                  final previewTapDetails = _resolvePreviewTap(
                    details.globalPosition,
                  );
                  if (previewTapDetails == null) {
                    return;
                  }
                  context.read<CameraBloc>().add(
                    CameraFocusPointRequested(
                      tapPosition: previewTapDetails.localPosition,
                      previewSize: previewTapDetails.previewSize,
                      indicatorPosition: details.localPosition,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _CameraPreviewLayer(
                        controller: controller,
                        previewKey: _previewKey,
                      ),
                    ),
                    const Positioned.fill(child: _CameraOverlay()),
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
                        onLensSelected: (lensDirection) => context
                            .read<CameraBloc>()
                            .add(CameraLensSelected(lensDirection)),
                        onUploadCurrentBatch: () =>
                            _uploadCurrentBatch(state.capturedPhotoPaths),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _PreviewTapDetails? _resolvePreviewTap(Offset globalPosition) {
    final previewContext = _previewKey.currentContext;
    if (previewContext == null) {
      return null;
    }

    final renderObject = previewContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    final previewSize = renderObject.size;
    final isInsidePreview =
        localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= previewSize.width &&
        localPosition.dy <= previewSize.height;
    if (!isInsidePreview) {
      return null;
    }

    return _PreviewTapDetails(
      localPosition: localPosition,
      previewSize: previewSize,
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

class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer({
    required this.controller,
    required this.previewKey,
  });

  final CameraController controller;
  final GlobalKey previewKey;

  @override
  Widget build(BuildContext context) {
    final rawPreviewSize = controller.value.previewSize;
    final fallbackAspectRatio = controller.value.aspectRatio <= 0
        ? 1.0
        : 1 / controller.value.aspectRatio;
    final previewAspectRatio =
        rawPreviewSize == null ||
            rawPreviewSize.width <= 0 ||
            rawPreviewSize.height <= 0
        ? fallbackAspectRatio
        : rawPreviewSize.height / rawPreviewSize.width;

    return Center(
      child: AspectRatio(
        key: previewKey,
        aspectRatio: previewAspectRatio <= 0
            ? fallbackAspectRatio
            : previewAspectRatio,
        child: CameraPreview(controller),
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
    return BlocSelector<UploadQueueBloc, UploadQueueState, _QueueSummary>(
      selector: (state) {
        final queuedCount = state.items
            .where((item) => item.status != UploadStatus.uploaded)
            .length;
        return _QueueSummary(
          queuedCount: queuedCount,
          uploadingCount: state.uploadingCount,
          isOnline: state.isOnline,
        );
      },
      builder: (context, summary) {
        final showQueueBanner = summary.queuedCount > 0;
        final queueMessage = !summary.isOnline
            ? 'Offline: ${summary.queuedCount} upload${summary.queuedCount == 1 ? '' : 's'} queued'
            : summary.uploadingCount > 0
            ? 'Uploading ${summary.uploadingCount} of ${summary.queuedCount} queued item${summary.queuedCount == 1 ? '' : 's'}'
            : '${summary.queuedCount} upload${summary.queuedCount == 1 ? '' : 's'} pending in queue';

        return Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: Colors.white,
                    iconSize: 34,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: onOpenUploadManager,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.file_upload_outlined),
                        if (summary.queuedCount > 0)
                          Positioned(
                            right: -10,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B79FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${summary.queuedCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showQueueBanner) ...[
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          summary.isOnline
                              ? Icons.cloud_upload_rounded
                              : Icons.cloud_off_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            queueMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QueueSummary {
  const _QueueSummary({
    required this.queuedCount,
    required this.uploadingCount,
    required this.isOnline,
  });

  final int queuedCount;
  final int uploadingCount;
  final bool isOnline;

  @override
  bool operator ==(Object other) {
    return other is _QueueSummary &&
        other.queuedCount == queuedCount &&
        other.uploadingCount == uploadingCount &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode => Object.hash(queuedCount, uploadingCount, isOnline);
}

class _PreviewTapDetails {
  const _PreviewTapDetails({
    required this.localPosition,
    required this.previewSize,
  });

  final Offset localPosition;
  final Size previewSize;
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
    required this.onLensSelected,
    required this.onUploadCurrentBatch,
  });

  final CameraState state;
  final VoidCallback onOpenBatchPreview;
  final VoidCallback onCapture;
  final ValueChanged<CameraLensDirection> onLensSelected;
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
                (preset) => _ZoomPresetButton(
                  label: '${preset.toStringAsFixed(preset >= 1 ? 0 : 1)}x',
                  selected: (state.currentZoom - preset).abs() < 0.2,
                  onTap: () => context.read<CameraBloc>().add(
                    CameraZoomPresetSelected(preset),
                  ),
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
                photoCount: state.capturedPhotoPaths.length,
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
            _CameraSwitchButton(
              canSwitchCamera: state.hasFrontLens && state.hasBackLens,
              onPressed: () {
                final nextDirection =
                    state.selectedLensDirection == CameraLensDirection.back
                    ? CameraLensDirection.front
                    : CameraLensDirection.back;
                onLensSelected(nextDirection);
              },
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

class _ZoomPresetButton extends StatelessWidget {
  const _ZoomPresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? Colors.white : const Color(0xCC3A4047),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1A1D20) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CameraSwitchButton extends StatelessWidget {
  const _CameraSwitchButton({
    required this.canSwitchCamera,
    required this.onPressed,
  });

  final bool canSwitchCamera;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: canSwitchCamera ? onPressed : null,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xCC3A4047),
        disabledBackgroundColor: const Color(0x803A4047),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.cameraswitch_rounded),
    );
  }
}

class _GalleryBubble extends StatelessWidget {
  const _GalleryBubble({required this.photoPath, required this.photoCount});

  final String? photoPath;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
        ),
        if (photoCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2B79FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Text(
                '$photoCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
