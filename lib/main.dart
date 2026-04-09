import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/features/camera_sync/background/upload_sync_worker.dart';
import 'src/features/camera_sync/data/data_sources/mock_upload_remote.dart';
import 'src/features/camera_sync/data/data_sources/network_checker.dart';
import 'src/features/camera_sync/data/data_sources/upload_queue_local.dart';
import 'src/features/camera_sync/data/models/upload_item_model.dart';
import 'src/features/camera_sync/data/repositories/upload_queue_repository_impl.dart';
import 'src/features/attendance/data/data_sources/device_location.dart';
import 'src/features/attendance/data/data_sources/office_location_local.dart';
import 'src/features/attendance/data/models/location_model.dart';
import 'src/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'src/features/attendance/domain/repositories/attendance_repository.dart';
import 'src/features/camera_sync/domain/repositories/upload_queue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const _GeoSnapBootstrapApp());
}

Future<void> _registerUploadSyncWorkerSafely() async {
  try {
    await registerUploadSyncWorker();
  } catch (_) {
    // Keep app startup resilient when background scheduler isn't available.
  }
}

class _GeoSnapBootstrapApp extends StatefulWidget {
  const _GeoSnapBootstrapApp();

  @override
  State<_GeoSnapBootstrapApp> createState() => _GeoSnapBootstrapAppState();
}

class _GeoSnapBootstrapAppState extends State<_GeoSnapBootstrapApp> {
  late final Future<_AppDependencies> _dependenciesFuture =
      _initializeDependencies();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _dependenciesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final dependencies = snapshot.data!;
          return GeoSnapApp(
            attendanceRepository: dependencies.attendanceRepository,
            uploadQueueRepository: dependencies.uploadQueueRepository,
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Startup failed. Please relaunch the app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.attendanceRepository,
    required this.uploadQueueRepository,
  });

  final AttendanceRepository attendanceRepository;
  final UploadQueueRepository uploadQueueRepository;
}

Future<_AppDependencies> _initializeDependencies() async {
  final sharedPreferences = await _getSharedPreferencesSafely();
  final uploadQueueLocalDataSource = await _getUploadQueueLocalDataSource();

  final officeLocationLocalDataSource = sharedPreferences == null
      ? _InMemoryOfficeLocationLocalDataSource()
      : SharedPreferencesOfficeLocationLocalDataSource(sharedPreferences);

  final attendanceRepository = AttendanceRepositoryImpl(
    deviceLocationDataSource: GeolocatorDeviceLocationDataSource(),
    officeLocationLocalDataSource: officeLocationLocalDataSource,
  );
  final uploadQueueRepository = UploadQueueRepositoryImpl(
    uploadQueueLocalDataSource: uploadQueueLocalDataSource,
    uploadRemoteDataSource: MockUploadRemoteDataSource(),
    networkCheckerDataSource: InternetLookupNetworkCheckerDataSource(),
  );

  // Avoid blocking first frame on platform scheduler setup.
  unawaited(_registerUploadSyncWorkerSafely());

  return _AppDependencies(
    attendanceRepository: attendanceRepository,
    uploadQueueRepository: uploadQueueRepository,
  );
}

Future<SharedPreferences?> _getSharedPreferencesSafely() async {
  try {
    return await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 4),
    );
  } catch (_) {
    return null;
  }
}

Future<UploadQueueLocalDataSource> _getUploadQueueLocalDataSource() async {
  try {
    final appDirectory = await getApplicationDocumentsDirectory().timeout(
      const Duration(seconds: 4),
    );
    Hive.init(appDirectory.path);
    final uploadQueueBox = await openUploadQueueHiveBox().timeout(
      const Duration(seconds: 4),
    );
    return HiveUploadQueueLocalDataSource(uploadQueueBox);
  } catch (_) {
    return _InMemoryUploadQueueLocalDataSource();
  }
}

class _InMemoryUploadQueueLocalDataSource
    implements UploadQueueLocalDataSource {
  List<UploadItemModel> _items = const [];

  @override
  Future<List<UploadItemModel>> getUploadItems() async {
    return List<UploadItemModel>.unmodifiable(_items);
  }

  @override
  Future<void> saveUploadItems(List<UploadItemModel> items) async {
    _items = List<UploadItemModel>.from(items);
  }
}

class _InMemoryOfficeLocationLocalDataSource
    implements OfficeLocationLocalDataSource {
  LocationModel? _location;

  @override
  Future<void> clearOfficeLocation() async {
    _location = null;
  }

  @override
  Future<LocationModel?> getSavedOfficeLocation() async {
    return _location;
  }

  @override
  Future<void> saveOfficeLocation(LocationModel location) async {
    _location = location;
  }
}
