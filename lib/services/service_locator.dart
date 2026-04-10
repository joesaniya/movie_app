import 'package:get_it/get_it.dart';
import 'package:movie_task_ap/services/api_service.dart';
import 'package:movie_task_ap/services/connectivity_service.dart';
import 'package:movie_task_ap/services/local_storage_service.dart';
import 'package:movie_task_ap/services/sync_service.dart';
import 'package:movie_task_ap/services/background_sync_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final localStorageService = LocalStorageService();
  await localStorageService.initialize();

  getIt.registerSingleton<ApiService>(
    ApiService(localStorageService: localStorageService),
  );
  getIt.registerSingleton<LocalStorageService>(localStorageService);
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<SyncService>(
    SyncService(
      apiService: getIt<ApiService>(),
      localStorageService: getIt<LocalStorageService>(),
    ),
  );

  // Initialize background sync service
  await BackgroundSyncService.initialize();
}
