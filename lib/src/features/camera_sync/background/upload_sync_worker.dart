import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
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

    final appDirectory = await getApplicationDocumentsDirectory();
    Hive.init(appDirectory.path);
    final uploadQueueBox = await openUploadQueueHiveBox();
    final repository = UploadQueueRepositoryImpl(
      uploadQueueLocalDataSource: HiveUploadQueueLocalDataSource(
        uploadQueueBox,
      ),
      uploadRemoteDataSource: MockUploadRemoteDataSource(),
      networkCheckerDataSource: InternetLookupNetworkCheckerDataSource(),
    );

    try {
      await ProcessPendingUploadsUseCase(repository)();
      return Future<bool>.value(true);
    } finally {
      await uploadQueueBox.close();
    }
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

Future<void> triggerUploadSyncNow() async {
  await Workmanager().registerOneOffTask(
    AppConstants.uploadSyncOneOffUniqueName,
    AppConstants.uploadSyncTaskName,
    initialDelay: Duration.zero,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
