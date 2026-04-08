import 'package:flutter/material.dart';

import '../../bloc/upload_queue/upload_queue_state.dart';
import '../../constants/camera_sync_ui_color.dart';
import '../../constants/camera_sync_ui_text.dart';

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
