class AppConstants {
  const AppConstants._();

  static const double attendanceRadiusInMeters = 50;
  static const Duration currentLocationTimeout = Duration(seconds: 8);
  static const int locationDistanceFilterInMeters = 2;
  static const Duration locationUpdateInterval = Duration(seconds: 1);
  static const Duration staleLocationThreshold = Duration(seconds: 8);
  static const double maxTrackingAccuracyInMeters = 30;
  static const double targetCurrentFixAccuracyInMeters = 12;
  static const int locationStabilizationSampleCount = 5;
  static const Duration locationStabilizationTimeout = Duration(seconds: 3);
  static const double maxLocationJumpSpeedMetersPerSecond = 18;
  static const int locationSmoothingWindowSize = 4;
  static const double fallbackLocationAccuracyInMeters = 6;
  static const double nearDistanceCompensationThresholdInMeters = 30;
  static const double maxNearDistanceCompensationInMeters = 8;
  static const double nearDistanceCompensationFactor = 0.25;
  static const double minDistanceDeltaForUiUpdateInMeters = 1;
  static const int attendanceStartHour = 9;
  static const int attendanceStartMinute = 0;
  static const int attendanceEndHour = 10;
  static const int attendanceEndMinute = 30;
  static const String officeLatitudeKey = 'office_latitude';
  static const String officeLongitudeKey = 'office_longitude';
  static const String officeAccuracyKey = 'office_accuracy';
  static const String uploadQueueBoxName = 'upload_queue_box';
  static const String uploadQueueKey = 'upload_queue_items';
  static const String uploadSyncTaskName = 'upload_sync_task';
  static const String uploadSyncUniqueName = 'upload_sync_periodic_task';
  static const String uploadSyncOneOffUniqueName = 'upload_sync_one_off_task';
}
