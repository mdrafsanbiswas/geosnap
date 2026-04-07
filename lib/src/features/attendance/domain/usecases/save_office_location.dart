import '../entities/geo_point.dart';
import '../repositories/attendance_repository.dart';

class SaveOfficeLocationUseCase {
  const SaveOfficeLocationUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  Future<void> call(GeoPoint location) {
    return _attendanceRepository.saveOfficeLocation(location);
  }
}
