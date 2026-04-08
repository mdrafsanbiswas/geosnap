import 'package:flutter/material.dart';

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
