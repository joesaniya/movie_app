import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../services/service_locator.dart';

class MovieDetailProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();

  MovieDetail? _movieDetail;
  bool _isLoading = false;
  String? _error;

  MovieDetail? get movieDetail => _movieDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMovieDetail({required String imdbId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _movieDetail = await _apiService.getMovieDetail(imdbId: imdbId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load movie details: $e';
      _movieDetail = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _movieDetail = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
