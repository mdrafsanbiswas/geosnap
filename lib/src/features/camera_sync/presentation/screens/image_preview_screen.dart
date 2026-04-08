import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    required this.filePaths,
    this.initialIndex = 0,
    this.title = 'Image Preview',
    super.key,
  });

  final List<String> filePaths;
  final int initialIndex;
  final String title;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  static const List<double> _tapZoomSteps = [1.35, 1.75, 2.2, 2.7, 3.2, 3.8];

  final TransformationController _transformationController =
      TransformationController();

  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  Offset? _tapMarkerPoint;
  int _tapMarkerId = 0;
  Timer? _tapMarkerTimer;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          final animation = _zoomAnimation;
          if (animation == null) {
            return;
          }
          _transformationController.value = animation.value;
        });
  }

  @override
  void dispose() {
    _tapMarkerTimer?.cancel();
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onImageTapped(TapUpDetails details) {
    final localTapPoint = details.localPosition;
    _showTapMarker(localTapPoint);

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = _nextTapZoomScale(currentScale);
    final targetMatrix = _buildZoomMatrix(localTapPoint, targetScale);
    _animateToMatrix(targetMatrix);
  }

  double _nextTapZoomScale(double currentScale) {
    for (final zoomStep in _tapZoomSteps) {
      if (zoomStep > currentScale + 0.05) {
        return zoomStep;
      }
    }
    return 4;
  }

  Matrix4 _buildZoomMatrix(Offset focalPoint, double targetScale) {
    return Matrix4.diagonal3Values(targetScale, targetScale, 1)
      ..setTranslationRaw(
        -focalPoint.dx * (targetScale - 1),
        -focalPoint.dy * (targetScale - 1),
        0,
      );
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _zoomAnimationController.stop();
    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value.clone(),
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _zoomAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _zoomAnimationController
      ..reset()
      ..forward();
  }

  void _showTapMarker(Offset point) {
    _tapMarkerTimer?.cancel();
    final markerId = ++_tapMarkerId;
    setState(() {
      _tapMarkerPoint = point;
    });

    _tapMarkerTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted || markerId != _tapMarkerId) {
        return;
      }
      setState(() {
        _tapMarkerPoint = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePaths.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 56,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 34,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          title: Text(widget.title),
        ),
        body: const Center(child: Text('No image available.')),
      );
    }

    final currentPath = widget
        .filePaths[_safeIndex(widget.initialIndex, widget.filePaths.length)];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leadingWidth: 56,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left_rounded),
          iconSize: 34,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        ),
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onImageTapped,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Image.file(
                    File(currentPath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white60,
                            size: 42,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Unable to load this image.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_tapMarkerPoint != null)
                    Positioned(
                      left: _tapMarkerPoint!.dx - 24,
                      top: _tapMarkerPoint!.dy - 24,
                      child: IgnorePointer(
                        child: _TapMarker(markerId: _tapMarkerId),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _safeIndex(int requested, int length) {
    if (length <= 0) {
      return 0;
    }
    if (requested < 0) {
      return 0;
    }
    if (requested >= length) {
      return length - 1;
    }
    return requested;
  }
}

class _TapMarker extends StatelessWidget {
  const _TapMarker({required this.markerId});

  final int markerId;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(markerId),
      tween: Tween<double>(begin: 0.75, end: 1.05),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFE27A), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, size: 16, color: Color(0xFFFFE27A)),
        ),
      ),
    );
  }
}
