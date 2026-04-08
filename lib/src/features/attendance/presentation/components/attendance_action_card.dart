import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../bloc/attendance_state.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

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
