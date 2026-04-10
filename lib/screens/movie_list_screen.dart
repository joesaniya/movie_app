import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../providers/movie_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/connectivity_provider.dart';
import '../config/app_theme.dart';
import '../config/ui_components.dart';
import '../widgets/loading_widgets.dart' as lw;
import '../utils/animation_helper.dart';
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

class _MovieListScreenState extends State<MovieListScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  bool _isSearching = false;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _headerAnim = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mp = Provider.of<PaginatedMoviesProvider>(context, listen: false);
      final bk = Provider.of<BookmarkProvider>(context, listen: false);
      await mp.getTrendingMovies();
      await bk.loadUserBookmarks(widget.userId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    final mp = Provider.of<PaginatedMoviesProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        mp.hasMore &&
        !mp.isLoading) {
      if (_isSearching && _searchController.text.isNotEmpty) {
        mp.searchMovies(query: _searchController.text);
      } else {
        mp.getTrendingMovies();
      }
    }
  }

  void _performSearch(String? query) {
    final q = (query ?? _searchController.text).trim();
    log('Search: $q');
    if (q.isEmpty) {
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
      ).searchMovies(query: q, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Consumer<ConnectivityProvider>(
                  builder: (_, conn, __) => !conn.isOnline
                      ? const lw.NoInternetWidget()
                      : const SizedBox.shrink(),
                ),
                FadeTransition(opacity: _headerFade, child: _buildHeader()),
                _buildSearchBar(),
                const SizedBox(height: 4),
                Expanded(
                  child: Consumer<PaginatedMoviesProvider>(
                    builder: (_, mp, __) {
                      if (mp.movies.isEmpty && mp.isLoading)
                        return const lw.LoadingWidget(
                          message: 'Fetching films...',
                        );
                      if (mp.movies.isEmpty && mp.error != null)
                        return lw.ErrorWidget(
                          message: mp.error!,
                          onRetry: () => _performSearch(_searchController.text),
                        );
                      if (mp.movies.isEmpty)
                        return const lw.EmptyWidget(
                          title: 'No Films Found',
                          message: 'Try a different search term.',
                          icon: Icons.movie_outlined,
                        );
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: mp.movies.length + (mp.hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == mp.movies.length)
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: lw.LoadingWidget(isSmall: true),
                            );
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 200 + (i % 8) * 40,
                            ),
                            curve: Curves.easeOut,
                            builder: (_, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - v)),
                                child: child,
                              ),
                            ),
                            child: MovieCard(
                              movie: mp.movies[i],
                              userId: widget.userId,
                              onTap: () => Navigator.push(
                                context,
                                AnimatedPageRoute(
                                  builder: (_) => MovieDetailScreen(
                                    imdbId: mp.movies[i].imdbId,
                                    movie: mp.movies[i],
                                    userId: widget.userId,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          FilmBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The Collection',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.cream,
                  ),
                ),
                Text(
                  'curated for ${widget.userName}',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: AppTheme.dustGray,
                  ),
                ),
              ],
            ),
          ),
         
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              AnimatedPageRoute(builder: (_) => const BookmarksScreen()),
            ),
            child: Consumer<BookmarkProvider>(
              builder: (_, bk, __) {
                final count = bk.bookmarks.length;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.crimson.withOpacity(0.35),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_rounded,
                        color: AppTheme.crimsonSoft,
                        size: 16,
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.crimsonSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Focus(
        onFocusChange: (v) => setState(() => _searchFocused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.graphite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _searchFocused
                  ? AppTheme.gold.withOpacity(0.6)
                  : AppTheme.warmGray.withOpacity(0.4),
              width: _searchFocused ? 1 : 0.5,
            ),
            boxShadow: _searchFocused ? AppTheme.goldGlow : null,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              setState(() {});
              _performSearch(v);
            },
            onSubmitted: _performSearch,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: AppTheme.cream,
            ),
            decoration: InputDecoration(
              hintText: 'Search films & series...',
              hintStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: AppTheme.dustGray,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _searchFocused ? AppTheme.gold : AppTheme.dustGray,
                size: 18,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.dustGray,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _performSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
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
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      duration: const Duration(milliseconds: 130),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _tapCtrl.forward(),
        onTapUp: (_) {
          _tapCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _tapCtrl.reverse(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.warmGray.withOpacity(0.35),
              width: 0.5,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
             
              _buildPoster(),
             
              Expanded(child: _buildInfo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppTheme.radiusLg),
        bottomLeft: Radius.circular(AppTheme.radiusLg),
      ),
      child: SizedBox(
        width: 88,
        height: 124,
        child: widget.movie.hasPoster
            ? CachedNetworkImage(
                imageUrl: widget.movie.poster,
                fit: BoxFit.cover,
                placeholder: (_, __) => const lw.LoadingShimmer(height: 124),
                errorWidget: (_, __, ___) => _posterPlaceholder(),
              )
            : _posterPlaceholder(),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: AppTheme.graphite,
      child: const Center(
        child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 30),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilmBadge(label: widget.movie.type, color: AppTheme.gold),
              const SizedBox(width: 6),
              Text(
                widget.movie.year,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  color: AppTheme.dustGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.movie.title,
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.cream,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.movie.imdbId,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: AppTheme.dustGray,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.25),
                      width: 0.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'DETAILS',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
      builder: (_, bk, __) {
        final saved = bk.isMovieBookmarked(movieImdbId);
        return GestureDetector(
          onTap: () async {
            if (saved) {
              final list = bk.bookmarks
                  .where((b) => b.movieImdbId == movieImdbId)
                  .toList();
              if (list.isNotEmpty) {
                await bk.removeBookmark(
                  userId: userId,
                  bookmarkId: list.first.id,
                  movieImdbId: movieImdbId,
                );
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from collection'),
                      duration: Duration(seconds: 1),
                    ),
                  );
              }
            } else {
              await bk.bookmarkMovie(
                userId: userId,
                movieImdbId: movieImdbId,
                movieTitle: movieTitle,
                moviePoster: moviePoster,
              );
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to collection'),
                    duration: Duration(seconds: 1),
                  ),
                );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: saved
                  ? AppTheme.crimson.withOpacity(0.15)
                  : AppTheme.warmGray.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: saved
                    ? AppTheme.crimson.withOpacity(0.4)
                    : AppTheme.warmGray.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: saved ? AppTheme.crimsonSoft : AppTheme.ashGray,
              size: 16,
            ),
          ),
        );
      },
    );
  }
}
