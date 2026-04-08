import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import '../constants/camera_sync_ui_color.dart';
import '../constants/camera_sync_ui_text.dart';

class EmptyUploadState extends StatelessWidget {
  const EmptyUploadState({required this.isOnline, super.key});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final statusText = isOnline
        ? CameraSyncUiText.emptyUploadsOnlineBody
        : CameraSyncUiText.emptyUploadsOfflineBody;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: CameraSyncUiColor.panelSurface,
            border: Border.all(color: CameraSyncUiColor.panelBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload_outlined, color: Colors.white70),
              const SizedBox(height: 12),
              const Text(
                CameraSyncUiText.emptyUploadsTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadSummaryCard extends StatelessWidget {
  const UploadSummaryCard({required this.state, super.key});

  final UploadQueueState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: CameraSyncUiColor.panelSurface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                CameraSyncUiText.batchSyncProgress,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: state.isOnline
                      ? CameraSyncUiColor.networkOnlineBg
                      : CameraSyncUiColor.networkOfflineBg,
                ),
                child: Text(
                  state.isOnline
                      ? CameraSyncUiText.online
                      : CameraSyncUiText.offline,
                  style: TextStyle(
                    color: state.isOnline
                        ? CameraSyncUiColor.networkOnlineText
                        : CameraSyncUiColor.networkOfflineText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: state.overallProgress,
            minHeight: 6,
            backgroundColor: CameraSyncUiColor.progressTrack,
            valueColor: const AlwaysStoppedAnimation<Color>(
              CameraSyncUiColor.progressFill,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            CameraSyncUiText.progressLine(
              state.uploadedCount,
              state.totalCount,
              state.retryableCount,
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          if (state.lastSyncedAt != null)
            Text(
              CameraSyncUiText.lastSync(state.lastSyncedAt!),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class UploadItemCard extends StatelessWidget {
  const UploadItemCard({
    required this.item,
    required this.onPreview,
    super.key,
  });

  final UploadItem item;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return GestureDetector(
      onTap: onPreview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: CameraSyncUiColor.uploadItemSurface,
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            _Thumb(filePath: item.filePath),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(item.filePath),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(label: item.status.label, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (item.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.open_in_full_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: CameraSyncUiColor.thumbFallbackBg,
            child: Icon(
              Icons.insert_drive_file,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(UploadStatus status) {
  switch (status) {
    case UploadStatus.pending:
      return CameraSyncUiColor.uploadStatusPending;
    case UploadStatus.uploading:
      return CameraSyncUiColor.uploadStatusUploading;
    case UploadStatus.uploaded:
      return CameraSyncUiColor.uploadStatusUploaded;
    case UploadStatus.failed:
      return CameraSyncUiColor.uploadStatusFailed;
    case UploadStatus.waitingForNetwork:
      return CameraSyncUiColor.uploadStatusWaitingNetwork;
  }
}
