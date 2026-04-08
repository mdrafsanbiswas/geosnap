import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UploadProgressNotificationService {
  UploadProgressNotificationService();

  static const int _notificationId = 21001;
  static const String _channelId = 'upload_progress_channel';
  static const String _channelName = 'Upload Progress';
  static const String _channelDescription =
      'Shows ongoing photo upload progress while app is in background.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) {
      return;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(initializationSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.low,
      ),
    );

    _isInitialized = true;
  }

  Future<void> showOrUpdate({
    required int totalCount,
    required int uploadedCount,
    required int uploadingCount,
    required int retryableCount,
    required bool isOnline,
    required double progress,
  }) async {
    if (!Platform.isAndroid || totalCount <= 0) {
      return;
    }
    await initialize();

    final progressPercent = (progress.clamp(0, 1) * 100).round();
    final hasPending = uploadedCount < totalCount;
    if (!hasPending) {
      await cancel();
      return;
    }

    final title = isOnline ? 'Uploading photos' : 'Uploads waiting for network';
    final body = isOnline
        ? '$uploadedCount/$totalCount uploaded • $uploadingCount in progress'
        : '$uploadedCount/$totalCount uploaded • $retryableCount queued';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent,
      ),
    );

    await _plugin.show(_notificationId, title, body, details);
  }

  Future<void> cancel() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _plugin.cancel(_notificationId);
  }
}
