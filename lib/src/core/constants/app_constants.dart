class AppConstants {
  const AppConstants._();

  static const double attendanceRadiusInMeters = 50;
  static const Duration currentLocationTimeout = Duration(seconds: 12);
  static const int locationDistanceFilterInMeters = 2;
  static const Duration locationUpdateInterval = Duration(seconds: 1);
  static const Duration staleLocationThreshold = Duration(seconds: 8);
  static const double maxTrackingAccuracyInMeters = 35;
  static const double targetCurrentFixAccuracyInMeters = 20;
  static const int locationStabilizationSampleCount = 5;
  static const Duration locationStabilizationTimeout = Duration(seconds: 4);
  static const double maxLocationJumpSpeedMetersPerSecond = 60;
  static const double minDistanceDeltaForUiUpdateInMeters = 1;
  static const String officeLatitudeKey = 'office_latitude';
  static const String officeLongitudeKey = 'office_longitude';
}
