import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/service_locator.dart';

final _logger = Logger('MovieDetailProvider');

class MovieDetailProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();
  final LocalStorageService _localStorageService = getIt<LocalStorageService>();

  MovieDetail? _movieDetail;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineData = false;

  MovieDetail? get movieDetail => _movieDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineData => _isOfflineData;

  Future<void> fetchMovieDetail({required String imdbId}) async {
    _isLoading = true;
    _error = null;
    _isOfflineData = false;
    notifyListeners();

    try {
      _movieDetail = await _apiService.getMovieDetail(imdbId: imdbId);

     
      if (_movieDetail?.response != 'True') {
        
        _logger.warning('Movie not found in API: $imdbId, checking cache...');
        final cachedDetail = await _localStorageService.getCachedMovieDetail(
          imdbId,
        );
        if (cachedDetail != null) {
          _movieDetail = cachedDetail;
          _error = 'Viewing cached data (offline mode)';
          _isOfflineData = true;
        } else {
          _error = 'Movie details not found';
          _movieDetail = null;
          _isOfflineData = false;
        }
      } else {
        _error = null;
        _isOfflineData = false;
      }
    } catch (e) {
      _logger.warning('Failed to load movie from API: $e, trying cache...');

      
      try {
        final cachedDetail = await _localStorageService.getCachedMovieDetail(
          imdbId,
        );
        if (cachedDetail != null) {
          _movieDetail = cachedDetail;
          _error = 'Viewing cached data (offline mode)';
          _isOfflineData = true;
        } else {
          _error = 'Failed to load movie details: $e';
          _movieDetail = null;
          _isOfflineData = false;
        }
      } catch (cacheError) {
        _logger.severe('Error loading from cache: $cacheError');
        _error = 'Failed to load movie details: $e';
        _movieDetail = null;
        _isOfflineData = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 
  void loadMovieDetailFromBookmark({
    required String title,
    required String year,
    required String imdbId,
    String? rated,
    String? released,
    String? runtime,
    String? genre,
    String? director,
    String? actors,
    String? plot,
    String? poster,
    String? imdbRating,
  }) {
    _movieDetail = MovieDetail(
      title: title,
      year: year,
      imdbId: imdbId,
      rated: rated,
      released: released,
      runtime: runtime,
      genre: genre,
      director: director,
      actors: actors,
      plot: plot,
      poster: poster,
      imdbRating: imdbRating,
      response: 'True',
    );
    _isOfflineData = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

 
  Future<void> loadFromCacheIfAvailable({required String imdbId}) async {
    try {
      final cachedDetail = await _localStorageService.getCachedMovieDetail(
        imdbId,
      );
      if (cachedDetail != null) {
        _movieDetail = cachedDetail;
        _isOfflineData = true;
        _isLoading = false;
        _error = null;
        _logger.info('Loaded movie detail from cache: $imdbId');
        notifyListeners();
      }
    } catch (e) {
      _logger.warning('Could not load from cache: $e');
     
    }
  }

  void reset() {
    _movieDetail = null;
    _isLoading = false;
    _error = null;
    _isOfflineData = false;
    notifyListeners();
  }
}
