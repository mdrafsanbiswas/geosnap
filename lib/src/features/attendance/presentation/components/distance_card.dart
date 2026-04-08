import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

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
