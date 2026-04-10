import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';
import '../services/connectivity_service.dart';
import '../services/local_storage_service.dart';
import 'dart:developer';

class PaginatedMoviesProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();
  final LocalStorageService _localStorageService = getIt<LocalStorageService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();

  final List<Movie> _movies = [];
  int _currentPage = 1;
  int _totalResults = 0;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  String _searchQuery = 'popular';
  bool _wasOffline = false;

  List<Movie> get movies => _movies;
  int get currentPage => _currentPage;
  int get totalResults => _totalResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;

  PaginatedMoviesProvider() {
    _wasOffline = !_connectivityService.isOnline;
    _connectivityService.addListener(_onConnectivityChanged);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      
      final cachedMovies = await _localStorageService.getCachedTrendingMovies();
      if (cachedMovies.isNotEmpty) {
        _movies.addAll(cachedMovies);
        _totalResults = cachedMovies.length;
        _hasMore = false;

        if (_wasOffline) {
          _error = 'Viewing cached movies (offline mode)';
        }
        notifyListeners();
      }
    } catch (e) {
      log('Error initializing cached movies: $e');
    }
  }

  void _onConnectivityChanged() {
    final isNowOnline = _connectivityService.isOnline;

    if (_wasOffline && isNowOnline) {
     
      getTrendingMovies(refresh: true);
    } else if (!_wasOffline && !isNowOnline) {
     
      _loadOfflineMovies();
    }

    _wasOffline = !isNowOnline;
  }

  Future<void> _loadOfflineMovies() async {
    try {
      if (_movies.isEmpty) {
        final cachedMovies = await _localStorageService
            .getCachedTrendingMovies();
        if (cachedMovies.isNotEmpty) {
          _movies.clear();
          _movies.addAll(cachedMovies);
          _totalResults = cachedMovies.length;
          _hasMore = false;
          _error = 'Viewing cached movies (offline mode)';
          notifyListeners();
        }
      } else {
        _error = 'Viewing cached movies (offline mode)';
        notifyListeners();
      }
    } catch (e) {
      log('Error loading offline movies: $e');
    }
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }

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
     
      if (!_connectivityService.isOnline && !refresh) {
        log('Offline mode detected - attempting to load cached movies');
        final cachedMovies = await _localStorageService
            .getCachedTrendingMovies();
        if (cachedMovies.isNotEmpty) {
          _movies.addAll(cachedMovies);
          _totalResults = cachedMovies.length;
          _currentPage = 1;
          _hasMore = false;
          _error = 'Viewing cached movies (offline mode)';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      
      final response = await _apiService.getTrendingMovies(page: _currentPage);

      if (response.isSuccess && response.movies != null) {
        _movies.addAll(response.movies!);
        _totalResults = response.total;
        _currentPage++;
        _hasMore = _movies.length < _totalResults;
        _error = null;

       
        await _localStorageService.cacheTrendingMovies(_movies).catchError((e) {
          log('Warning: Failed to cache trending movies: $e');
        });

        _apiService.preCacheMovieDetails(response.movies!).catchError((e) {
          log('Warning: Failed to pre-cache movie details: $e');
        });
      } else {
        _error = response.error ?? 'Failed to fetch movies';

        
        if (!_connectivityService.isOnline) {
          final cachedMovies = await _localStorageService
              .getCachedTrendingMovies();
          if (cachedMovies.isNotEmpty) {
            _movies.addAll(cachedMovies);
            _error = 'Viewing cached movies (offline mode)';
            _hasMore = false;
          }
        }
      }
    } catch (e) {
      log('Error fetching trending movies: $e');
      
      final cachedMovies = await _localStorageService.getCachedTrendingMovies();
      if (cachedMovies.isNotEmpty) {
        _movies.addAll(cachedMovies);
        _error = 'Viewing cached movies (offline mode)';
        _hasMore = false;
      } else {
        _error = 'Failed to load movies: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMovies({
    required String query,
    bool refresh = false,
  }) async {
    log('Searching movies with query: $query, refresh: $refresh');
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
      if (!_connectivityService.isOnline) {
        log('Offline mode detected - attempting local search on cached movies');
        final localResults = await _performLocalSearch(query);
        if (localResults.isNotEmpty) {
          _movies.addAll(localResults);
          _totalResults = localResults.length;
          _currentPage = 1;
          _hasMore = false;
          _error = 'Searching offline - results from cached movies';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      
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

       
        await _localStorageService.cacheSearchMovies(query, _movies).catchError(
          (e) {
            log('Warning: Failed to cache search results: $e');
          },
        );

        _apiService.preCacheMovieDetails(response.movies!).catchError((e) {
          log('Warning: Failed to pre-cache movie details: $e');
        });
      } else {
        _error = response.error ?? 'No movies found';

        
        if (!_connectivityService.isOnline) {
          final cachedMovies = await _localStorageService.getCachedSearchMovies(
            query,
          );
          if (cachedMovies.isNotEmpty) {
            _movies.addAll(cachedMovies);
            _error = 'Viewing cached search results (offline mode)';
            _hasMore = false;
          }
        }
      }
    } catch (e) {
      log('Error searching movies: $e');
     
      final cachedMovies = await _localStorageService.getCachedSearchMovies(
        query,
      );
      if (cachedMovies.isNotEmpty) {
        _movies.addAll(cachedMovies);
        _error = 'Viewing cached search results (offline mode)';
        _hasMore = false;
      } else if (!_connectivityService.isOnline) {
        _error =
            'No offline search available - search requires internet connection';
      } else {
        _error = 'Failed to search movies: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Movie>> _performLocalSearch(String query) async {
    try {
     
      final allMovies = await _localStorageService.getCachedTrendingMovies();

      if (allMovies.isEmpty) {
        log('No cached movies available for local search');
        return [];
      }

      
      final searchTerm = query.toLowerCase();
      final results = allMovies.where((movie) {
        final title = movie.title.toLowerCase();
        final plot = (movie.plot ?? '').toLowerCase();
        return title.contains(searchTerm) || plot.contains(searchTerm);
      }).toList();

      log('Local search found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      log('Error performing local search: $e');
      return [];
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
