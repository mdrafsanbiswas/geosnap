import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/camera_sync/background/upload_sync_worker.dart';
import 'features/camera_sync/domain/repositories/upload_queue_repository.dart';
import 'features/camera_sync/domain/usecases/enqueue_upload_batch.dart';
import 'features/camera_sync/domain/usecases/get_upload_items.dart';
import 'features/camera_sync/domain/usecases/has_network_access.dart';
import 'features/camera_sync/domain/usecases/process_pending_uploads.dart';
import 'features/camera_sync/domain/usecases/watch_network_access.dart';
import 'features/camera_sync/presentation/bloc/camera/camera_bloc.dart';
import 'features/camera_sync/presentation/bloc/camera/camera_event.dart';
import 'features/camera_sync/presentation/bloc/upload_queue/upload_queue_bloc.dart';
import 'features/camera_sync/presentation/bloc/upload_queue/upload_queue_event.dart';
import 'features/camera_sync/presentation/bloc/upload_queue/upload_queue_state.dart';
import 'features/camera_sync/presentation/screens/camera_preview_screen.dart';
import 'features/camera_sync/presentation/services/upload_progress_notification_service.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/clear_saved_office_location.dart';
import 'features/attendance/domain/usecases/calculate_distance.dart';
import 'features/attendance/domain/usecases/get_current_location.dart';
import 'features/attendance/domain/usecases/get_saved_office_location.dart';
import 'features/attendance/domain/usecases/save_office_location.dart';
import 'features/attendance/domain/usecases/watch_current_location.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_event.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';
import 'features/home/presentation/screens/starter_screen.dart';

class GeoSnapApp extends StatefulWidget {
  const GeoSnapApp({
    required this.attendanceRepository,
    required this.uploadQueueRepository,
    super.key,
  });

  final AttendanceRepository attendanceRepository;
  final UploadQueueRepository uploadQueueRepository;

  @override
  State<GeoSnapApp> createState() => _GeoSnapAppState();
}

class _GeoSnapAppState extends State<GeoSnapApp> with WidgetsBindingObserver {
  late final UploadQueueBloc _uploadQueueBloc;
  late final StreamSubscription<UploadQueueState> _uploadQueueSubscription;
  final UploadProgressNotificationService _uploadProgressNotificationService =
      UploadProgressNotificationService();
  DateTime? _lastBackgroundSyncRequestedAt;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uploadQueueBloc = UploadQueueBloc(
      getUploadItems: GetUploadItemsUseCase(widget.uploadQueueRepository),
      enqueueUploadBatch: EnqueueUploadBatchUseCase(
        widget.uploadQueueRepository,
      ),
      processPendingUploads: ProcessPendingUploadsUseCase(
        widget.uploadQueueRepository,
      ),
      hasNetworkAccess: HasNetworkAccessUseCase(widget.uploadQueueRepository),
      watchNetworkAccess: WatchNetworkAccessUseCase(
        widget.uploadQueueRepository,
      ),
    )..add(const UploadQueueInitialized());

    _uploadQueueSubscription = _uploadQueueBloc.stream.listen(
      _onUploadQueueStateChanged,
    );
    unawaited(_uploadProgressNotificationService.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      _uploadQueueBloc.add(const UploadQueueAppResumed());
      unawaited(_uploadProgressNotificationService.cancel());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_updateBackgroundUploadNotification(_uploadQueueBloc.state));
      unawaited(_requestBackgroundUploadSync());
    }
  }

  void _onUploadQueueStateChanged(UploadQueueState state) {
    unawaited(_updateBackgroundUploadNotification(state));
  }

  Future<void> _updateBackgroundUploadNotification(
    UploadQueueState state,
  ) async {
    if (!Platform.isAndroid) {
      return;
    }

    final inForeground = _appLifecycleState == AppLifecycleState.resumed;
    if (inForeground) {
      await _uploadProgressNotificationService.cancel();
      return;
    }

    await _uploadProgressNotificationService.showOrUpdate(
      totalCount: state.totalCount,
      uploadedCount: state.uploadedCount,
      uploadingCount: state.uploadingCount,
      retryableCount: state.retryableCount,
      isOnline: state.isOnline,
      progress: state.overallProgress,
    );
  }

  Future<void> _requestBackgroundUploadSync() async {
    final now = DateTime.now();
    final lastRequestedAt = _lastBackgroundSyncRequestedAt;
    if (lastRequestedAt != null &&
        now.difference(lastRequestedAt) < const Duration(seconds: 15)) {
      return;
    }

    _lastBackgroundSyncRequestedAt = now;
    try {
      await triggerUploadSyncNow();
    } catch (_) {
      // Keep lifecycle transitions resilient if scheduler is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF386BFF),
          surface: const Color(0xFFF4F6FB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: widget.attendanceRepository),
          RepositoryProvider.value(value: widget.uploadQueueRepository),
        ],
        child: MultiBlocProvider(
          providers: [BlocProvider.value(value: _uploadQueueBloc)],
          child: Builder(
            builder: (context) => StarterScreen(
              onOpenAttendance: () => _openAttendance(context),
              onOpenCameraSync: () => _openCameraSync(context),
            ),
          ),
        ),
      ),
    );
  }

  void _openAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => AttendanceBloc(
            getSavedOfficeLocation: GetSavedOfficeLocationUseCase(
              widget.attendanceRepository,
            ),
            saveOfficeLocation: SaveOfficeLocationUseCase(
              widget.attendanceRepository,
            ),
            clearSavedOfficeLocation: ClearSavedOfficeLocationUseCase(
              widget.attendanceRepository,
            ),
            getCurrentLocation: GetCurrentLocationUseCase(
              widget.attendanceRepository,
            ),
            watchCurrentLocation: WatchCurrentLocationUseCase(
              widget.attendanceRepository,
            ),
            calculateDistance: CalculateDistanceUseCase(
              widget.attendanceRepository,
            ),
          )..add(const AttendanceInitialized()),
          child: const AttendanceScreen(),
        ),
      ),
    );
  }

  void _openCameraSync(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => CameraBloc()..add(const CameraInitialized()),
            ),
            BlocProvider.value(value: context.read<UploadQueueBloc>()),
          ],
          child: const CameraPreviewScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uploadQueueSubscription.cancel();
    unawaited(_uploadProgressNotificationService.cancel());
    _uploadQueueBloc.close();
    super.dispose();
  }
}
