import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/camera/camera_bloc.dart';
import '../../bloc/camera/camera_event.dart';
import '../../bloc/camera/camera_state.dart';
import '../../constants/camera_sync_ui_color.dart';
import '../../constants/camera_sync_ui_text.dart';

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
