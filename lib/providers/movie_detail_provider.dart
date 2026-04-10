import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/service_locator.dart';

final _logger = Logger('MovieDetailProvider');

class MovieDetailProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();

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
      _error = null;
      _isOfflineData = false;
    } catch (e) {
      _error = 'Failed to load movie details: $e';
      _movieDetail = null;
      _isOfflineData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load movie detail from bookmark data (for offline viewing)
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

  void reset() {
    _movieDetail = null;
    _isLoading = false;
    _error = null;
    _isOfflineData = false;
    notifyListeners();
  }
}
