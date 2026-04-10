import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import '../models/movie_model.dart';
import 'network_interceptor.dart';
import 'local_storage_service.dart';

final _logger = Logger('ApiService');

class ApiService {
  static const String baseUrlUsers = 'https://reqres.in/api';
  static const String baseUrlMovies = 'https://www.omdbapi.com';
  static const String movieApiKey = 'eac7cc99';
  static const String reqresApiKey = 'reqres_e76eb59af1234a00ae6db056b038d1e1';

  late final Dio _dioUsers;
  late final Dio _dioMovies;
  final LocalStorageService _localStorageService;

  ApiService({LocalStorageService? localStorageService})
    : _localStorageService = localStorageService ?? LocalStorageService() {
    _dioUsers = Dio(
      BaseOptions(
        baseUrl: baseUrlUsers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': reqresApiKey,
        },
      ),
    );
    log('ApiService initialized with base URLs: $baseUrlUsers, $_dioUsers');
    _dioMovies = Dio(
      BaseOptions(
        baseUrl: baseUrlMovies,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // _dioUsers.interceptors.add(SimulatedFailureInterceptor());
    _dioUsers.interceptors.add(NetworkInterceptor());

    // _dioMovies.interceptors.add(SimulatedFailureInterceptor());
    _dioMovies.interceptors.add(NetworkInterceptor());
  }

  Future<UsersResponse> fetchUsers({int page = 1}) async {
    log('Fetching users - Page: $page');
    try {
      _logger.info('Fetching users - Page: $page');
      final response = await _dioUsers.get(
        '/users',
        queryParameters: {'page': page, 'per_page': 6},
      );
      return UsersResponse.fromJson(response.data);
    } catch (e) {
      _logger.severe('Error fetching users: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUserSimple({
    required String name,
    required String job,
  }) async {
    try {
      _logger.info('Creating user via Reqres API: $name - $job');
      final response = await _dioUsers.post(
        '/users',
        data: {'name': name, 'job': job},
      );
      _logger.info('User created successfully with ID: ${response.data['id']}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      _logger.severe('Error creating user: $e');
      rethrow;
    }
  }

  Future<CreateUserResponse> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String avatar,
  }) async {
    try {
      _logger.info('Creating user: $firstName $lastName');
      final response = await _dioUsers.post(
        '/users',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'avatar': avatar,
        },
      );
      return CreateUserResponse.fromJson(response.data);
    } catch (e) {
      _logger.severe('Error creating user: $e');
      rethrow;
    }
  }

  Future<MovieSearchResponse> searchMovies({
    required String query,
    int page = 1,
  }) async {
    try {
      _logger.info('Searching movies: $query - Page: $page');
      final response = await _dioMovies.get(
        '',
        queryParameters: {
          's': query,
          'page': page,
          'apikey': movieApiKey,
          'type': 'movie',
        },
      );
      return MovieSearchResponse.fromJson(response.data);
    } on DioException catch (e) {
      _logger.severe('Error searching movies: $e');
      rethrow;
    }
  }

  Future<MovieDetail> getMovieDetail({required String imdbId}) async {
    try {
      _logger.info('Fetching movie detail: $imdbId');
      final response = await _dioMovies.get(
        '',
        queryParameters: {'i': imdbId, 'apikey': movieApiKey, 'type': 'movie'},
      );
      final movieDetail = MovieDetail.fromJson(response.data);

      if (movieDetail.response != 'True') {
        _logger.warning('API returned "not found" response for: $imdbId');

        final cachedDetail = await _localStorageService.getCachedMovieDetail(
          imdbId,
        );
        if (cachedDetail != null) {
          _logger.info('Returning cached movie detail for: $imdbId');
          return cachedDetail;
        }
        throw Exception('Movie not found: $imdbId');
      }

      await _localStorageService.cacheMovieDetail(movieDetail);
      return movieDetail;
    } on DioException catch (e) {
      _logger.warning(
        'Network error fetching movie detail for $imdbId: $e. Checking cache...',
      );

      final cachedDetail = await _localStorageService.getCachedMovieDetail(
        imdbId,
      );
      if (cachedDetail != null) {
        _logger.info('Returning cached movie detail for: $imdbId');
        return cachedDetail;
      }
      _logger.severe(
        'Error fetching movie detail and no cache available for: $imdbId',
      );
      rethrow;
    }
  }

  Future<MovieSearchResponse> getTrendingMovies({int page = 1}) async {
    return searchMovies(query: 'popular', page: page);
  }

  /// Pre-caches movie details for a list of movies in the background.
  /// This ensures all movies from search results are available offline.
  /// Runs without blocking and silently ignores errors for individual movies.
  Future<void> preCacheMovieDetails(List<Movie> movies) async {
    if (movies.isEmpty) return;

    _logger.info('Starting to pre-cache details for ${movies.length} movies');

    // Fetch all movie details concurrently with controlled rate limiting
    final futures = <Future<void>>[];
    for (final movie in movies) {
      futures.add(
        _fetchAndCacheMovieDetail(movie.imdbId).catchError((e) {
          _logger.warning(
            'Failed to pre-cache details for ${movie.imdbId}: $e',
          );
          // Silently ignore errors - we don't want to block the UI
        }),
      );
    }

    // Wait for all requests to complete (in parallel or with reasonable concurrency)
    await Future.wait(futures);
    _logger.info('Pre-caching complete for ${movies.length} movies');
  }

  /// Fetches and caches a single movie detail.
  /// Returns null if already cached or if fetch fails.
  Future<void> _fetchAndCacheMovieDetail(String imdbId) async {
    try {
      // Check if already cached to avoid redundant API calls
      final cached = await _localStorageService.getCachedMovieDetail(imdbId);
      if (cached != null) {
        _logger.info('Movie detail already cached: $imdbId');
        return;
      }

      _logger.info('Pre-caching movie detail: $imdbId');
      final response = await _dioMovies.get(
        '',
        queryParameters: {'i': imdbId, 'apikey': movieApiKey, 'type': 'movie'},
      );

      final movieDetail = MovieDetail.fromJson(response.data);
      if (movieDetail.response == 'True') {
        await _localStorageService.cacheMovieDetail(movieDetail);
        _logger.info('Successfully cached movie detail: $imdbId');
      }
    } catch (e) {
      _logger.warning('Error pre-caching movie detail $imdbId: $e');
      rethrow;
    }
  }
}
