import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/upload_item_model.dart';

abstract class UploadQueueLocalDataSource {
  Future<List<UploadItemModel>> getUploadItems();

  Future<void> saveUploadItems(List<UploadItemModel> items);
}

class SharedPreferencesUploadQueueLocalDataSource
    implements UploadQueueLocalDataSource {
  const SharedPreferencesUploadQueueLocalDataSource(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  @override
  Future<List<UploadItemModel>> getUploadItems() async {
    final encoded = _sharedPreferences.getString(AppConstants.uploadQueueKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List<dynamic>) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => UploadItemModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveUploadItems(List<UploadItemModel> items) {
    final payload = items.map((item) => item.toMap()).toList(growable: false);
    return _sharedPreferences.setString(
      AppConstants.uploadQueueKey,
      jsonEncode(payload),
    );
  }
}
