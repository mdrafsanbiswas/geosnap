import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/calculate_distance_use_case.dart';
import 'features/attendance/domain/usecases/get_current_location_use_case.dart';
import 'features/attendance/domain/usecases/get_saved_office_location_use_case.dart';
import 'features/attendance/domain/usecases/save_office_location_use_case.dart';
import 'features/attendance/domain/usecases/watch_current_location_use_case.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
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
      ),
      home: RepositoryProvider.value(
        value: attendanceRepository,
        child: BlocProvider(
          create: (context) => AttendanceCubit(
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
          )..initialize(),
          child: const AttendanceScreen(),
        ),
      ),
    );
  }
}
