import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/features/attendance/data/datasources/device_location.dart';
import 'src/features/attendance/data/datasources/office_location_local.dart';
import 'src/features/attendance/data/repositories/attendance_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final attendanceRepository = AttendanceRepositoryImpl(
    deviceLocationDataSource: GeolocatorDeviceLocationDataSource(),
    officeLocationLocalDataSource:
        SharedPreferencesOfficeLocationLocalDataSource(sharedPreferences),
  );

  runApp(GeoSnapApp(attendanceRepository: attendanceRepository));
}
