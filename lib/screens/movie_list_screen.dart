import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../providers/movie_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/connectivity_provider.dart';
import '../config/app_theme.dart';
import '../widgets/loading_widgets.dart' as loading_widgets;
import 'movie_detail_screen.dart';

class MovieListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const MovieListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moviesProvider = Provider.of<PaginatedMoviesProvider>(
        context,
        listen: false,
      );
      final bookmarkProvider = Provider.of<BookmarkProvider>(
        context,
        listen: false,
      );

      moviesProvider.getTrendingMovies();
      bookmarkProvider.loadUserBookmarks(widget.userId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final moviesProvider = Provider.of<PaginatedMoviesProvider>(
      context,
      listen: false,
    );

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        moviesProvider.hasMore &&
        !moviesProvider.isLoading) {
      if (_isSearching && _searchController.text.isNotEmpty) {
        moviesProvider.searchMovies(query: _searchController.text);
      } else {
        moviesProvider.getTrendingMovies();
      }
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      Provider.of<PaginatedMoviesProvider>(
        context,
        listen: false,
      ).getTrendingMovies(refresh: true);
    } else {
      setState(() => _isSearching = true);
      Provider.of<PaginatedMoviesProvider>(
        context,
        listen: false,
      ).searchMovies(query: query, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movies'),
            Text(
              'for ${widget.userName}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) {
              return Column(
                children: [
                  if (!connectivity.isOnline)
                    const loading_widgets.NoInternetWidget(),
                ],
              );
            },
          ),
         
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (value.isEmpty) {
                  _performSearch('');
                }
              },
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search movies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
         
          Expanded(
            child: Consumer<PaginatedMoviesProvider>(
              builder: (context, moviesProvider, _) {
                if (moviesProvider.movies.isEmpty && moviesProvider.isLoading) {
                  return const loading_widgets.LoadingWidget(
                    message: 'Loading movies...',
                  );
                }

                if (moviesProvider.movies.isEmpty &&
                    moviesProvider.error != null) {
                  return loading_widgets.ErrorWidget(
                    message: moviesProvider.error!,
                    onRetry: () => _performSearch(_searchController.text),
                  );
                }

                if (moviesProvider.movies.isEmpty) {
                  return loading_widgets.EmptyWidget(
                    title: 'No Movies Found',
                    message: 'Try a different search or browse trending movies',
                    icon: Icons.movie_outlined,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      moviesProvider.movies.length +
                      (moviesProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == moviesProvider.movies.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const loading_widgets.LoadingWidget(
                          isSmall: true,
                        ),
                      );
                    }

                    final movie = moviesProvider.movies[index];
                    return MovieCard(
                      movie: movie,
                      userId: widget.userId,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(
                              imdbId: movie.imdbId,
                              movie: movie,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final Movie movie;
  final String userId;
  final VoidCallback onTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: movie.hasPoster
                    ? CachedNetworkImage(
                        imageUrl: movie.poster,
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
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
           
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Year: ${movie.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                movie.type.toUpperCase(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      BookmarkButton(
                        userId: userId,
                        movieImdbId: movie.imdbId,
                        movieTitle: movie.title,
                        moviePoster: movie.poster,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkButton extends StatelessWidget {
  final String userId;
  final String movieImdbId;
  final String movieTitle;
  final String moviePoster;

  const BookmarkButton({
    super.key,
    required this.userId,
    required this.movieImdbId,
    required this.movieTitle,
    required this.moviePoster,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked = bookmarkProvider.isMovieBookmarked(
          userId,
          movieImdbId,
        );

        return IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? AppTheme.accentColor : Colors.grey,
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
              }
            } else {
              await bookmarkProvider.bookmarkMovie(
                userId: userId,
                movieImdbId: movieImdbId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
              );
            }
          },
        );
      },
    );
  }
}
