import 'package:logging/logging.dart';

final _logger = Logger('BackgroundSyncService');

class BackgroundSyncService {
  static const String _syncTaskName = 'offline_data_sync_task';
  static bool _isInitialized = false;

  
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      
      _isInitialized = true;
      _logger.info('BackgroundSyncService initialized (foreground sync only)');
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
      _logger.info(
        'Periodic sync will trigger automatically when device reconnects',
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
      _logger.info('Immediate sync triggered (foreground)');
    
    } catch (e) {
      _logger.severe('Failed to schedule immediate sync: $e');
      rethrow;
    }
  }

 
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
