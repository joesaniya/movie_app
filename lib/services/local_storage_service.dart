import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/bookmark_model.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _usersBoxName = 'local_users';
  static const String _bookmarksBoxName = 'bookmarks';
  static const String _movieDetailsBoxName = 'movie_details';
  static const String _cachedApiUsersBoxName = 'cached_api_users';

  late Box<Map> _usersBox;
  late Box<Map> _bookmarksBox;
  late Box<Map> _movieDetailsBox;
  late Box<Map> _cachedApiUsersBox;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _usersBox = await Hive.openBox<Map>(_usersBoxName);
      _bookmarksBox = await Hive.openBox<Map>(_bookmarksBoxName);
      _movieDetailsBox = await Hive.openBox<Map>(_movieDetailsBoxName);
      _cachedApiUsersBox = await Hive.openBox<Map>(_cachedApiUsersBoxName);
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize local storage: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<LocalUser> createUser({
    required String name,
    required String job,
  }) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
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
    await _ensureInitialized();
    final userData = _usersBox.get(userId);
    if (userData == null) return null;
    return LocalUser.fromJson(userData.cast<String, dynamic>());
  }

  Future<List<LocalUser>> getAllUsers() async {
    await _ensureInitialized();
    final users = <LocalUser>[];
    for (final entry in _usersBox.values) {
      users.add(LocalUser.fromJson(entry.cast<String, dynamic>()));
    }
    return users;
  }

  Future<List<LocalUser>> getUnsyncedUsers() async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    final userData = _usersBox.get(userId);
    if (userData != null) {
      final user = LocalUser.fromJson(userData.cast<String, dynamic>());
      final updatedUser = user.copyWith(isSynced: true, apiId: apiId);
      await _usersBox.put(userId, updatedUser.toJson());
    }
  }

  Future<void> deleteUser(String userId) async {
    await _ensureInitialized();
    await _usersBox.delete(userId);
  }

  Future<Bookmark> bookmarkMovie({
    required String userId,
    required String movieImdbId,
    required String movieTitle,
    required String moviePoster,
    String? movieYear,
    String? moviePlot,
    String? movieDirector,
    String? movieActors,
    String? movieRated,
    String? movieRuntime,
    String? movieReleased,
    String? movieGenre,
    String? imdbRating,
  }) async {
    await _ensureInitialized();
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      userId: userId,
      movieImdbId: movieImdbId,
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      createdAt: DateTime.now(),
      isSynced: false,
      movieYear: movieYear,
      moviePlot: moviePlot,
      movieDirector: movieDirector,
      movieActors: movieActors,
      movieRated: movieRated,
      movieRuntime: movieRuntime,
      movieReleased: movieReleased,
      movieGenre: movieGenre,
      imdbRating: imdbRating,
    );

    await _bookmarksBox.put(bookmark.id, bookmark.toJson());
    return bookmark;
  }

  Future<void> removeBookmark(String bookmarkId) async {
    await _ensureInitialized();
    await _bookmarksBox.delete(bookmarkId);
  }

  Future<List<Bookmark>> getUserBookmarks(String userId) async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    final bookmarks = <Bookmark>[];
    for (final entry in _bookmarksBox.values) {
      bookmarks.add(Bookmark.fromJson(entry.cast<String, dynamic>()));
    }
    return bookmarks;
  }

  Future<List<Bookmark>> getUnsyncedBookmarks() async {
    await _ensureInitialized();
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
    await _ensureInitialized();
    for (final entry in _bookmarksBox.values) {
      final bookmark = Bookmark.fromJson(entry.cast<String, dynamic>());
      if (bookmark.userId == userId && bookmark.movieImdbId == movieImdbId) {
        return true;
      }
    }
    return false;
  }

  Future<void> markBookmarkAsSynced(String bookmarkId) async {
    await _ensureInitialized();
    final bookmarkData = _bookmarksBox.get(bookmarkId);
    if (bookmarkData != null) {
      final bookmark = Bookmark.fromJson(bookmarkData.cast<String, dynamic>());
      final updated = bookmark.copyWith(isSynced: true);
      await _bookmarksBox.put(bookmarkId, updated.toJson());
    }
  }

  Future<void> cacheMovieDetail(MovieDetail movieDetail) async {
    await _ensureInitialized();
    final movieData = movieDetail.toJson();
    movieData['_cachedAt'] = DateTime.now().toIso8601String();
    await _movieDetailsBox.put(movieDetail.imdbId, movieData);
  }

  Future<MovieDetail?> getCachedMovieDetail(String imdbId) async {
    await _ensureInitialized();
    final movieData = _movieDetailsBox.get(imdbId);
    if (movieData == null) return null;
    try {
      return MovieDetail.fromJson(movieData.cast<String, dynamic>());
    } catch (e) {
      return null;
    }
  }

  Future<List<MovieDetail>> getAllCachedMovieDetails() async {
    await _ensureInitialized();
    final movieDetails = <MovieDetail>[];
    for (final entry in _movieDetailsBox.values) {
      try {
        movieDetails.add(MovieDetail.fromJson(entry.cast<String, dynamic>()));
      } catch (e) {
        continue;
      }
    }
    return movieDetails;
  }

  Future<bool> isMovieDetailCached(String imdbId) async {
    await _ensureInitialized();
    return _movieDetailsBox.containsKey(imdbId);
  }

  Future<void> clearMovieDetailsCache() async {
    await _ensureInitialized();
    await _movieDetailsBox.clear();
  }

  
  Future<void> cacheApiUsers(List<User> users) async {
    await _ensureInitialized();
    final userData = users.map((u) => u.toJson()).toList();
    await _cachedApiUsersBox.put('cached_users', {'users': userData});
  }

  
  Future<List<User>> getCachedApiUsers() async {
    await _ensureInitialized();
    final cachedData = _cachedApiUsersBox.get('cached_users');
    if (cachedData == null) return [];

    try {
      final usersList = cachedData['users'] as List;
      return usersList
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  
  Future<void> clearCachedApiUsers() async {
    await _ensureInitialized();
    await _cachedApiUsersBox.clear();
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _usersBox.clear();
    await _bookmarksBox.clear();
    await _movieDetailsBox.clear();
    await _cachedApiUsersBox.clear();
  }
}
