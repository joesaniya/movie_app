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

  /// Create user with simple name and job fields (Reqres API format)
  /// POST https://reqres.in/api/users
  /// Request: {"name": "morpheus", "job": "leader"}
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

  /// Create user with full details (legacy method)
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
      final isNetworkError =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError ||
          e.message?.contains('No internet') == true;

      final statusCode = e.response?.statusCode;
      final isApiError = statusCode == 401 || statusCode == 429;
      final isServerError = statusCode != null && statusCode >= 500;

      if (isNetworkError || isApiError || isServerError) {
        _logger.warning(
          'Network/API error searching movies (${e.type}), using fallback data: $query',
        );
        return _getMockMovieSearchResponse(query, page);
      }

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
    } on DioException catch (e) {
      final isNetworkError =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError ||
          e.message?.contains('No internet') == true;

      final statusCode = e.response?.statusCode;
      final isApiError = statusCode == 401 || statusCode == 429;
      final isServerError = statusCode != null && statusCode >= 500;

      if (isNetworkError || isApiError || isServerError) {
        _logger.warning(
          'Network/API error fetching movie detail (${e.type}), using fallback data: $imdbId',
        );
        return _getMockMovieDetail(imdbId);
      }

      _logger.severe('Error fetching movie detail: $e');
      rethrow;
    }
  }

  Future<MovieSearchResponse> getTrendingMovies({int page = 1}) async {
    return searchMovies(query: 'popular', page: page);
  }

  MovieSearchResponse _getMockMovieSearchResponse(String query, int page) {
    final mockMovies = [
      // Drama movies
      Movie(
        title: 'The Shawshank Redemption',
        year: '1994',
        imdbId: 'tt0111161',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMDFlYTAwYTItYTU0OC00ZDlhLWEyNWYtMTA5ZWFkZGNmNzE1XkEyXkFqcGdeQXVyMTAwMzUyNjc2._V1_SX300.jpg',
        plot:
            'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency. A powerful drama about hope and friendship.',
      ),
      Movie(
        title: 'Forrest Gump',
        year: '1994',
        imdbId: 'tt0109830',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BNWIwODRlZTUtY2U3ZS00Yzg1LWJhNzYtMmZiYmEyNmU1NjVmXkEyXkFqcGdeQXVyMTQxNzMzNDI@._V1_SX300.jpg',
        plot:
            'The presidencies of Kennedy and Johnson unfold from the perspective of an Alabama man with an IQ of 75. An inspiring drama about life.',
      ),
      // Action/Crime movies
      Movie(
        title: 'The Dark Knight',
        year: '2008',
        imdbId: 'tt0468569',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZWcwODg0MTE4MQ@@._V1_SX300.jpg',
        plot:
            'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests. An action-packed crime thriller.',
      ),
      Movie(
        title: 'Pulp Fiction',
        year: '1994',
        imdbId: 'tt0110912',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BNGNhMDIzZTUtNTBlZi00MTRlLWFjM2ItMDJkYzdhYzMzODcyXkEyXkFqcGdeQXVyNzkwMjQ5NzM@._V1_SX300.jpg',
        plot:
            'The lives of two mob hitmen, a boxer, a gangster and his wife intertwine in four tales of violence and redemption. A crime thriller masterpiece.',
      ),
      // Sci-Fi movies
      Movie(
        title: 'Inception',
        year: '2010',
        imdbId: 'tt1375666',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMjAxMzc5ZDctNDg2OC00MGE3LWFhZmUtNzc5YzVjMDAwMDAyXkEyXkFqcGdeQXVyNDUy5DA12Mw._V1_SX300.jpg',
        plot:
            'A skilled thief who steals corporate secrets through the use of dream-sharing technology. A mind-bending science fiction thriller.',
      ),
      Movie(
        title: 'Interstellar',
        year: '2014',
        imdbId: 'tt0816692',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BZjdkOTU3MDktN2IxOS00OGEyLWFmMjktY2FiMGZkNWIyODZiXkEyXkFqcGdeQXVyMzQ0MjM5NjU@._V1_SX300.jpg',
        plot:
            'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival. Epic science fiction adventure.',
      ),
      // Horror movies
      Movie(
        title: 'The Conjuring',
        year: '2013',
        imdbId: 'tt1457767',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMTM0MDcyNDMwMl5BMl5BanBnXkFtZWcwNzc3ODk3MQ@@._V1_SX300.jpg',
        plot:
            'Paranormal investigators work to help a family terrorized by a dark presence in their home. A terrifying horror film.',
      ),
      Movie(
        title: 'The Ring',
        year: '2002',
        imdbId: 'tt0298933',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMTI1NDMxMDA2NF5BMl5BanBnXkFtZWcwNzI5ODQ3MQ@@._V1_SX300.jpg',
        plot:
            'A journalist uncovers a deadly videotape that kills everyone who watches it within seven days. A chilling horror movie.',
      ),
      Movie(
        title: 'Insidious',
        year: '2010',
        imdbId: 'tt1591095',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BNDY5ZTQwNDMtNzAxNS00YjY1LTkyNDYtNmQyNzU0MTM1ODMzXkEyXkFqcGdeQXVyMjUzOTY1NTc@._V1_SX300.jpg',
        plot:
            'A family fights to save their son from a supernatural realm called The Further. A scary horror film filled with supernatural terror.',
      ),
      // Thriller movies
      Movie(
        title: 'Gone Girl',
        year: '2014',
        imdbId: 'tt2488496',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMTk0MDQ3MzAzOV5BMl5BanBnXkFtZWcwMzY0Nzc0MjE@._V1_SX300.jpg',
        plot:
            'With his wife\'s disappearance having become the focus of an intense media circus, a man reveals secrets and lies. A psychological thriller.',
      ),
      Movie(
        title: 'se7en',
        year: '1995',
        imdbId: 'tt0114369',
        type: 'movie',
        poster:
            'https://m.media-amazon.com/images/M/MV5BOTUwODM5N2YtY2IyMC00MzQ0LWI2YjItNjZiYzA1MTI2OTAxXkEyXkFqcGdeQXVyNjU0OTQ0ODA@._V1_SX300.jpg',
        plot:
            'Two detectives hunt a serial killer who uses the victims to represent the seven deadly sins. A dark thriller masterpiece.',
      ),
    ];

    // Filter by query - checks title and plot for keyword matches
    List<Movie> filteredMovies = mockMovies;
    if (query != 'popular') {
      final queryLower = query.toLowerCase();
      filteredMovies = mockMovies
          .where(
            (movie) =>
                movie.title.toLowerCase().contains(queryLower) ||
                (movie.plot?.toLowerCase().contains(queryLower) ?? false),
          )
          .toList();
    }

    // Pagination: 6 movies per page
    final startIndex = (page - 1) * 6;
    final endIndex = startIndex + 6;

    if (startIndex >= filteredMovies.length && filteredMovies.isNotEmpty) {
      // Return empty result for pages beyond available data
      return MovieSearchResponse(
        movies: [],
        totalResults: filteredMovies.length.toString(),
        response: 'True',
      );
    }

    final paginatedMovies = filteredMovies.sublist(
      startIndex,
      endIndex > filteredMovies.length ? filteredMovies.length : endIndex,
    );

    return MovieSearchResponse(
      movies: paginatedMovies.isNotEmpty ? paginatedMovies : [],
      totalResults: filteredMovies.length.toString(),
      response: 'True',
      error: filteredMovies.isEmpty
          ? 'No movies found matching "$query"'
          : null,
    );
  }

  MovieDetail _getMockMovieDetail(String imdbId) {
    final mockDetailsMap = {
      'tt0111161': MovieDetail(
        title: 'The Shawshank Redemption',
        year: '1994',
        rated: 'R',
        released: '14 Oct 1994',
        runtime: '142 min',
        genre: 'Drama',
        director: 'Frank Darabont',
        actors: 'Tim Robbins, Morgan Freeman, Bob Gunton',
        plot:
            'Two imprisoned men bond over a number of years, finding solace and eventual redemption through acts of common decency.',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMDFlYTAwYTItYTU0OC00ZDlhLWEyNWYtMTA5ZWFkZGNmNzE1XkEyXkFqcGdeQXVyMTAwMzUyNjc2._V1_SX300.jpg',
        imdbId: 'tt0111161',
        imdbRating: '9.3',
        response: 'True',
      ),
      'tt0468569': MovieDetail(
        title: 'The Dark Knight',
        year: '2008',
        rated: 'PG-13',
        released: '18 Jul 2008',
        runtime: '152 min',
        genre: 'Action, Crime, Drama',
        director: 'Christopher Nolan',
        actors: 'Christian Bale, Heath Ledger, Aaron Eckhart',
        plot:
            'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman must accept one of the greatest psychological and physical tests of his ability to fight injustice.',
        poster:
            'https://m.media-amazon.com/images/M/MV5BMTMxNTMwODM0NF5BMl5BanBnXkFtZWcwODg0MTE4MQ@@._V1_SX300.jpg',
        imdbId: 'tt0468569',
        imdbRating: '9.0',
        response: 'True',
      ),
    };

    return mockDetailsMap[imdbId] ??
        MovieDetail(
          title: 'Movie Not Found',
          year: '2024',
          imdbId: imdbId,
          response: 'False',
        );
  }
}
