import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';
import '../constants/camera_sync_ui_color.dart';

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
