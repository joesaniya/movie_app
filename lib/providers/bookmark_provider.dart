import 'package:flutter/material.dart';
import '../models/bookmark_model.dart';
import '../services/local_storage_service.dart';
import '../services/service_locator.dart';

class BookmarkProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = getIt<LocalStorageService>();

  List<Bookmark> _bookmarks = [];
  Map<String, Set<String>> _userBookmarkedMovies = {};
  bool _isLoading = false;
  String? _error;

  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserBookmarks(String userId) async {
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
  }) async {
    try {
      final bookmark = await _localStorageService.bookmarkMovie(
        userId: userId,
        movieImdbId: movieImdbId,
        movieTitle: movieTitle,
        moviePoster: moviePoster,
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
}
