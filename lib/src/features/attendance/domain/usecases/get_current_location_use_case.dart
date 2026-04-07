import '../entities/geo_point.dart';
import '../repositories/attendance_repository.dart';

class GetCurrentLocationUseCase {
  const GetCurrentLocationUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  Future<GeoPoint> call() => _attendanceRepository.getCurrentLocation();
}
