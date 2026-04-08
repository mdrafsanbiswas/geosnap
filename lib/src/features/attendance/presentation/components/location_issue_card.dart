import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/location_exception.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

class LocationIssueCard extends StatelessWidget {
  const LocationIssueCard({
    required this.locationErrorType,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
    super.key,
  });

  final LocationErrorType locationErrorType;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final action = _resolveAction();
    final title = _resolveTitle();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AttendanceUiColor.issueBgA, AttendanceUiColor.issueBgB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AttendanceUiColor.issueBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AttendanceUiColor.issueIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_not_fixed,
                    color: AttendanceUiColor.issueIconFg,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AttendanceUiColor.issueTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message ?? AttendanceUiText.locationRequired,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AttendanceUiColor.issueBody,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(34, 34),
                    backgroundColor: AttendanceUiColor.issueCloseBg,
                    foregroundColor: AttendanceUiColor.issueCloseFg,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: AttendanceUiText.dismiss,
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () async {
                await action.onPressed();
                if (context.mounted && action.retryAfterAction) {
                  onRetry();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AttendanceUiColor.issueBtnBg,
                foregroundColor: AttendanceUiColor.issueBtnFg,
                iconColor: AttendanceUiColor.issueBtnFg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(action.icon, size: 18),
              label: Text(
                action.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveTitle() {
    switch (locationErrorType) {
      case LocationErrorType.serviceDisabled:
        return AttendanceUiText.gpsOff;
      case LocationErrorType.permissionDeniedForever:
        return AttendanceUiText.permissionBlocked;
      case LocationErrorType.permissionDenied:
        return AttendanceUiText.permissionNeeded;
      case LocationErrorType.timeout:
        return AttendanceUiText.requestTimedOut;
      case LocationErrorType.unavailable:
        return AttendanceUiText.temporarilyUnavailable;
    }
  }

  _LocationIssueAction _resolveAction() {
    switch (locationErrorType) {
      case LocationErrorType.serviceDisabled:
        return _LocationIssueAction(
          label: AttendanceUiText.enableGps,
          icon: Icons.gps_fixed,
          retryAfterAction: false,
          onPressed: () async {
            await Geolocator.openLocationSettings();
          },
        );
      case LocationErrorType.permissionDeniedForever:
        return _LocationIssueAction(
          label: AttendanceUiText.openAppSettings,
          icon: Icons.settings,
          retryAfterAction: false,
          onPressed: () async {
            await Geolocator.openAppSettings();
          },
        );
      case LocationErrorType.permissionDenied:
      case LocationErrorType.timeout:
      case LocationErrorType.unavailable:
        return _LocationIssueAction(
          label: AttendanceUiText.retryLocation,
          icon: Icons.refresh,
          retryAfterAction: true,
          onPressed: () async {},
        );
    }
  }
}

class _LocationIssueAction {
  const _LocationIssueAction({
    required this.label,
    required this.icon,
    required this.retryAfterAction,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool retryAfterAction;
  final Future<void> Function() onPressed;
}
