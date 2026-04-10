import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';

final _logger = Logger('BackgroundSyncService');

class BackgroundSyncService {
  static const String _syncTaskName = 'offline_data_sync_task';
  static const String _oneTimeSyncTaskName = 'offline_data_one_time_sync';
  static bool _isInitialized = false;


  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
      _isInitialized = true;
      _logger.info('BackgroundSyncService initialized with WorkManager');
    } catch (e) {
      _logger.severe('Failed to initialize BackgroundSyncService: $e');
      rethrow;
    }
  }

  
  static Future<void> registerPeriodicSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
     
      await Workmanager().cancelByTag(_syncTaskName);

      
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: const Duration(minutes: 15),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
        initialDelay: const Duration(minutes: 1),
        tag: _syncTaskName,
      );

      _logger.info(
        'Periodic sync task registered - will trigger every 15 minutes',
      );
    } catch (e) {
      _logger.severe('Failed to register periodic sync: $e');
      rethrow;
    }
  }


  static Future<void> scheduleImmediateSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      
      await Workmanager().cancelByTag(_oneTimeSyncTaskName);

    
      await Workmanager().registerOneOffTask(
        _oneTimeSyncTaskName,
        _syncTaskName,
        initialDelay: const Duration(seconds: 1),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(seconds: 5),
        tag: _oneTimeSyncTaskName,
      );

      _logger.info('Immediate sync task scheduled');
    } catch (e) {
      _logger.severe('Failed to schedule immediate sync: $e');
      rethrow;
    }
  }

 
  static Future<void> cancelAllSyncTasks() async {
    try {
      await Workmanager().cancelAll();
      _logger.info('All sync tasks cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel sync tasks: $e');
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
  static String get syncTaskName => _syncTaskName;
}


@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
     
      final logger = Logger('BackgroundSyncService.Callback');

      logger.info('Background sync task executing: $taskName');

    
      try {
       
        final localStorageService = LocalStorageService();
        await localStorageService.initialize();

        final apiService = ApiService(localStorageService: localStorageService);

      
        final syncService = SyncService(
          apiService: apiService,
          localStorageService: localStorageService,
        );

       
        await syncService.syncOfflineData();

        logger.info('Background sync task completed successfully');
        return true;
      } catch (e) {
        final logger = Logger('BackgroundSyncService.Callback');
        logger.severe('Error during background sync: $e');
     
        return false;
      }
    } catch (e) {
     
      return false;
    }
  });
}
