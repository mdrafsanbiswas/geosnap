import '../entities/geo_point.dart';
import '../repositories/attendance_repository.dart';

class WatchCurrentLocationUseCase {
  const WatchCurrentLocationUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  Stream<GeoPoint> call() => _attendanceRepository.watchCurrentLocation();
}
