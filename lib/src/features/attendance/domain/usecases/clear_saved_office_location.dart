import '../repositories/attendance_repository.dart';

class ClearSavedOfficeLocationUseCase {
  const ClearSavedOfficeLocationUseCase(this._attendanceRepository);

  final AttendanceRepository _attendanceRepository;

  Future<void> call() {
    return _attendanceRepository.clearSavedOfficeLocation();
  }
}
