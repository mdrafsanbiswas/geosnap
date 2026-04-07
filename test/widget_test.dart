import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geosnap/src/features/attendance/data/datasources/device_location.dart';
import 'package:geosnap/src/features/attendance/data/datasources/office_location_local.dart';
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

    await tester.pumpWidget(GeoSnapApp(attendanceRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Set Office Location'), findsOneWidget);
    expect(find.text('Mark Attendance'), findsOneWidget);
  });
}

class _FakeDeviceLocationDataSource implements DeviceLocationDataSource {
  const _FakeDeviceLocationDataSource();

  @override
  Future<Position> getCurrentPosition() => Future.error(UnimplementedError());

  @override
  Stream<Position> watchPosition() => const Stream.empty();
}
