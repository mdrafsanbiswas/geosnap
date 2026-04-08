import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geosnap/src/features/camera_sync/domain/entities/upload_item.dart';
import 'package:geosnap/src/features/camera_sync/domain/repositories/upload_queue_repository.dart';
import 'package:geosnap/src/features/attendance/data/data_sources/device_location.dart';
import 'package:geosnap/src/features/attendance/data/data_sources/office_location_local.dart';
import 'package:geosnap/src/features/attendance/data/repositories/attendance_repository_impl.dart';

import 'package:geosnap/src/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders attendance screen shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    final repository = AttendanceRepositoryImpl(
      deviceLocationDataSource: const _FakeDeviceLocationDataSource(),
      officeLocationLocalDataSource:
          SharedPreferencesOfficeLocationLocalDataSource(sharedPreferences),
    );

    await tester.pumpWidget(
      GeoSnapApp(
        attendanceRepository: repository,
        uploadQueueRepository: const _FakeUploadQueueRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GeoSnap'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Camera & Sync'), findsOneWidget);
  });
}

class _FakeDeviceLocationDataSource implements DeviceLocationDataSource {
  const _FakeDeviceLocationDataSource();

  @override
  Future<Position> getCurrentPosition() => Future.error(UnimplementedError());

  @override
  Stream<Position> watchPosition() => const Stream.empty();
}

class _FakeUploadQueueRepository implements UploadQueueRepository {
  const _FakeUploadQueueRepository();

  @override
  Future<List<UploadItem>> enqueueBatch(List<String> filePaths) async {
    return const [];
  }

  @override
  Future<List<UploadItem>> getUploadItems() async {
    return const [];
  }

  @override
  Future<bool> hasNetworkAccess() async {
    return true;
  }

  @override
  Future<List<UploadItem>> processPendingUploads({
    UploadItemsListener? onItemsUpdated,
  }) async {
    return const [];
  }

  @override
  Stream<bool> watchNetworkAccess() => const Stream<bool>.empty();
}
