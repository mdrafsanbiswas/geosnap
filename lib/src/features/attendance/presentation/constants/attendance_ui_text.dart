class AttendanceUiText {
  const AttendanceUiText._();

  static const title = 'Attendance';

  static const officeTitle = 'Office Location';
  static const reset = 'Reset';
  static const officeHintSet =
      'Set your office. You can reset it later if required.';
  static const officeHintLocked =
      'Office location is locked. Use reset to set it again.';
  static const officeLegend = 'Office';
  static const youLegend = 'You';
  static const setOffice = 'Set office location';
  static const officeSaved = 'Set office location';
  static const syncingLocation = 'Syncing location ..';

  static const officeMarkerTitle = 'Office Location';
  static const currentMarkerTitle = 'Your Current Location';
  static const officeMarkerId = 'office_location';
  static const currentMarkerId = 'current_location';
  static const officeRadiusId = 'office_radius';
  static const currentAccuracyId = 'current_accuracy';

  static String latLon(String lat, String lon) => 'Lat: $lat   Lon: $lon';
  static String distanceMeters(int meters) => '${meters}m';

  static const distanceUnknown = '--';
  static const officeRequired = 'Office location required';
  static const zoneInside = 'Inside attendance zone';
  static const zoneOutside = 'Outside attendance zone';
  static const setOfficeToTrack =
      'Set your office location to start distance tracking.';
  static String withinMeters(int meters) =>
      'You are within $meters meters of the office.';
  static String moveWithinMeters(int meters) =>
      'Move within $meters meters to enable attendance check-in.';
  static const ready = 'READY';
  static const moveCloser = 'MOVE CLOSER';

  static const locationRequired = 'Location access is required for attendance.';
  static const dismiss = 'Dismiss';
  static const gpsOff = 'GPS is turned off';
  static const permissionBlocked = 'Location permission is blocked';
  static const permissionNeeded = 'Location permission is needed';
  static const requestTimedOut = 'Location request timed out';
  static const temporarilyUnavailable = 'Location is temporarily unavailable';

  static const enableGps = 'Enable GPS';
  static const openAppSettings = 'Open App Settings';
  static const retryLocation = 'Retry Location';

  static String window(String start, String end) =>
      'Attendance window: $start - $end. Outside this window, it is marked late.';
  static const noMarkedYet = 'No attendance marked yet.';
  static const late = 'LATE';
  static const onTime = 'ON TIME';
  static String markedAt(String time, bool isLate) =>
      'Marked at $time - ${isLate ? late : onTime}';
  static const markAttendance = 'Mark attendance';

  static const am = 'AM';
  static const pm = 'PM';
}
