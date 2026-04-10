import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../models/user_model.dart';
import '../models/movie_model.dart';
import 'network_interceptor.dart';

final _logger = Logger('ApiService');

class ApiService {
  static const String baseUrlUsers = 'https://reqres.in/api';
  static const String baseUrlMovies = 'https://www.omdbapi.com';
  static const String movieApiKey = 'eac7cc99';
  static const String reqresApiKey = 'reqres_e76eb59af1234a00ae6db056b038d1e1';

  late final Dio _dioUsers;
  late final Dio _dioMovies;

  ApiService() {
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

  // User API calls
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
    } catch (e) {
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
      return MovieDetail.fromJson(response.data);
    } catch (e) {
      _logger.severe('Error fetching movie detail: $e');
      rethrow;
    }
  }

  Future<MovieSearchResponse> getTrendingMovies({int page = 1}) async {
   
    return searchMovies(query: 'popular', page: page);
  }
}
