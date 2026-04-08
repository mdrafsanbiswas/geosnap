import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/upload_status.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import '../constants/camera_sync_ui_color.dart';
import '../constants/camera_sync_ui_text.dart';

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
