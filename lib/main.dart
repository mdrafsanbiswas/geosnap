import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
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

  runApp(GeoSnapApp(attendanceRepository: attendanceRepository));
}
