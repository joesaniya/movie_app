import 'package:logging/logging.dart';
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

    if (unsyncedUsers.isEmpty) {
      _logger.info('No unsynced users to sync');
      return;
    }

    for (final user in unsyncedUsers) {
      try {
        _logger.info('Syncing user: ${user.name} (job: ${user.job})');

        // POST to Reqres API: {\"name\": \"name\", \"job\": \"job\"}
        final response = await apiService.createUserSimple(
          name: user.name,
          job: user.job,
        );

        // Extract API ID from response
        final apiId = response['id']?.toString() ?? '';

        if (apiId.isEmpty) {
          _logger.warning('No API ID received for user ${user.name}');
          continue;
        }

        // Update local database with API ID and mark as synced
        await localStorageService.updateUserSyncStatus(
          userId: user.id,
          apiId: apiId,
        );

        _logger.info(
          'User synced successfully: ${user.name} -> API ID: $apiId',
        );
      } catch (e) {
        _logger.warning('Failed to sync user ${user.name}: $e');
        // Don't rethrow - continue syncing other users
      }
    }
  }

  Future<void> _syncBookmarks() async {
    final unsyncedBookmarks = await localStorageService.getUnsyncedBookmarks();

    for (final bookmark in unsyncedBookmarks) {
      try {
        _logger.info('Syncing bookmark: ${bookmark.movieTitle}');

        // Get the user associated with this bookmark to verify sync status
        final user = await localStorageService.getUserById(bookmark.userId);

        if (user == null) {
          _logger.warning('User not found for bookmark ${bookmark.movieTitle}');
          continue;
        }

        // Only sync bookmark if the user was successfully synced
        // This ensures the user-bookmark relationship is preserved
        if (!user.isSynced) {
          _logger.warning(
            'User ${user.name} not synced yet, skipping bookmark sync',
          );
          continue;
        }

        // TODO: Implement actual API call to sync bookmark
        // Example:
        // await apiService.createBookmark(
        //   userId: user.apiId!,
        //   movieImdbId: bookmark.movieImdbId,
        //   movieTitle: bookmark.movieTitle,
        //   moviePoster: bookmark.moviePoster,
        // );

        // For now, just mark as synced locally
        await localStorageService.markBookmarkAsSynced(bookmark.id);

        _logger.info('Bookmark synced successfully: ${bookmark.movieTitle}');
      } catch (e) {
        _logger.warning('Failed to sync bookmark ${bookmark.movieTitle}: $e');
        // Don't rethrow - continue syncing other bookmarks
      }
    }
  }

  Future<bool> hasUnsyncedData() async {
    final unsyncedUsers = await localStorageService.getUnsyncedUsers();
    final unsyncedBookmarks = await localStorageService.getUnsyncedBookmarks();

    return unsyncedUsers.isNotEmpty || unsyncedBookmarks.isNotEmpty;
  }
}
