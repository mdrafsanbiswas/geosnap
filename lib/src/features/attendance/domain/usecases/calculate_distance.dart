import '../entities/geo_point.dart';
import '../repositories/attendance_repository.dart';

class CalculateDistanceUseCase {
  const CalculateDistanceUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  double call({required GeoPoint origin, required GeoPoint destination}) {
    return _attendanceRepository.calculateDistanceInMeters(
      origin: origin,
      destination: destination,
    );
  }
}
