import 'package:logging/logging.dart';

final _logger = Logger('BackgroundSyncService');

class BackgroundSyncService {
  static const String _syncTaskName = 'offline_data_sync_task';
  static bool _isInitialized = false;

  /// Initialize background sync service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For now, we rely on ConnectivityProvider foreground sync
      // which triggers automatically when device reconnects
      _isInitialized = true;
      _logger.info('BackgroundSyncService initialized (foreground sync only)');
    } catch (e) {
      _logger.severe('Failed to initialize BackgroundSyncService: $e');
      rethrow;
    }
  }

  /// Register periodic background sync task
  /// Currently uses foreground sync when device reconnects
  /// Production: Implement with WorkManager 0.9.0+ or Firebase Cloud Messaging
  static Future<void> registerPeriodicSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.info(
        'Periodic sync will trigger automatically when device reconnects',
      );
      // Foreground sync is handled by ConnectivityProvider
    } catch (e) {
      _logger.severe('Failed to register periodic sync: $e');
      rethrow;
    }
  }

  /// Schedule immediate sync task when device goes online
  /// This is handled by ConnectivityProvider foreground sync
  static Future<void> scheduleImmediateSync() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.info('Immediate sync triggered (foreground)');
      // Actual sync is handled by ConnectivityProvider
    } catch (e) {
      _logger.severe('Failed to schedule immediate sync: $e');
      rethrow;
    }
  }

  /// Cancel all background sync tasks
  static Future<void> cancelAllSyncTasks() async {
    try {
      _isInitialized = false;
      _logger.info('All sync tasks cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel sync tasks: $e');
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
  static String get syncTaskName => _syncTaskName;
}
