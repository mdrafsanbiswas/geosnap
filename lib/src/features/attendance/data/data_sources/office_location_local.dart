import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/location_model.dart';

abstract class OfficeLocationLocalDataSource {
  Future<LocationModel?> getSavedOfficeLocation();

  Future<void> saveOfficeLocation(LocationModel location);
}

class SharedPreferencesOfficeLocationLocalDataSource
    implements OfficeLocationLocalDataSource {
  const SharedPreferencesOfficeLocationLocalDataSource(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  @override
  Future<LocationModel?> getSavedOfficeLocation() async {
    final latitude = _sharedPreferences.getDouble(
      AppConstants.officeLatitudeKey,
    );
    final longitude = _sharedPreferences.getDouble(
      AppConstants.officeLongitudeKey,
    );
    final accuracy = _sharedPreferences.getDouble(
      AppConstants.officeAccuracyKey,
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    return LocationModel.fromStorage(
      latitude: latitude,
      longitude: longitude,
      accuracyInMeters: accuracy,
    );
  }

  @override
  Future<void> saveOfficeLocation(LocationModel location) async {
    await _sharedPreferences.setDouble(
      AppConstants.officeLatitudeKey,
      location.latitude,
    );
    await _sharedPreferences.setDouble(
      AppConstants.officeLongitudeKey,
      location.longitude,
    );
    if (location.accuracyInMeters != null) {
      await _sharedPreferences.setDouble(
        AppConstants.officeAccuracyKey,
        location.accuracyInMeters!,
      );
    } else {
      await _sharedPreferences.remove(AppConstants.officeAccuracyKey);
    }
  }
}
