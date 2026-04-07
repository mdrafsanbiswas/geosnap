import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/geo_point.dart';
import '../cubit/attendance_cubit.dart';
import '../cubit/attendance_state.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceCubit, AttendanceState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));

        context.read<AttendanceCubit>().clearMessage();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text('Attendance'),
        ),
        body: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            final cubit = context.read<AttendanceCubit>();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OfficeLocationCard(
                    officeLocation: state.officeLocation,
                    currentLocation: state.currentLocation,
                    isLoading: state.status == AttendanceViewStatus.loading,
                    onSetOfficeLocation: cubit.setOfficeLocation,
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
                      onPressed: cubit.retryLocationTracking,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry location'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _AttendanceActionCard(
                    canMarkAttendance: state.canMarkAttendance,
                    attendanceMarkedAt: state.attendanceMarkedAt,
                    onMarkAttendance: cubit.markAttendance,
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

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'STEP 1: OFFICE CONTEXT',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF7B86A5),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.circle, size: 8, color: Color(0xFF386BFF)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
                            size: 44,
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
            const SizedBox(height: 12),
            if (previewLocation != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    'Lat: ${previewLocation.latitude.toStringAsFixed(4)},  '
                    'Lon: ${previewLocation.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF58637F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              officeLocation == null
                  ? 'Save your current GPS coordinates as the designated office location.'
                  : 'To mark your attendance, ensure your current office location is correctly identified.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7390),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: isLoading ? null : onSetOfficeLocation,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Set Office Location'),
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
    final distanceText = officeLocation == null
        ? '--'
        : '${(distanceInMeters ?? 0).round()}m';

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFF8FAFF),
              child: CircleAvatar(
                radius: 47,
                backgroundColor: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      distanceText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF29304D),
                          ),
                    ),
                    Text(
                      isInRange ? 'WITHIN' : 'AWAY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF9AA2BD),
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Chip(
              avatar: const Icon(
                Icons.circle,
                size: 10,
                color: Color(0xFFFF6B6B),
              ),
              label: Text(statusLabel),
            ),
            const SizedBox(height: 8),
            Text(
              helperText,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7390)),
            ),
          ],
        ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: canMarkAttendance
              ? const Color(0x22386BFF)
              : const Color(0xFFD8DDF0),
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              canMarkAttendance ? Icons.lock_open_rounded : Icons.lock_outline,
              color: canMarkAttendance
                  ? const Color(0xFF386BFF)
                  : const Color(0xFFA8B2CC),
              size: 30,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canMarkAttendance ? onMarkAttendance : null,
                child: const Text('Mark Attendance'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              markedAtText.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9AA2BD),
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
  final safeHour = hour == 0 ? 12 : hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$safeHour:$minute $suffix';
}
