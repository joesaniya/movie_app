import 'dart:developer';

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
import 'bookmarks_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final moviesProvider = Provider.of<PaginatedMoviesProvider>(
        context,
        listen: false,
      );
      final bookmarkProvider = Provider.of<BookmarkProvider>(
        context,
        listen: false,
      );

      await moviesProvider.getTrendingMovies();
      await bookmarkProvider.loadUserBookmarks(widget.userId);
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

  void _performSearch(String? query) {
    final finalQuery = (query ?? _searchController.text).trim();
    log('Performing search with query: $finalQuery');

    if (finalQuery.isEmpty) {
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
      ).searchMovies(query: finalQuery, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movies', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'for ${widget.userName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Tooltip(
                message: 'View Bookmarks',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.bookmark, color: AppTheme.accentColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarksScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});

                  _performSearch(value);
                },
                onSubmitted: (value) {
                  _performSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search movies...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _performSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
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

class MovieCard extends StatefulWidget {
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
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 220,
                        color: Colors.grey[200],
                        child: widget.movie.hasPoster
                            ? CachedNetworkImage(
                                imageUrl: widget.movie.poster,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const loading_widgets.LoadingShimmer(),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
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

                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.movie.type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.movie.year,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_movies,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.movie.imdbId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            BookmarkButton(
                              userId: widget.userId,
                              movieImdbId: widget.movie.imdbId,
                              movieTitle: widget.movie.title,
                              moviePoster: widget.movie.poster,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        final isBookmarked = bookmarkProvider.isMovieBookmarked(movieImdbId);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isBookmarked
                ? AppTheme.accentColor.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTap: () async {
              if (isBookmarked) {
                final bookmarks = bookmarkProvider.bookmarks
                    .where((b) => b.movieImdbId == movieImdbId)
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
                        duration: Duration(seconds: 1),
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
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to bookmarks'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: isBookmarked
                      ? AppTheme.accentColor
                      : Colors.grey.shade600,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isBookmarked ? 'Bookmarked' : 'Bookmark',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isBookmarked
                        ? AppTheme.accentColor
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
