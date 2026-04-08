import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../camera_sync/domain/entities/upload_status.dart';
import '../../../camera_sync/presentation/bloc/upload_queue/upload_queue_bloc.dart';
import '../../../camera_sync/presentation/bloc/upload_queue/upload_queue_state.dart';

class StarterScreen extends StatelessWidget {
  const StarterScreen({
    required this.onOpenAttendance,
    required this.onOpenCameraSync,
    super.key,
  });

  final VoidCallback onOpenAttendance;
  final VoidCallback onOpenCameraSync;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FC), Color(0xFFE7EDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GeoSnap',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0E1B3D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a feature to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF546386),
                  ),
                ),
                const SizedBox(height: 24),
                _TaskCard(
                  title: 'Attendance',
                  subtitle: 'Geo-Fenced Check-in',
                  description:
                      'Set office location, track distance, and mark attendance inside 50m.',
                  icon: Icons.location_pin,
                  color: const Color(0xFF386BFF),
                  onTap: onOpenAttendance,
                ),
                const SizedBox(height: 16),
                _TaskCard(
                  title: 'Camera & Sync',
                  subtitle: 'Batch Capture Uploads',
                  description:
                      'Capture image batches, upload with progress, retain pending queue, and retry automatically.',
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF0B172B),
                  onTap: onOpenCameraSync,
                  notificationChip: const _UploadQueueNotificationChip(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.notificationChip,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? notificationChip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color, Color.lerp(color, Colors.white, 0.3)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                        ),
                        if (notificationChip != null)
                          Flexible(child: notificationChip!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadQueueNotificationChip extends StatelessWidget {
  const _UploadQueueNotificationChip();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UploadQueueBloc, UploadQueueState, String?>(
      selector: (state) {
        final queuedCount = state.items
            .where((item) => item.status != UploadStatus.uploaded)
            .length;
        if (queuedCount == 0) {
          return null;
        }
        if (!state.isOnline) {
          return 'Offline: $queuedCount upload${queuedCount == 1 ? '' : 's'} queued';
        }
        return '$queuedCount pending upload${queuedCount == 1 ? '' : 's'}';
      },
      builder: (context, notification) {
        if (notification == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            notification,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
