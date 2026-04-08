import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'features/camera_sync/presentation/screens/camera_preview_screen.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/calculate_distance.dart';
import 'features/attendance/domain/usecases/get_current_location.dart';
import 'features/attendance/domain/usecases/get_saved_office_location.dart';
import 'features/attendance/domain/usecases/save_office_location.dart';
import 'features/attendance/domain/usecases/watch_current_location.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_event.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';
import 'features/home/presentation/screens/starter_screen.dart';

class GeoSnapApp extends StatelessWidget {
  const GeoSnapApp({
    required this.attendanceRepository,
    required this.uploadQueueRepository,
    super.key,
  });

  final AttendanceRepository attendanceRepository;
  final UploadQueueRepository uploadQueueRepository;

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
          backgroundColor: Colors.transparent,
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
          RepositoryProvider.value(value: attendanceRepository),
          RepositoryProvider.value(value: uploadQueueRepository),
        ],
        child: Builder(
          builder: (context) => StarterScreen(
            onOpenAttendance: () => _openAttendance(context),
            onOpenCameraSync: () => _openCameraSync(context),
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
              attendanceRepository,
            ),
            saveOfficeLocation: SaveOfficeLocationUseCase(
              attendanceRepository,
            ),
            getCurrentLocation: GetCurrentLocationUseCase(
              attendanceRepository,
            ),
            watchCurrentLocation: WatchCurrentLocationUseCase(
              attendanceRepository,
            ),
            calculateDistance: CalculateDistanceUseCase(
              attendanceRepository,
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
            BlocProvider(
              create: (_) => UploadQueueBloc(
                getUploadItems: GetUploadItemsUseCase(
                  uploadQueueRepository,
                ),
                enqueueUploadBatch: EnqueueUploadBatchUseCase(
                  uploadQueueRepository,
                ),
                processPendingUploads: ProcessPendingUploadsUseCase(
                  uploadQueueRepository,
                ),
                hasNetworkAccess: HasNetworkAccessUseCase(
                  uploadQueueRepository,
                ),
                watchNetworkAccess: WatchNetworkAccessUseCase(
                  uploadQueueRepository,
                ),
              )..add(const UploadQueueInitialized()),
            ),
          ],
          child: const CameraPreviewScreen(),
        ),
      ),
    );
  }
}
