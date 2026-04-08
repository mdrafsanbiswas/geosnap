import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/constants/app_constants.dart';
import '../data/data_sources/mock_upload_remote.dart';
import '../data/data_sources/network_checker.dart';
import '../data/data_sources/upload_queue_local.dart';
import '../data/repositories/upload_queue_repository_impl.dart';
import '../domain/usecases/process_pending_uploads.dart';

@pragma('vm:entry-point')
void uploadSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = UploadQueueRepositoryImpl(
      uploadQueueLocalDataSource: SharedPreferencesUploadQueueLocalDataSource(
        sharedPreferences,
      ),
      uploadRemoteDataSource: MockUploadRemoteDataSource(),
      networkCheckerDataSource: InternetLookupNetworkCheckerDataSource(),
    );

    await ProcessPendingUploadsUseCase(repository)();
    return Future<bool>.value(true);
  });
}

Future<void> registerUploadSyncWorker() async {
  await Workmanager().initialize(uploadSyncCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    AppConstants.uploadSyncUniqueName,
    AppConstants.uploadSyncTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
