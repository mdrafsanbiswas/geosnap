import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/upload_status.dart';
import '../../bloc/upload_queue/upload_queue_bloc.dart';
import '../../bloc/upload_queue/upload_queue_state.dart';
import '../../constants/camera_sync_ui_text.dart';

class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    required this.isFlashEnabled,
    required this.onToggleFlash,
    super.key,
  });

  final bool isFlashEnabled;
  final VoidCallback onToggleFlash;

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
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: [
                      _TopActionButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Icons.close_rounded,
                      ),
                      const Spacer(),
                      _TopActionButton(
                        onPressed: onToggleFlash,
                        icon: isFlashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        isActive: isFlashEnabled,
                      ),
                    ],
                  ),
                ],
              ),
              if (showQueueBanner) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                  child: DecoratedBox(
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
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.onPressed,
    required this.icon,
    this.isActive = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkResponse(
          onTap: onPressed,
          radius: 21,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.amber.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                icon,
                color: onPressed == null
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.white,
                size: 17,
              ),
            ),
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
