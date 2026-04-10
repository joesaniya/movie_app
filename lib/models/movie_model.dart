class Movie {
  final String title;
  final String year;
  final String imdbId;
  final String type;
  final String poster;
  final String? plot;
  final String? director;
  final String? actors;
  final String? rated;
  final String? runtime;
  final String? releaseDate;

  Movie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.type,
    required this.poster,
    this.plot,
    this.director,
    this.actors,
    this.rated,
    this.runtime,
    this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    title: json['Title'] as String? ?? '',
    year: json['Year'] as String? ?? '',
    imdbId: json['imdbID'] as String? ?? '',
    type: json['Type'] as String? ?? 'movie',
    poster: json['Poster'] as String? ?? '',
    plot: json['Plot'] as String?,
    director: json['Director'] as String?,
    actors: json['Actors'] as String?,
    rated: json['Rated'] as String?,
    runtime: json['Runtime'] as String?,
    releaseDate: json['Released'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Title': title,
    'Year': year,
    'imdbID': imdbId,
    'Type': type,
    'Poster': poster,
    'Plot': plot,
    'Director': director,
    'Actors': actors,
    'Rated': rated,
    'Runtime': runtime,
    'Released': releaseDate,
  };

  bool get hasPoster => poster != null && poster != 'N/A' && poster!.isNotEmpty;
}

class MovieSearchResponse {
  final List<Movie>? movies;
  final String? totalResults;
  final String response;
  final String? error;

  MovieSearchResponse({
    this.movies,
    this.totalResults,
    required this.response,
    this.error,
  });

  factory MovieSearchResponse.fromJson(Map<String, dynamic> json) {
    List<Movie>? movies;
    if (json['Search'] != null && json['Search'] is List) {
      movies = (json['Search'] as List)
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return MovieSearchResponse(
      movies: movies,
      totalResults: json['totalResults'] as String?,
      response: json['Response'] as String? ?? 'False',
      error: json['Error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'Search': movies?.map((e) => e.toJson()).toList(),
    'totalResults': totalResults,
    'Response': response,
    'Error': error,
  };

  bool get isSuccess => response == 'True' && movies != null;
  int get total => int.tryParse(totalResults ?? '0') ?? 0;
}

class MovieDetail {
  final String title;
  final String year;
  final String? rated;
  final String? released;
  final String? runtime;
  final String? genre;
  final String? director;
  final String? actors;
  final String? plot;
  final String? poster;
  final String imdbId;
  final String? imdbRating;
  final String response;

  MovieDetail({
    required this.title,
    required this.year,
    this.rated,
    this.released,
    this.runtime,
    this.genre,
    this.director,
    this.actors,
    this.plot,
    this.poster,
    required this.imdbId,
    this.imdbRating,
    required this.response,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) => MovieDetail(
    title: json['Title'] as String? ?? '',
    year: json['Year'] as String? ?? '',
    rated: json['Rated'] as String?,
    released: json['Released'] as String?,
    runtime: json['Runtime'] as String?,
    genre: json['Genre'] as String?,
    director: json['Director'] as String?,
    actors: json['Actors'] as String?,
    plot: json['Plot'] as String?,
    poster: json['Poster'] as String?,
    imdbId: json['imdbID'] as String? ?? '',
    imdbRating: json['imdbRating'] as String?,
    response: json['Response'] as String? ?? 'False',
  );

  Map<String, dynamic> toJson() => {
    'Title': title,
    'Year': year,
    'Rated': rated,
    'Released': released,
    'Runtime': runtime,
    'Genre': genre,
    'Director': director,
    'Actors': actors,
    'Plot': plot,
    'Poster': poster,
    'imdbID': imdbId,
    'imdbRating': imdbRating,
    'Response': response,
  };

  bool get hasPoster => poster != null && poster != 'N/A' && poster!.isNotEmpty;
}
