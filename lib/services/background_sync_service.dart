import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';
import '../services/service_locator.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';

final _logger = Logger('BackgroundSyncService');

class BackgroundSyncService {
  static const String _syncTaskName = 'offline_data_sync_task';
  static const String _oneTimeSyncTaskName = 'offline_data_one_time_sync';
  static bool _isInitialized = false;

  /// Initialize WorkManager - must be called early in app lifecycle
  /// Typically called from main() before runApp()
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

  /// Register a periodic sync task that runs every 15 minutes
  /// Useful for checking if device has connectivity and syncing pending data
  static Future<void> registerPeriodicSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel existing periodic task to avoid duplicates
      await Workmanager().cancelByTag(_syncTaskName);

      // Register a periodic task (minimum interval is 15 minutes on most platforms)
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

  /// Schedule an immediate one-time sync when device comes online
  /// More responsive than periodic sync for connectivity changes
  static Future<void> scheduleImmediateSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing one-time sync first to avoid duplicates
      await Workmanager().cancelByTag(_oneTimeSyncTaskName);

      // Schedule immediate one-time sync
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

  /// Cancel all WorkManager sync tasks
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

/// Top-level function that gets called by WorkManager in an isolated context
/// Must be a top-level function with @pragma('vm:entry-point')
/// This runs in a separate isolate, so we need to handle setup carefully
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Create a local logger since we're in an isolated context
      final logger = Logger('BackgroundSyncService.Callback');

      logger.info('Background sync task executing: $taskName');

      // Initialize services in this isolated context
      try {
        // Get or reinitialize services
        final localStorageService = LocalStorageService();
        await localStorageService.initialize();

        final apiService = ApiService(localStorageService: localStorageService);

        // Create SyncService with initialized services
        final syncService = SyncService(
          apiService: apiService,
          localStorageService: localStorageService,
        );

        // Execute the actual sync
        await syncService.syncOfflineData();

        logger.info('Background sync task completed successfully');
        return true;
      } catch (e) {
        final logger = Logger('BackgroundSyncService.Callback');
        logger.severe('Error during background sync: $e');
        // Return false to indicate failure - WorkManager will retry with backoff
        return false;
      }
    } catch (e) {
      // Catch-all for any unexpected errors
      return false;
    }
  });
}
