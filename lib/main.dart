import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/features/camera_sync/background/upload_sync_worker.dart';
import 'src/features/camera_sync/data/data_sources/mock_upload_remote.dart';
import 'src/features/camera_sync/data/data_sources/network_checker.dart';
import 'src/features/camera_sync/data/data_sources/upload_queue_local.dart';
import 'src/features/camera_sync/data/repositories/upload_queue_repository_impl.dart';
import 'src/features/attendance/data/data_sources/device_location.dart';
import 'src/features/attendance/data/data_sources/office_location_local.dart';
import 'src/features/attendance/data/repositories/attendance_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  final attendanceRepository = AttendanceRepositoryImpl(
    deviceLocationDataSource: GeolocatorDeviceLocationDataSource(),
    officeLocationLocalDataSource:
        SharedPreferencesOfficeLocationLocalDataSource(sharedPreferences),
  );
  final uploadQueueRepository = UploadQueueRepositoryImpl(
    uploadQueueLocalDataSource: SharedPreferencesUploadQueueLocalDataSource(
      sharedPreferences,
    ),
    uploadRemoteDataSource: MockUploadRemoteDataSource(),
    networkCheckerDataSource: InternetLookupNetworkCheckerDataSource(),
  );

  try {
    await registerUploadSyncWorker();
  } catch (_) {
    // Keep app startup resilient when background scheduler isn't available.
  }

  runApp(
    GeoSnapApp(
      attendanceRepository: attendanceRepository,
      uploadQueueRepository: uploadQueueRepository,
    ),
  );
}
