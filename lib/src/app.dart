import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/calculate_distance.dart';
import 'features/attendance/domain/usecases/get_current_location.dart';
import 'features/attendance/domain/usecases/get_saved_office_location.dart';
import 'features/attendance/domain/usecases/save_office_location.dart';
import 'features/attendance/domain/usecases/watch_current_location.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_event.dart';
import 'features/attendance/presentation/screens/attendance_screen.dart';

class GeoSnapApp extends StatelessWidget {
  const GeoSnapApp({required this.attendanceRepository, super.key});

  final AttendanceRepository attendanceRepository;

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
      home: RepositoryProvider.value(
        value: attendanceRepository,
        child: BlocProvider(
          create: (context) => AttendanceBloc(
            getSavedOfficeLocation: GetSavedOfficeLocationUseCase(
              context.read<AttendanceRepository>(),
            ),
            saveOfficeLocation: SaveOfficeLocationUseCase(
              context.read<AttendanceRepository>(),
            ),
            getCurrentLocation: GetCurrentLocationUseCase(
              context.read<AttendanceRepository>(),
            ),
            watchCurrentLocation: WatchCurrentLocationUseCase(
              context.read<AttendanceRepository>(),
            ),
            calculateDistance: CalculateDistanceUseCase(
              context.read<AttendanceRepository>(),
            ),
          )..add(const AttendanceInitialized()),
          child: const AttendanceScreen(),
        ),
      ),
    );
  }
}
