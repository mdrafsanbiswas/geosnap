import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_event.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import '../components/camera_preview_components.dart';
import '../constants/camera_sync_ui_color.dart';
import '../constants/camera_sync_ui_text.dart';
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
        backgroundColor: CameraSyncUiColor.cameraSurface,
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
                return CameraErrorView(
                  message: state.message ?? CameraSyncUiText.cameraUnavailable,
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
                      child: CameraPreviewLayer(
                        controller: controller,
                        previewKey: _previewKey,
                      ),
                    ),
                    const Positioned.fill(child: CameraOverlay()),
                    CameraTopBar(onOpenUploadManager: _openUploadManager),
                    Positioned(
                      right: 8,
                      top: 110,
                      bottom: 200,
                      child: ZoomRail(
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
                      child: CameraBottomControls(
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

  PreviewTapDetails? _resolvePreviewTap(Offset globalPosition) {
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

    return PreviewTapDetails(
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
          const SnackBar(content: Text(CameraSyncUiText.captureBeforeUpload)),
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
