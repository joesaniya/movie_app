import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

final _logger = Logger('SyncService');

class SyncService {
  final ApiService apiService;
  final LocalStorageService localStorageService;

  SyncService({required this.apiService, required this.localStorageService});

  Future<void> syncOfflineData() async {
    _logger.info('Starting offline data sync');

    try {
      
      await _syncUsers();

     
      await _syncBookmarks();

      _logger.info('Offline data sync completed successfully');
    } catch (e) {
      _logger.severe('Error syncing offline data: $e');
      rethrow;
    }
  }

  Future<void> _syncUsers() async {
    final unsyncedUsers = await localStorageService.getUnsyncedUsers();

    for (final user in unsyncedUsers) {
      try {
        _logger.info('Syncing user: ${user.name}');

       
        final nameParts = user.name.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1
            ? nameParts.skip(1).join(' ')
            : '';

       
        final seed = '$firstName $lastName'.toLowerCase().replaceAll(' ', '_');
        final avatarUrl =
            'https://api.dicebear.com/7.x/avataaars/svg?seed=$seed';

        final response = await apiService.createUser(
          firstName: firstName,
          lastName: lastName,
          email:
              '${user.name.toLowerCase().replaceAll(' ', '.')}@offline.local',
          avatar: avatarUrl,
        );

      
        final apiId = response.id ?? const Uuid().v4();
        await localStorageService.updateUserSyncStatus(
          userId: user.id,
          apiId: apiId,
        );

        _logger.info('User synced successfully: ${user.name} -> $apiId');
      } catch (e) {
        _logger.warning('Failed to sync user ${user.name}: $e');
       
      }
    }
  }

  Future<void> _syncBookmarks() async {
    final unsyncedBookmarks = await localStorageService.getUnsyncedBookmarks();

    for (final bookmark in unsyncedBookmarks) {
      try {
        _logger.info('Syncing bookmark: ${bookmark.movieTitle}');


        await localStorageService.markBookmarkAsSynced(bookmark.id);

        _logger.info('Bookmark synced successfully: ${bookmark.movieTitle}');
      } catch (e) {
        _logger.warning('Failed to sync bookmark ${bookmark.movieTitle}: $e');
       
      }
    }
  }

  Future<bool> hasUnsyncedData() async {
    final unsyncedUsers = await localStorageService.getUnsyncedUsers();
    final unsyncedBookmarks = await localStorageService.getUnsyncedBookmarks();

    return unsyncedUsers.isNotEmpty || unsyncedBookmarks.isNotEmpty;
  }
}
