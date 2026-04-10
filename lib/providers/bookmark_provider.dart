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
  Set<String> _globalBookmarkedMovies = {};
  bool _isLoading = false;
  String? _error;
  bool _wasOffline = false;

  BookmarkProvider() {
    _wasOffline = !_connectivityService.isOnline;
    _connectivityService.addListener(_onConnectivityChanged);
  }

  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserBookmarks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final bookmarks = await _localStorageService.getAllBookmarks();
      _bookmarks = bookmarks;

      _globalBookmarkedMovies = {
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
      // Validate that userId is provided and not empty
      if (userId.isEmpty) {
        _error = 'A valid user must be selected to bookmark movies';
        notifyListeners();
        return;
      }

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
      _globalBookmarkedMovies.add(movieImdbId);

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
      _globalBookmarkedMovies.remove(movieImdbId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove bookmark: $e';
      notifyListeners();
    }
  }

  bool isMovieBookmarked(String movieImdbId) {
    return _globalBookmarkedMovies.contains(movieImdbId);
  }

  Future<void> loadAllBookmarks() async {
    try {
      final bookmarks = await _localStorageService.getAllBookmarks();
      _bookmarks = bookmarks;

      _globalBookmarkedMovies = {
        for (final bookmark in bookmarks) bookmark.movieImdbId,
      };

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load bookmarks: $e';
      notifyListeners();
    }
  }

  void reset() {
    _bookmarks.clear();
    _globalBookmarkedMovies.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    final isNowOnline = _connectivityService.isOnline;

    if (_wasOffline && isNowOnline) {
      _logger.info('Device came online, reloading all bookmarks');
      Future.delayed(const Duration(seconds: 1), () {
        _logger.info('Reloading all bookmarks after sync');
        loadAllBookmarks();
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
