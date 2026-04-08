import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/upload_item_model.dart';

abstract class UploadQueueLocalDataSource {
  Future<List<UploadItemModel>> getUploadItems();

  Future<void> saveUploadItems(List<UploadItemModel> items);
}

class HiveUploadQueueLocalDataSource implements UploadQueueLocalDataSource {
  const HiveUploadQueueLocalDataSource(this._box);

  final Box<String> _box;

  @override
  Future<List<UploadItemModel>> getUploadItems() async {
    final encoded = _box.get(AppConstants.uploadQueueKey);
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
    return _box.put(AppConstants.uploadQueueKey, jsonEncode(payload));
  }
}

Future<Box<String>> openUploadQueueHiveBox() async {
  if (Hive.isBoxOpen(AppConstants.uploadQueueBoxName)) {
    return Hive.box<String>(AppConstants.uploadQueueBoxName);
  }

  return Hive.openBox<String>(AppConstants.uploadQueueBoxName);
}
