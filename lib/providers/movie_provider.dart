import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';

class PaginatedMoviesProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();

  List<Movie> _movies = [];
  int _currentPage = 1;
  int _totalResults = 0;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  String _searchQuery = 'popular';

  List<Movie> get movies => _movies;
  int get currentPage => _currentPage;
  int get totalResults => _totalResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

  Future<void> getTrendingMovies({bool refresh = false}) async {
    if (!refresh && _isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _movies.clear();
      _error = null;
      _searchQuery = 'popular';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getTrendingMovies(page: _currentPage);

      if (response.isSuccess && response.movies != null) {
        _movies.addAll(response.movies!);
        _totalResults = response.total;
        _currentPage++;
        _hasMore = _movies.length < _totalResults;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to fetch movies';
      }
    } catch (e) {
      _error = 'Failed to load movies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMovies({
    required String query,
    bool refresh = false,
  }) async {
    if (!refresh && _isLoading) return;

    if (refresh || _searchQuery != query) {
      _currentPage = 1;
      _movies.clear();
      _error = null;
      _searchQuery = query;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.searchMovies(
        query: query,
        page: _currentPage,
      );

      if (response.isSuccess && response.movies != null) {
        _movies.addAll(response.movies!);
        _totalResults = response.total;
        _currentPage++;
        _hasMore = _movies.length < _totalResults;
        _error = null;
      } else {
        _error = response.error ?? 'No movies found';
      }
    } catch (e) {
      _error = 'Failed to search movies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Movie? getMovieById(String imdbId) {
    try {
      return _movies.firstWhere((m) => m.imdbId == imdbId);
    } catch (e) {
      return null;
    }
  }

  void reset() {
    _movies.clear();
    _currentPage = 1;
    _totalResults = 0;
    _isLoading = false;
    _error = null;
    _hasMore = true;
    _searchQuery = 'popular';
    notifyListeners();
  }
}
