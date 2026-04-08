import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../bloc/attendance_state.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

class OfficeLocationCard extends StatelessWidget {
  const OfficeLocationCard({
    required this.officeLocation,
    required this.currentLocation,
    required this.isLoading,
    required this.currentLocationMarkerIcon,
    required this.officeLocationMarkerIcon,
    required this.onSetOfficeLocation,
    required this.onResetOfficeLocation,
    super.key,
  });

  final GeoPoint? officeLocation;
  final GeoPoint? currentLocation;
  final bool isLoading;
  final BitmapDescriptor? currentLocationMarkerIcon;
  final BitmapDescriptor? officeLocationMarkerIcon;
  final VoidCallback onSetOfficeLocation;
  final VoidCallback onResetOfficeLocation;

  @override
  Widget build(BuildContext context) {
    final previewLocation = officeLocation ?? currentLocation;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = (screenHeight * 0.28).clamp(170.0, 220.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AttendanceUiColor.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AttendanceUiText.officeTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AttendanceUiColor.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (officeLocation != null)
                  TextButton.icon(
                    onPressed: isLoading ? null : onResetOfficeLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(AttendanceUiText.reset),
                    style: TextButton.styleFrom(
                      foregroundColor: AttendanceUiColor.brand,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              officeLocation == null
                  ? AttendanceUiText.officeHintSet
                  : AttendanceUiText.officeHintLocked,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AttendanceUiColor.body,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: mapHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: previewLocation == null
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AttendanceUiColor.mapBgA,
                              AttendanceUiColor.mapBgB,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_searching,
                            size: 40,
                            color: AttendanceUiColor.mapIcon,
                          ),
                        ),
                      )
                    : IgnorePointer(
                        child: GoogleMap(
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          zoomGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              previewLocation.latitude,
                              previewLocation.longitude,
                            ),
                            zoom: 17,
                          ),
                          markers: {
                            if (officeLocation != null)
                              Marker(
                                markerId: const MarkerId(
                                  AttendanceUiText.officeMarkerId,
                                ),
                                position: LatLng(
                                  officeLocation!.latitude,
                                  officeLocation!.longitude,
                                ),
                                zIndexInt: 1,
                                icon:
                                    officeLocationMarkerIcon ??
                                    BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueRed,
                                    ),
                                anchor: const Offset(0.5, 1),
                                infoWindow: const InfoWindow(
                                  title: AttendanceUiText.officeMarkerTitle,
                                ),
                              ),
                            if (currentLocation != null)
                              Marker(
                                markerId: const MarkerId(
                                  AttendanceUiText.currentMarkerId,
                                ),
                                position: LatLng(
                                  currentLocation!.latitude,
                                  currentLocation!.longitude,
                                ),
                                zIndexInt: 2,
                                icon:
                                    currentLocationMarkerIcon ??
                                    BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueAzure,
                                    ),
                                anchor: const Offset(0.5, 0.5),
                                infoWindow: const InfoWindow(
                                  title: AttendanceUiText.currentMarkerTitle,
                                ),
                              ),
                          },
                          circles: {
                            if (officeLocation != null)
                              Circle(
                                circleId: const CircleId(
                                  AttendanceUiText.officeRadiusId,
                                ),
                                center: LatLng(
                                  officeLocation!.latitude,
                                  officeLocation!.longitude,
                                ),
                                radius: AppConstants.attendanceRadiusInMeters,
                                strokeColor: AttendanceUiColor.danger,
                                fillColor: AttendanceUiColor.officeRadiusFill,
                                strokeWidth: 2,
                              ),
                            if (currentLocation != null)
                              Circle(
                                circleId: const CircleId(
                                  AttendanceUiText.currentAccuracyId,
                                ),
                                center: LatLng(
                                  currentLocation!.latitude,
                                  currentLocation!.longitude,
                                ),
                                radius: _currentLocationAccuracyRadius(
                                  currentLocation!.accuracyInMeters,
                                ),
                                strokeColor: AttendanceUiColor.accuracyStroke,
                                fillColor: AttendanceUiColor.accuracyFill,
                                strokeWidth: 1,
                              ),
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: const [
                _LegendChip(
                  icon: Icons.business,
                  label: AttendanceUiText.officeLegend,
                  color: AttendanceUiColor.danger,
                ),
                _LegendChip(
                  icon: Icons.my_location,
                  label: AttendanceUiText.youLegend,
                  color: AttendanceUiColor.brandBlue,
                ),
              ],
            ),
            if (currentLocation != null) ...[
              const SizedBox(height: 10),
              _CoordinateText(location: currentLocation!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: isLoading || officeLocation != null
                    ? null
                    : onSetOfficeLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: AttendanceUiColor.brand,
                  disabledBackgroundColor: AttendanceUiColor.btnDisabledBg,
                  disabledForegroundColor: AttendanceUiColor.btnDisabledFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.apartment_rounded, size: 18),
                label: Text(
                  officeLocation == null
                      ? AttendanceUiText.setOffice
                      : AttendanceUiText.officeSaved,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _currentLocationAccuracyRadius(double? accuracyInMeters) {
    if (accuracyInMeters == null) {
      return 22;
    }

    return accuracyInMeters.clamp(16, 42).toDouble();
  }
}

class DistanceCard extends StatelessWidget {
  const DistanceCard({
    required this.officeLocation,
    required this.distanceInMeters,
    required this.isInRange,
    super.key,
  });

  final GeoPoint? officeLocation;
  final double? distanceInMeters;
  final bool isInRange;

  @override
  Widget build(BuildContext context) {
    final distanceValue = officeLocation == null ? null : distanceInMeters;
    final distanceText = distanceValue == null
        ? AttendanceUiText.distanceUnknown
        : AttendanceUiText.distanceMeters(distanceValue.round());
    final progress = distanceValue == null
        ? 0.0
        : (1 - (distanceValue / AppConstants.attendanceRadiusInMeters))
              .clamp(0, 1)
              .toDouble();

    final statusLabel = officeLocation == null
        ? AttendanceUiText.officeRequired
        : isInRange
        ? AttendanceUiText.zoneInside
        : AttendanceUiText.zoneOutside;

    final helperText = officeLocation == null
        ? AttendanceUiText.setOfficeToTrack
        : isInRange
        ? AttendanceUiText.withinMeters(
            AppConstants.attendanceRadiusInMeters.toInt(),
          )
        : AttendanceUiText.moveWithinMeters(
            AppConstants.attendanceRadiusInMeters.toInt(),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AttendanceUiColor.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: [
            _DistanceMeter(
              distanceText: distanceText,
              inRange: isInRange,
              progress: progress,
              proximityLabel: distanceValue == null
                  ? null
                  : isInRange
                  ? AttendanceUiText.ready
                  : AttendanceUiText.moveCloser,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isInRange
                    ? AttendanceUiColor.stateOkBg
                    : AttendanceUiColor.stateWarnBg,
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isInRange
                      ? AttendanceUiColor.stateOkText
                      : AttendanceUiColor.stateWarnText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              helperText,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AttendanceUiColor.helper),
            ),
          ],
        ),
      ),
    );
  }
}

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

class AttendanceActionCard extends StatelessWidget {
  const AttendanceActionCard({
    required this.canMarkAttendance,
    required this.attendanceMarkedAt,
    required this.attendanceMarkStatus,
    required this.onMarkAttendance,
    super.key,
  });

  final bool canMarkAttendance;
  final DateTime? attendanceMarkedAt;
  final AttendanceMarkStatus? attendanceMarkStatus;
  final VoidCallback onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    final windowText = AttendanceUiText.window(
      _formatWindowTime(
        AppConstants.attendanceStartHour,
        AppConstants.attendanceStartMinute,
      ),
      _formatWindowTime(
        AppConstants.attendanceEndHour,
        AppConstants.attendanceEndMinute,
      ),
    );

    final markedAtText = attendanceMarkedAt == null
        ? AttendanceUiText.noMarkedYet
        : AttendanceUiText.markedAt(
            _formatTime(attendanceMarkedAt!),
            attendanceMarkStatus == AttendanceMarkStatus.late,
          );

    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: AttendanceUiColor.dashedBorder,
        borderRadius: 16,
        dashLength: 8,
        gapLength: 5,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AttendanceUiColor.actionBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                canMarkAttendance
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: canMarkAttendance
                    ? AttendanceUiColor.brand
                    : AttendanceUiColor.lockOff,
                size: 30,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: canMarkAttendance ? onMarkAttendance : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AttendanceUiColor.brand,
                    disabledBackgroundColor: AttendanceUiColor.actionDisabledBg,
                    disabledForegroundColor: AttendanceUiColor.actionDisabledFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AttendanceUiText.markAttendance,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                markedAtText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AttendanceUiColor.actionDisabledFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                windowText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AttendanceUiColor.note,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AttendanceUiColor.chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AttendanceUiColor.chipText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateText extends StatelessWidget {
  const _CoordinateText({required this.location});

  final GeoPoint location;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AttendanceUiColor.coordBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            AttendanceUiText.latLon(
              location.latitude.toStringAsFixed(5),
              location.longitude.toStringAsFixed(5),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AttendanceUiColor.coordText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DistanceMeter extends StatelessWidget {
  const _DistanceMeter({
    required this.distanceText,
    required this.inRange,
    required this.progress,
    this.proximityLabel,
  });

  final String distanceText;
  final bool inRange;
  final double progress;
  final String? proximityLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(140),
            painter: _CircularRangePainter(
              color: inRange
                  ? AttendanceUiColor.meterOk
                  : AttendanceUiColor.meterWarn,
              progress: progress,
            ),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AttendanceUiColor.meterInnerBg,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distanceText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AttendanceUiColor.meterValue,
                  ),
                ),
                if (proximityLabel != null)
                  Text(
                    proximityLabel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AttendanceUiColor.meterLabel,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _CircularRangePainter extends CustomPainter {
  const _CircularRangePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 7.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AttendanceUiColor.meterBase
      ..strokeCap = StrokeCap.butt;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2) * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularRangePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.borderRadius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double borderRadius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(borderRadius),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}

String _formatWindowTime(int hour, int minute) {
  final safeHour = hour == 0
      ? 12
      : hour > 12
      ? hour - 12
      : hour;
  final suffix = hour >= 12 ? AttendanceUiText.pm : AttendanceUiText.am;
  final paddedMinute = minute.toString().padLeft(2, '0');
  return '$safeHour:$paddedMinute $suffix';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
  final safeHour = hour == 0 ? 12 : hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12
      ? AttendanceUiText.pm
      : AttendanceUiText.am;
  return '$safeHour:$minute $suffix';
}
