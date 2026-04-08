import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/upload_status.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import '../constants/camera_sync_ui_color.dart';
import '../constants/camera_sync_ui_text.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

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

class CameraPreviewLayer extends StatelessWidget {
  const CameraPreviewLayer({
    required this.controller,
    required this.previewKey,
    super.key,
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

class CameraErrorView extends StatelessWidget {
  const CameraErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

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
            FilledButton(
              onPressed: onRetry,
              child: const Text(CameraSyncUiText.retryCamera),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({required this.onOpenUploadManager, super.key});

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
            ? CameraSyncUiText.offlineQueued(summary.queuedCount)
            : summary.uploadingCount > 0
            ? CameraSyncUiText.uploadingProgress(
                summary.uploadingCount,
                summary.queuedCount,
              )
            : CameraSyncUiText.queuedPending(summary.queuedCount);

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
                                color: CameraSyncUiColor.queueBadge,
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

class PreviewTapDetails {
  const PreviewTapDetails({
    required this.localPosition,
    required this.previewSize,
  });

  final Offset localPosition;
  final Size previewSize;
}

class ZoomRail extends StatelessWidget {
  const ZoomRail({
    required this.minZoom,
    required this.maxZoom,
    required this.currentZoom,
    required this.onChanged,
    super.key,
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

class CameraBottomControls extends StatelessWidget {
  const CameraBottomControls({
    required this.state,
    required this.onOpenBatchPreview,
    required this.onCapture,
    required this.onLensSelected,
    required this.onUploadCurrentBatch,
    super.key,
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
            backgroundColor: CameraSyncUiColor.queueBadge,
          ),
          onPressed: onUploadCurrentBatch,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text(
            CameraSyncUiText.uploadBatch(state.capturedPhotoPaths.length),
          ),
        ),
      ],
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
          color: selected ? Colors.white : CameraSyncUiColor.zoomPresetBg,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? CameraSyncUiColor.zoomPresetSelectedText
                : Colors.white70,
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
        backgroundColor: CameraSyncUiColor.switchButtonBg,
        disabledBackgroundColor: CameraSyncUiColor.switchButtonDisabledBg,
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
                color: CameraSyncUiColor.queueBadge,
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
