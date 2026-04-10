import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/bookmark_model.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';
import '../services/service_locator.dart';

final _logger = Logger('BookmarkProvider');

class BookmarkProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = getIt<LocalStorageService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();

  List<Bookmark> _bookmarks = [];
  Map<String, Set<String>> _userBookmarkedMovies = {};
  bool _isLoading = false;
  String? _error;
  bool _wasOffline = false;
  String? _currentUserId;

  BookmarkProvider() {
    _wasOffline = !_connectivityService.isOnline;
    _connectivityService.addListener(_onConnectivityChanged);
  }

  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserBookmarks(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      final bookmarks = await _localStorageService.getUserBookmarks(userId);
      _bookmarks = bookmarks;

      if (!_userBookmarkedMovies.containsKey(userId)) {
        _userBookmarkedMovies[userId] = {};
      }
      _userBookmarkedMovies[userId] = {
        for (final bookmark in bookmarks) bookmark.movieImdbId,
      };

      _error = null;
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> bookmarkMovie({
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
    try {
      final bookmark = await _localStorageService.bookmarkMovie(
        userId: userId,
        movieImdbId: movieImdbId,
        movieTitle: movieTitle,
        moviePoster: moviePoster,
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

      _bookmarks.add(bookmark);

      if (!_userBookmarkedMovies.containsKey(userId)) {
        _userBookmarkedMovies[userId] = {};
      }
      _userBookmarkedMovies[userId]!.add(movieImdbId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to bookmark movie: $e';
      notifyListeners();
    }
  }

  Future<void> removeBookmark({
    required String userId,
    required String bookmarkId,
    required String movieImdbId,
  }) async {
    try {
      await _localStorageService.removeBookmark(bookmarkId);

      _bookmarks.removeWhere((b) => b.id == bookmarkId);
      _userBookmarkedMovies[userId]?.remove(movieImdbId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove bookmark: $e';
      notifyListeners();
    }
  }

  bool isMovieBookmarked(String userId, String movieImdbId) {
    return _userBookmarkedMovies[userId]?.contains(movieImdbId) ?? false;
  }

  Future<void> loadAllBookmarks() async {
    try {
      final bookmarks = await _localStorageService.getAllBookmarks();
      _bookmarks = bookmarks;

      _userBookmarkedMovies.clear();
      for (final bookmark in bookmarks) {
        if (!_userBookmarkedMovies.containsKey(bookmark.userId)) {
          _userBookmarkedMovies[bookmark.userId] = {};
        }
        _userBookmarkedMovies[bookmark.userId]!.add(bookmark.movieImdbId);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
      notifyListeners();
    }
  }

  void reset() {
    _bookmarks.clear();
    _userBookmarkedMovies.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    final isNowOnline = _connectivityService.isOnline;

    
    if (_wasOffline && isNowOnline) {
      _logger.info(
        'Device came online, scheduling bookmarks reload after sync completes',
      );
     
      Future.delayed(const Duration(seconds: 1), () {
        if (_currentUserId != null) {
          _logger.info('Reloading bookmarks for user: $_currentUserId');
          loadUserBookmarks(_currentUserId!);
        } else {
          _logger.info('Reloading all bookmarks');
          loadAllBookmarks();
        }
      });
    }

    _wasOffline = !isNowOnline;
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
