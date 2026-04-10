class Bookmark {
  final String id;
  final String userId;
  final String movieImdbId;
  final String movieTitle;
  final String moviePoster;
  final DateTime createdAt;
  final bool isSynced;


  final String? movieYear;
  final String? moviePlot;
  final String? movieDirector;
  final String? movieActors;
  final String? movieRated;
  final String? movieRuntime;
  final String? movieReleased;
  final String? movieGenre;
  final String? imdbRating;

  Bookmark({
    required this.id,
    required this.userId,
    required this.movieImdbId,
    required this.movieTitle,
    required this.moviePoster,
    required this.createdAt,
    this.isSynced = false,
    this.movieYear,
    this.moviePlot,
    this.movieDirector,
    this.movieActors,
    this.movieRated,
    this.movieRuntime,
    this.movieReleased,
    this.movieGenre,
    this.imdbRating,
  });

  Bookmark copyWith({
    String? id,
    String? userId,
    String? movieImdbId,
    String? movieTitle,
    String? moviePoster,
    DateTime? createdAt,
    bool? isSynced,
    String? movieYear,
    String? moviePlot,
    String? movieDirector,
    String? movieActors,
    String? movieRated,
    String? movieRuntime,
    String? movieReleased,
    String? movieGenre,
    String? imdbRating,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      movieImdbId: movieImdbId ?? this.movieImdbId,
      movieTitle: movieTitle ?? this.movieTitle,
      moviePoster: moviePoster ?? this.moviePoster,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      movieYear: movieYear ?? this.movieYear,
      moviePlot: moviePlot ?? this.moviePlot,
      movieDirector: movieDirector ?? this.movieDirector,
      movieActors: movieActors ?? this.movieActors,
      movieRated: movieRated ?? this.movieRated,
      movieRuntime: movieRuntime ?? this.movieRuntime,
      movieReleased: movieReleased ?? this.movieReleased,
      movieGenre: movieGenre ?? this.movieGenre,
      imdbRating: imdbRating ?? this.imdbRating,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'movieImdbId': movieImdbId,
    'movieTitle': movieTitle,
    'moviePoster': moviePoster,
    'createdAt': createdAt.toIso8601String(),
    'isSynced': isSynced ? 1 : 0,
    'movieYear': movieYear,
    'moviePlot': moviePlot,
    'movieDirector': movieDirector,
    'movieActors': movieActors,
    'movieRated': movieRated,
    'movieRuntime': movieRuntime,
    'movieReleased': movieReleased,
    'movieGenre': movieGenre,
    'imdbRating': imdbRating,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'] as String,
    userId: json['userId'] as String,
    movieImdbId: json['movieImdbId'] as String,
    movieTitle: json['movieTitle'] as String,
    moviePoster: json['moviePoster'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isSynced: (json['isSynced'] as int?) == 1,
    movieYear: json['movieYear'] as String?,
    moviePlot: json['moviePlot'] as String?,
    movieDirector: json['movieDirector'] as String?,
    movieActors: json['movieActors'] as String?,
    movieRated: json['movieRated'] as String?,
    movieRuntime: json['movieRuntime'] as String?,
    movieReleased: json['movieReleased'] as String?,
    movieGenre: json['movieGenre'] as String?,
    imdbRating: json['imdbRating'] as String?,
  );
}

class LocalUser {
  final String id;
  final String name;
  final String job;
  final DateTime createdAt;
  final bool isSynced;
  final String? apiId;

  LocalUser({
    required this.id,
    required this.name,
    required this.job,
    required this.createdAt,
    this.isSynced = false,
    this.apiId,
  });

  LocalUser copyWith({
    String? id,
    String? name,
    String? job,
    DateTime? createdAt,
    bool? isSynced,
    String? apiId,
  }) {
    return LocalUser(
      id: id ?? this.id,
      name: name ?? this.name,
      job: job ?? this.job,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      apiId: apiId ?? this.apiId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'job': job,
    'createdAt': createdAt.toIso8601String(),
    'isSynced': isSynced ? 1 : 0,
    'apiId': apiId,
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    id: json['id'] as String,
    name: json['name'] as String,
    job: json['job'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isSynced: (json['isSynced'] as int?) == 1,
    apiId: json['apiId'] as String?,
  );
}
