import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/bookmark_model.dart';

class LocalStorageService {
  static const String _usersBoxName = 'local_users';
  static const String _bookmarksBoxName = 'bookmarks';

  late Box<Map> _usersBox;
  late Box<Map> _bookmarksBox;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _usersBox = await Hive.openBox<Map>(_usersBoxName);
      _bookmarksBox = await Hive.openBox<Map>(_bookmarksBoxName);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize local storage: $e');
    }
  }

 
  Future<LocalUser> createUser({
    required String name,
    required String job,
  }) async {
    final user = LocalUser(
      id: const Uuid().v4(),
      name: name,
      job: job,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await _usersBox.put(user.id, user.toJson());
    return user;
  }

  Future<LocalUser> createSyncedUser({
    required String name,
    required String job,
    required String apiId,
  }) async {
    final user = LocalUser(
      id: const Uuid().v4(),
      name: name,
      job: job,
      apiId: apiId,
      createdAt: DateTime.now(),
      isSynced: true,
    );

    await _usersBox.put(user.id, user.toJson());
    return user;
  }

  Future<LocalUser?> getUserById(String userId) async {
    final userData = _usersBox.get(userId);
    if (userData == null) return null;
    return LocalUser.fromJson(userData.cast<String, dynamic>());
  }

  Future<List<LocalUser>> getAllUsers() async {
    final users = <LocalUser>[];
    for (final entry in _usersBox.values) {
      users.add(LocalUser.fromJson(entry.cast<String, dynamic>()));
    }
    return users;
  }

  Future<List<LocalUser>> getUnsyncedUsers() async {
    final unsyncedUsers = <LocalUser>[];
    for (final entry in _usersBox.values) {
      final user = LocalUser.fromJson(entry.cast<String, dynamic>());
      if (!user.isSynced) {
        unsyncedUsers.add(user);
      }
    }
    return unsyncedUsers;
  }

  Future<void> updateUserSyncStatus({
    required String userId,
    required String apiId,
  }) async {
    final userData = _usersBox.get(userId);
    if (userData != null) {
      final user = LocalUser.fromJson(userData.cast<String, dynamic>());
      final updatedUser = user.copyWith(isSynced: true, apiId: apiId);
      await _usersBox.put(userId, updatedUser.toJson());
    }
  }

  Future<void> deleteUser(String userId) async {
    await _usersBox.delete(userId);
  }

 
  Future<Bookmark> bookmarkMovie({
    required String userId,
    required String movieImdbId,
    required String movieTitle,
    required String moviePoster,
  }) async {
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      userId: userId,
      movieImdbId: movieImdbId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await _bookmarksBox.put(bookmark.id, bookmark.toJson());
    return bookmark;
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await _bookmarksBox.delete(bookmarkId);
  }

  Future<List<Bookmark>> getUserBookmarks(String userId) async {
    final bookmarks = <Bookmark>[];
    for (final entry in _bookmarksBox.values) {
      final bookmark = Bookmark.fromJson(entry.cast<String, dynamic>());
      if (bookmark.userId == userId) {
        bookmarks.add(bookmark);
      }
    }
    return bookmarks;
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final bookmarks = <Bookmark>[];
    for (final entry in _bookmarksBox.values) {
      bookmarks.add(Bookmark.fromJson(entry.cast<String, dynamic>()));
    }
    return bookmarks;
  }

  Future<List<Bookmark>> getUnsyncedBookmarks() async {
    final unsyncedBookmarks = <Bookmark>[];
    for (final entry in _bookmarksBox.values) {
      final bookmark = Bookmark.fromJson(entry.cast<String, dynamic>());
      if (!bookmark.isSynced) {
        unsyncedBookmarks.add(bookmark);
      }
    }
    return unsyncedBookmarks;
  }

  Future<bool> isMovieBookmarked({
    required String userId,
    required String movieImdbId,
  }) async {
    for (final entry in _bookmarksBox.values) {
      final bookmark = Bookmark.fromJson(entry.cast<String, dynamic>());
      if (bookmark.userId == userId && bookmark.movieImdbId == movieImdbId) {
        return true;
      }
    }
    return false;
  }

  Future<void> markBookmarkAsSynced(String bookmarkId) async {
    final bookmarkData = _bookmarksBox.get(bookmarkId);
    if (bookmarkData != null) {
      final bookmark = Bookmark.fromJson(bookmarkData.cast<String, dynamic>());
      final updated = bookmark.copyWith(isSynced: true);
      await _bookmarksBox.put(bookmarkId, updated.toJson());
    }
  }

  Future<void> clear() async {
    await _usersBox.clear();
    await _bookmarksBox.clear();
  }
}
