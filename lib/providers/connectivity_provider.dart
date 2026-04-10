import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/background_sync_service.dart';
import '../services/service_locator.dart';

final _logger = Logger('ConnectivityProvider');

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  bool _wasOffline = false;

  ConnectivityProvider() {
    _wasOffline = !_connectivityService.isOnline;
    _connectivityService.addListener(_onConnectivityChanged);
  }

  bool get isOnline => _connectivityService.isOnline;

  void _onConnectivityChanged() {
    final isNowOnline = _connectivityService.isOnline;

    if (_wasOffline && isNowOnline) {
      _triggerOfflineDataSync();
    }

    _wasOffline = !isNowOnline;
    notifyListeners();
  }

  void _triggerOfflineDataSync() {
   
    _logger.info('Device went online, starting foreground sync...');
    final syncService = getIt<SyncService>();
    syncService
        .syncOfflineData()
        .then((_) {
          _logger.info('Foreground sync completed');
        })
        .catchError((e) {
          _logger.severe('Foreground sync failed: $e');
        });

    
    BackgroundSyncService.scheduleImmediateSync().catchError((e) {
      _logger.warning('Failed to schedule background sync: $e');
    });
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
