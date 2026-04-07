import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));

        context.read<AttendanceBloc>().add(const MessageCleared());
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Attendance'),
        ),
        body: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            final bloc = context.read<AttendanceBloc>();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OfficeLocationCard(
                    officeLocation: state.officeLocation,
                    currentLocation: state.currentLocation,
                    isLoading: state.status == AttendanceViewStatus.loading,
                    onSetOfficeLocation: () =>
                        bloc.add(const OfficeLocationRequested()),
                  ),
                  const SizedBox(height: 24),
                  _DistanceCard(
                    officeLocation: state.officeLocation,
                    distanceInMeters: state.distanceInMeters,
                    isInRange: state.isInRange,
                  ),
                  if (state.locationErrorType != null) ...[
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          bloc.add(const LocationTrackingRetried()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry location'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _AttendanceActionCard(
                    canMarkAttendance: state.canMarkAttendance,
                    attendanceMarkedAt: state.attendanceMarkedAt,
                    onMarkAttendance: () => bloc.add(const AttendanceMarked()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfficeLocationCard extends StatelessWidget {
  const _OfficeLocationCard({
    required this.officeLocation,
    required this.currentLocation,
    required this.isLoading,
    required this.onSetOfficeLocation,
  });

  final GeoPoint? officeLocation;
  final GeoPoint? currentLocation;
  final bool isLoading;
  final VoidCallback onSetOfficeLocation;

  @override
  Widget build(BuildContext context) {
    final previewLocation = officeLocation ?? currentLocation;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'STEP 1: OFFICE CONTEXT',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF7B86A5),
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.circle, size: 7, color: Color(0xFF386BFF)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: previewLocation == null
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8EDF8), Color(0xFFF7F9FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_searching,
                            size: 36,
                            color: Color(0xFF9CABCF),
                          ),
                        ),
                      )
                    : GoogleMap(
                        myLocationEnabled: currentLocation != null,
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
                              markerId: const MarkerId('office_location'),
                              position: LatLng(
                                officeLocation!.latitude,
                                officeLocation!.longitude,
                              ),
                            ),
                        },
                        circles: {
                          if (officeLocation != null)
                            Circle(
                              circleId: const CircleId('office_radius'),
                              center: LatLng(
                                officeLocation!.latitude,
                                officeLocation!.longitude,
                              ),
                              radius: AppConstants.attendanceRadiusInMeters,
                              strokeColor: const Color(0xFF386BFF),
                              fillColor: const Color(0x22386BFF),
                              strokeWidth: 2,
                            ),
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            if (previewLocation != null)
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE6EBF4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      'Lat : ${previewLocation.latitude.toStringAsFixed(4)},  '
                      'Lon : ${previewLocation.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF58637F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              officeLocation == null
                  ? 'Save your current GPS coordinates as the designated office location.'
                  : 'To mark your attendance, ensure your current office location is correctly identified.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7390),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onSetOfficeLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF386BFF),
                  side: const BorderSide(color: Color(0xFF386BFF), width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF9AA2BD),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined, size: 18),
                label: const Text(
                  'Set Office Location',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceCard extends StatelessWidget {
  const _DistanceCard({
    required this.officeLocation,
    required this.distanceInMeters,
    required this.isInRange,
  });

  final GeoPoint? officeLocation;
  final double? distanceInMeters;
  final bool isInRange;

  @override
  Widget build(BuildContext context) {
    final distanceValue = officeLocation == null ? null : (distanceInMeters ?? 0);
    final distanceText = distanceValue == null ? '--' : '${distanceValue.round()}m';

    final statusLabel = officeLocation == null
        ? 'SET OFFICE LOCATION'
        : isInRange
        ? 'WITHIN RANGE'
        : 'OUT OF RANGE';

    final helperText = officeLocation == null
        ? 'Set your office location to begin proximity tracking.'
        : isInRange
        ? 'You are within ${AppConstants.attendanceRadiusInMeters.toInt()} meters of the office.'
        : 'Move within ${AppConstants.attendanceRadiusInMeters.toInt()} meters of the designated office location to enable check-in.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          _DistanceMeter(
            distanceText: distanceText,
            inRange: isInRange,
            progress: distanceValue == null
                ? 0
                : (distanceValue / AppConstants.attendanceRadiusInMeters)
                    .clamp(0, 1)
                    .toDouble(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isInRange
                  ? const Color(0xFFDEF7EA)
                  : const Color(0xFFFFEBEE),
            ),
            child: Text(
              statusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isInRange
                    ? const Color(0xFF1D7B4A)
                    : const Color(0xFFD74646),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            helperText,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8A93AC)),
          ),
        ],
      ),
    );
  }
}

class _DistanceMeter extends StatelessWidget {
  const _DistanceMeter({
    required this.distanceText,
    required this.inRange,
    required this.progress,
  });

  final String distanceText;
  final bool inRange;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 134,
      height: 134,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(134),
            painter: _CircularRangePainter(
              color: inRange ? const Color(0xFF20A668) : const Color(0xFFED5A62),
              progress: progress,
            ),
          ),
          Container(
            width: 106,
            height: 106,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF2F4F8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distanceText,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2F3651),
                  ),
                ),
                Text(
                  inRange ? 'WITHIN' : 'AWAY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8F98B3),
                    letterSpacing: 1.1,
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

class _AttendanceActionCard extends StatelessWidget {
  const _AttendanceActionCard({
    required this.canMarkAttendance,
    required this.attendanceMarkedAt,
    required this.onMarkAttendance,
  });

  final bool canMarkAttendance;
  final DateTime? attendanceMarkedAt;
  final VoidCallback onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    final markedAtText = attendanceMarkedAt == null
        ? 'Available 09:00 AM - 10:30 AM'
        : 'Marked at ${_formatTime(attendanceMarkedAt!)}';

    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: const Color(0xFFD6DCE8),
        borderRadius: 16,
        dashLength: 8,
        gapLength: 5,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
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
                    ? const Color(0xFF386BFF)
                    : const Color(0xFFA8B2CC),
                size: 30,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: canMarkAttendance ? onMarkAttendance : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF386BFF),
                    disabledBackgroundColor: const Color(0xFFC8D0DF),
                    disabledForegroundColor: const Color(0xFF6F7891),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mark Attendance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                markedAtText.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9AA2BD),
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
    final strokeWidth = 6.0;
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFFDCE2EE)
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi * 0.85;
    final fullSweep = math.pi * 1.7;
    canvas.drawArc(rect, startAngle, fullSweep, false, basePaint);
    canvas.drawArc(
      rect,
      startAngle,
      fullSweep * progress.clamp(0.0, 1.0),
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

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
  final safeHour = hour == 0 ? 12 : hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$safeHour:$minute $suffix';
}
