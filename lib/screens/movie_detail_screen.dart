import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../models/bookmark_model.dart';
import '../providers/movie_detail_provider.dart';
import '../providers/bookmark_provider.dart';
import '../config/app_theme.dart';
import '../widgets/loading_widgets.dart' as loading_widgets;

class MovieDetailScreen extends StatefulWidget {
  final String imdbId;
  final Movie? movie;
  final Bookmark? bookmark;
  final String userId;

  const MovieDetailScreen({
    super.key,
    required this.imdbId,
    this.movie,
    this.bookmark,
    required this.userId,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieDetailProvider = Provider.of<MovieDetailProvider>(
        context,
        listen: false,
      );
      final bookmarkProvider = Provider.of<BookmarkProvider>(
        context,
        listen: false,
      );

      // Determine which bookmark to use for offline support
      Bookmark? bookmarkToUse = widget.bookmark;

      // If no bookmark was passed in, try to find one for this movie
      if (bookmarkToUse == null) {
        final userBookmarks = bookmarkProvider.bookmarks
            .where((b) => b.userId == widget.userId)
            .toList();
        // Find bookmark for this movie
        try {
          bookmarkToUse = userBookmarks.firstWhere(
            (b) => b.movieImdbId == widget.imdbId,
          );
        } catch (e) {
          // No bookmark found for this movie
          bookmarkToUse = null;
        }
      }

      // If we have bookmark data with movie details, load from bookmark (for offline support)
      if (bookmarkToUse != null && bookmarkToUse.movieYear != null) {
        movieDetailProvider.loadMovieDetailFromBookmark(
          title: bookmarkToUse.movieTitle,
          year: bookmarkToUse.movieYear ?? '',
          imdbId: widget.imdbId,
          rated: bookmarkToUse.movieRated,
          released: bookmarkToUse.movieReleased,
          runtime: bookmarkToUse.movieRuntime,
          genre: bookmarkToUse.movieGenre,
          director: bookmarkToUse.movieDirector,
          actors: bookmarkToUse.movieActors,
          plot: bookmarkToUse.moviePlot,
          poster: bookmarkToUse.moviePoster,
          imdbRating: bookmarkToUse.imdbRating,
        );
      } else {
        // If no bookmark, try to load from cache first
        movieDetailProvider.loadFromCacheIfAvailable(imdbId: widget.imdbId);
      }

      // Fetch updated movie details from API
      movieDetailProvider.fetchMovieDetail(imdbId: widget.imdbId);

      // Load user's bookmarks to ensure bookmark state is available
      bookmarkProvider.loadUserBookmarks(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Details'), elevation: 0),
      body: Consumer<MovieDetailProvider>(
        builder: (context, movieDetailProvider, _) {
          if (movieDetailProvider.isLoading) {
            return const loading_widgets.LoadingWidget(
              message: 'Loading movie details...',
            );
          }

          // Show error only if no movie detail is available
          if (movieDetailProvider.movieDetail == null) {
            return loading_widgets.ErrorWidget(
              message:
                  movieDetailProvider.error ?? 'Failed to load movie details',
              onRetry: () =>
                  movieDetailProvider.fetchMovieDetail(imdbId: widget.imdbId),
            );
          }

          final movie = movieDetailProvider.movieDetail!;
          final isOfflineData = movieDetailProvider.isOfflineData;

          return Column(
            children: [
              // Show offline indicator at the top
              if (isOfflineData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.orange[700],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          movieDetailProvider.error ?? 'Viewing offline data',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildMovieDetail(context, movie)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovieDetail(BuildContext context, MovieDetail movie) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 400,
                color: Colors.grey[200],
                child: movie.hasPoster
                    ? CachedNetworkImage(
                        imageUrl: movie.poster!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const loading_widgets.LoadingShimmer(),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.movie,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),

              Positioned(
                top: 16,
                right: 16,
                child: BookmarkFloatingButton(
                  userId: widget.userId,
                  movieImdbId: movie.imdbId,
                  movieTitle: movie.title,
                  moviePoster: movie.poster ?? '',
                  movieYear: movie.year,
                  moviePlot: movie.plot,
                  movieDirector: movie.director,
                  movieActors: movie.actors,
                  movieRated: movie.rated,
                  movieRuntime: movie.runtime,
                  movieReleased: movie.released,
                  movieGenre: movie.genre,
                  imdbRating: movie.imdbRating,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.infoColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            movie.imdbRating ?? 'N/A',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        movie.year,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (movie.rated != null && movie.rated != 'N/A')
                  _buildDetailItem(context, 'Rating', movie.rated!, Icons.flag),
                const SizedBox(height: 16),
                if (movie.runtime != null && movie.runtime != 'N/A')
                  _buildDetailItem(
                    context,
                    'Runtime',
                    movie.runtime!,
                    Icons.schedule,
                  ),
                const SizedBox(height: 16),
                if (movie.released != null && movie.released != 'N/A')
                  _buildDetailItem(
                    context,
                    'Release Date',
                    movie.released!,
                    Icons.calendar_today,
                  ),
                const SizedBox(height: 24),

                if (movie.genre != null && movie.genre != 'N/A') ...[
                  Text(
                    'Genre',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: (movie.genre ?? '').split(',').map((genre) {
                      return Chip(
                        label: Text(
                          genre.trim(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                if (movie.director != null && movie.director != 'N/A') ...[
                  _buildDetailSection(context, 'Director', movie.director!),
                  const SizedBox(height: 16),
                ],

                if (movie.actors != null && movie.actors != 'N/A') ...[
                  _buildDetailSection(context, 'Cast', movie.actors!),
                  const SizedBox(height: 16),
                ],

                if (movie.plot != null && movie.plot != 'N/A') ...[
                  Text(
                    'Synopsis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      movie.plot!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class BookmarkFloatingButton extends StatelessWidget {
  final String userId;
  final String movieImdbId;
  final String movieTitle;
  final String moviePoster;
  final String? movieYear;
  final String? moviePlot;
  final String? movieDirector;
  final String? movieActors;
  final String? movieRated;
  final String? movieRuntime;
  final String? movieReleased;
  final String? movieGenre;
  final String? imdbRating;

  const BookmarkFloatingButton({
    super.key,
    required this.userId,
    required this.movieImdbId,
    required this.movieTitle,
    required this.moviePoster,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked = bookmarkProvider.isMovieBookmarked(
          userId,
          movieImdbId,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppTheme.accentColor : Colors.black54,
              size: 28,
            ),
            onPressed: () async {
              if (isBookmarked) {
                final bookmarks = bookmarkProvider.bookmarks
                    .where(
                      (b) => b.userId == userId && b.movieImdbId == movieImdbId,
                    )
                    .toList();
                if (bookmarks.isNotEmpty) {
                  await bookmarkProvider.removeBookmark(
                    userId: userId,
                    bookmarkId: bookmarks.first.id,
                    movieImdbId: movieImdbId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from bookmarks'),
                        duration: Duration(milliseconds: 1500),
                      ),
                    );
                  }
                }
              } else {
                await bookmarkProvider.bookmarkMovie(
                  userId: userId,
                  movieImdbId: movieImdbId,
                  movieTitle: movieTitle,
                  moviePoster: moviePoster,
                  movieYear: movieYear,
                  moviePlot: moviePlot,
                  movieDirector: movieDirector,
                  movieActors: movieActors,
                  movieRated: movieRated,
                  movieRuntime: movieRuntime,
                  movieReleased: movieReleased,
                  movieGenre: movieGenre,
                  imdbRating: imdbRating,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to bookmarks'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}
