import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
