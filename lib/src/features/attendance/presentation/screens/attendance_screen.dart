import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/errors/location_exception.dart';
import '../../domain/entities/geo_point.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../components/attendance_components.dart';
import '../constants/attendance_ui_color.dart';
import '../constants/attendance_ui_text.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with WidgetsBindingObserver {
  BitmapDescriptor? _currentLocationMarkerIcon;
  BitmapDescriptor? _officeLocationMarkerIcon;
  LocationErrorType? _dismissedLocationErrorType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareMapMarkerIcons();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (_dismissedLocationErrorType != null) {
      setState(() {
        _dismissedLocationErrorType = null;
      });
    }

    final attendanceBloc = context.read<AttendanceBloc>();
    final attendanceState = attendanceBloc.state;
    if (attendanceState.status == AttendanceViewStatus.loading) {
      return;
    }

    attendanceBloc.add(const LocationTrackingRetried());
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeAreaPadding = MediaQuery.paddingOf(context).bottom;

    return MultiBlocListener(
      listeners: [
        BlocListener<AttendanceBloc, AttendanceState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
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
        ),
        BlocListener<AttendanceBloc, AttendanceState>(
          listenWhen: (previous, current) =>
              previous.locationErrorType != current.locationErrorType,
          listener: (context, state) {
            final currentErrorType = state.locationErrorType;
            if (currentErrorType == null ||
                (_dismissedLocationErrorType != null &&
                    currentErrorType != _dismissedLocationErrorType)) {
              setState(() {
                _dismissedLocationErrorType = null;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          leadingWidth: 56,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 34,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          title: const Text(AttendanceUiText.title),
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              bottomSafeAreaPadding + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocSelector<
                  AttendanceBloc,
                  AttendanceState,
                  ({LocationErrorType? locationErrorType, String? message})
                >(
                  selector: (state) => (
                    locationErrorType: state.locationErrorType,
                    message: state.message,
                  ),
                  builder: (context, errorState) {
                    final locationErrorType = errorState.locationErrorType;
                    if (locationErrorType == null ||
                        locationErrorType == _dismissedLocationErrorType) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LocationIssueCard(
                        locationErrorType: locationErrorType,
                        message: errorState.message,
                        onRetry: () => context.read<AttendanceBloc>().add(
                          const LocationTrackingRetried(),
                        ),
                        onDismiss: () {
                          setState(() {
                            _dismissedLocationErrorType = locationErrorType;
                          });
                        },
                      ),
                    );
                  },
                ),
                BlocSelector<
                  AttendanceBloc,
                  AttendanceState,
                  ({
                    GeoPoint? officeLocation,
                    GeoPoint? currentLocation,
                    bool isLoading,
                  })
                >(
                  selector: (state) => (
                    officeLocation: state.officeLocation,
                    currentLocation: state.currentLocation,
                    isLoading: state.status == AttendanceViewStatus.loading,
                  ),
                  builder: (context, officeCardState) {
                    return OfficeLocationCard(
                      officeLocation: officeCardState.officeLocation,
                      currentLocation: officeCardState.currentLocation,
                      isLoading: officeCardState.isLoading,
                      currentLocationMarkerIcon: _currentLocationMarkerIcon,
                      officeLocationMarkerIcon: _officeLocationMarkerIcon,
                      onSetOfficeLocation: () => context
                          .read<AttendanceBloc>()
                          .add(const OfficeLocationRequested()),
                      onResetOfficeLocation: () => context
                          .read<AttendanceBloc>()
                          .add(const OfficeLocationResetRequested()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                BlocSelector<
                  AttendanceBloc,
                  AttendanceState,
                  ({
                    GeoPoint? officeLocation,
                    double? distanceInMeters,
                    bool isInRange,
                  })
                >(
                  selector: (state) => (
                    officeLocation: state.officeLocation,
                    distanceInMeters: state.distanceInMeters,
                    isInRange: state.isInRange,
                  ),
                  builder: (context, distanceState) {
                    return DistanceCard(
                      officeLocation: distanceState.officeLocation,
                      distanceInMeters: distanceState.distanceInMeters,
                      isInRange: distanceState.isInRange,
                    );
                  },
                ),
                const SizedBox(height: 18),
                BlocSelector<
                  AttendanceBloc,
                  AttendanceState,
                  ({
                    bool canMarkAttendance,
                    DateTime? attendanceMarkedAt,
                    AttendanceMarkStatus? attendanceMarkStatus,
                  })
                >(
                  selector: (state) => (
                    canMarkAttendance: state.canMarkAttendance,
                    attendanceMarkedAt: state.attendanceMarkedAt,
                    attendanceMarkStatus: state.attendanceMarkStatus,
                  ),
                  builder: (context, actionState) {
                    return AttendanceActionCard(
                      canMarkAttendance: actionState.canMarkAttendance,
                      attendanceMarkedAt: actionState.attendanceMarkedAt,
                      attendanceMarkStatus: actionState.attendanceMarkStatus,
                      onMarkAttendance: () => context
                          .read<AttendanceBloc>()
                          .add(const AttendanceMarked()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _prepareMapMarkerIcons() async {
    final markerIcons = await Future.wait<BitmapDescriptor>([
      _buildIconMarker(
        icon: Icons.my_location_rounded,
        iconColor: AttendanceUiColor.brandBlue,
        logicalIconSize: 18,
        logicalCanvasSize: 34,
        includeBackdrop: true,
      ),
      _buildIconMarker(
        icon: Icons.location_on_rounded,
        iconColor: AttendanceUiColor.danger,
        logicalIconSize: 26,
        logicalCanvasSize: 42,
        includeBackdrop: false,
      ),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocationMarkerIcon = markerIcons[0];
      _officeLocationMarkerIcon = markerIcons[1];
    });
  }

  Future<BitmapDescriptor> _buildIconMarker({
    required IconData icon,
    required Color iconColor,
    required double logicalIconSize,
    required double logicalCanvasSize,
    required bool includeBackdrop,
  }) async {
    const scale = 4.0;
    final markerSize = logicalCanvasSize * scale;
    final markerCenter = Offset(markerSize / 2, markerSize / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (includeBackdrop) {
      final backgroundPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.92);
      final borderPaint = Paint()
        ..color = iconColor.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;

      canvas.drawCircle(
        markerCenter,
        (markerSize / 2) - (2 * scale),
        backgroundPaint,
      );
      canvas.drawCircle(
        markerCenter,
        (markerSize / 2) - (2 * scale),
        borderPaint,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: iconColor,
          fontSize: logicalIconSize * scale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      )
      ..layout();

    textPainter.paint(
      canvas,
      Offset(
        (markerSize - textPainter.width) / 2,
        (markerSize - textPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      markerSize.toInt(),
      markerSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final markerBytes = byteData?.buffer.asUint8List();
    if (markerBytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(
        icon == Icons.location_on_rounded
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueAzure,
      );
    }

    return BitmapDescriptor.bytes(
      markerBytes,
      imagePixelRatio: scale,
      bitmapScaling: MapBitmapScaling.auto,
    );
  }
}
