import '../entities/geo_point.dart';
import '../repositories/attendance_repository.dart';

class GetSavedOfficeLocationUseCase {
  const GetSavedOfficeLocationUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  Future<GeoPoint?> call() => _attendanceRepository.getSavedOfficeLocation();
}
