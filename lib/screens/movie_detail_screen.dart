import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../models/bookmark_model.dart';
import '../providers/movie_detail_provider.dart';
import '../providers/bookmark_provider.dart';
import '../config/app_theme.dart';
import '../config/ui_components.dart';
import '../widgets/loading_widgets.dart' as lw;

class MovieDetailScreen extends StatefulWidget {
  final String imdbId;
  final Movie? movie;
  final Bookmark? bookmark;
  final String userId;

  const MovieDetailScreen({super.key, required this.imdbId, this.movie, this.bookmark, required this.userId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> with TickerProviderStateMixin {
  late AnimationController _contentAnim;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _contentFade = CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mdp = Provider.of<MovieDetailProvider>(context, listen: false);
      final bk  = Provider.of<BookmarkProvider>(context, listen: false);

      Bookmark? bookmarkToUse = widget.bookmark;
      if (bookmarkToUse == null) {
        try {
          bookmarkToUse = bk.bookmarks.where((b) => b.userId == widget.userId).firstWhere((b) => b.movieImdbId == widget.imdbId);
        } catch (_) { bookmarkToUse = null; }
      }

      if (bookmarkToUse != null && bookmarkToUse.movieYear != null) {
        mdp.loadMovieDetailFromBookmark(
          title: bookmarkToUse.movieTitle, year: bookmarkToUse.movieYear ?? '',
          imdbId: widget.imdbId, rated: bookmarkToUse.movieRated,
          released: bookmarkToUse.movieReleased, runtime: bookmarkToUse.movieRuntime,
          genre: bookmarkToUse.movieGenre, director: bookmarkToUse.movieDirector,
          actors: bookmarkToUse.movieActors, plot: bookmarkToUse.moviePlot,
          poster: bookmarkToUse.moviePoster, imdbRating: bookmarkToUse.imdbRating,
        );
      } else {
        mdp.loadFromCacheIfAvailable(imdbId: widget.imdbId);
      }

      mdp.fetchMovieDetail(imdbId: widget.imdbId);
      bk.loadUserBookmarks(widget.userId);
      _contentAnim.forward();
    });
  }

  @override
  void dispose() { _contentAnim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBlack,
      body: Consumer<MovieDetailProvider>(
        builder: (_, mdp, __) {
          if (mdp.isLoading && mdp.movieDetail == null) {
            return const Center(child: lw.LoadingWidget(message: 'Loading film details...'));
          }
          if (mdp.movieDetail == null) {
            return lw.ErrorWidget(message: mdp.error ?? 'Failed to load film details', onRetry: () => mdp.fetchMovieDetail(imdbId: widget.imdbId));
          }

          return FadeTransition(
            opacity: _contentFade,
            child: Stack(
              children: [
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: AppTheme.pageGradient))),
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(context, mdp.movieDetail!, mdp.isOfflineData),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          if (mdp.isOfflineData) _buildOfflineBanner(mdp.error),
                          _buildContent(context, mdp.movieDetail!),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, MovieDetail movie, bool isOffline) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      backgroundColor: AppTheme.inkBlack,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: FilmBackButton(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            movie.hasPoster
                ? CachedNetworkImage(
                    imageUrl: movie.poster!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const lw.LoadingShimmer(height: 380),
                    errorWidget: (_, __, ___) => _posterPlaceholder(),
                  )
                : _posterPlaceholder(),
            // Gradient fade to black
            Container(
              decoration: BoxDecoration(gradient: AppTheme.posterGradient),
            ),
            // IMDB score overlay
            if (movie.imdbRating != null && movie.imdbRating != 'N/A')
              Positioned(
                bottom: 16, left: 16,
                child: _buildRatingChip(movie.imdbRating!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: AppTheme.graphite,
      child: const Center(child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 56)),
    );
  }

  Widget _buildRatingChip(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inkBlack.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 0.5),
        boxShadow: AppTheme.goldGlow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.gold, size: 15),
          const SizedBox(width: 5),
          Text('$rating / 10', style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.gold)),
          const SizedBox(width: 6),
          const Text('IMDB', style: TextStyle(fontFamily: 'DMSans', fontSize: 9, color: AppTheme.goldDim, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(String? error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.amber.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: AppTheme.amber.withOpacity(0.2), width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(error ?? 'Viewing cached data', style: const TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.amber, letterSpacing: 0.3))),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovieDetail movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(movie.title, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.cream, letterSpacing: -0.5, height: 1.1)),
          const SizedBox(height: 10),

          // Badges
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (movie.year.isNotEmpty) FilmBadge(label: movie.year, color: AppTheme.gold, icon: Icons.calendar_today_rounded),
              if (movie.rated != null && movie.rated != 'N/A') FilmBadge(label: movie.rated!, color: AppTheme.crimsonSoft),
              if (movie.runtime != null && movie.runtime != 'N/A') FilmBadge(label: movie.runtime!, color: AppTheme.ashGray, icon: Icons.schedule_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const GoldDivider(),
          const SizedBox(height: 20),

          // Meta grid
          _buildMetaGrid(movie),
          const SizedBox(height: 24),

          // Genre
          if (movie.genre != null && movie.genre != 'N/A') ...[
            const SectionHeader(title: 'Genres', icon: Icons.theater_comedy_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: (movie.genre ?? '').split(',').map((g) => _genreChip(g.trim())).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Director
          if (movie.director != null && movie.director != 'N/A') ...[
            _buildTextSection('Director', movie.director!, Icons.camera_alt_rounded),
            const SizedBox(height: 16),
          ],

          // Cast
          if (movie.actors != null && movie.actors != 'N/A') ...[
            _buildTextSection('Cast', movie.actors!, Icons.people_outline_rounded),
            const SizedBox(height: 16),
          ],

          // Synopsis
          if (movie.plot != null && movie.plot != 'N/A') ...[
            const GoldDivider(label: 'SYNOPSIS'),
            const SizedBox(height: 14),
            EditorialCard(
              padding: const EdgeInsets.all(18),
              borderColor: AppTheme.gold.withOpacity(0.15),
              child: Text(movie.plot!, style: const TextStyle(fontFamily: 'DMSans', fontSize: 14, color: AppTheme.canvas, height: 1.7)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaGrid(MovieDetail movie) {
    final items = <(String, String, IconData, Color)>[];
    if (movie.imdbRating != null && movie.imdbRating != 'N/A') items.add(('IMDB', movie.imdbRating!, Icons.star_rounded, AppTheme.gold));
    if (movie.rated != null && movie.rated != 'N/A') items.add(('RATING', movie.rated!, Icons.flag_rounded, AppTheme.crimsonSoft));
    if (movie.runtime != null && movie.runtime != 'N/A') items.add(('RUNTIME', movie.runtime!, Icons.timer_rounded, AppTheme.jade));
    if (movie.released != null && movie.released != 'N/A') items.add(('RELEASED', movie.released!, Icons.event_rounded, AppTheme.goldLight));

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
      childAspectRatio: 2.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => EditorialCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: item.$4.withOpacity(0.12), borderRadius: BorderRadius.circular(7)), child: Icon(item.$3, color: item.$4, size: 13)),
            const SizedBox(width: 9),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.$1, style: const TextStyle(fontFamily: 'DMSans', fontSize: 8, color: AppTheme.ashGray, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text(item.$2, style: const TextStyle(fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.cream), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          ],
        ),
      )).toList(),
    );
  }

  Widget _genreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.goldDim.withOpacity(0.3), width: 0.5),
      ),
      child: Text(label, style: const TextStyle(fontFamily: 'DMSans', fontSize: 12, color: AppTheme.canvas)),
    );
  }

  Widget _buildTextSection(String title, String content, IconData icon) {
    return EditorialCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.gold, size: 13),
            const SizedBox(width: 7),
            Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'DMSans', fontSize: 9, color: AppTheme.ashGray, letterSpacing: 2, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Container(height: 0.5, color: AppTheme.warmGray.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.cream, height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKMARK FLOATING BUTTON
// ─────────────────────────────────────────────
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
    super.key, required this.userId, required this.movieImdbId, required this.movieTitle, required this.moviePoster,
    this.movieYear, this.moviePlot, this.movieDirector, this.movieActors, this.movieRated, this.movieRuntime,
    this.movieReleased, this.movieGenre, this.imdbRating,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkProvider>(
      builder: (_, bk, __) {
        final saved = bk.isMovieBookmarked(movieImdbId);
        return GestureDetector(
          onTap: () async {
            if (saved) {
              final list = bk.bookmarks.where((b) => b.movieImdbId == movieImdbId).toList();
              if (list.isNotEmpty) {
                await bk.removeBookmark(userId: userId, bookmarkId: list.first.id, movieImdbId: movieImdbId);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from collection'), duration: Duration(milliseconds: 1500)));
              }
            } else {
              await bk.bookmarkMovie(userId: userId, movieImdbId: movieImdbId, movieTitle: movieTitle, moviePoster: moviePoster, movieYear: movieYear, moviePlot: moviePlot, movieDirector: movieDirector, movieActors: movieActors, movieRated: movieRated, movieRuntime: movieRuntime, movieReleased: movieReleased, movieGenre: movieGenre, imdbRating: imdbRating);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to collection'), duration: Duration(milliseconds: 1500)));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: saved ? AppTheme.crimson.withOpacity(0.9) : AppTheme.charcoal.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: saved ? AppTheme.crimson : AppTheme.warmGray.withOpacity(0.5), width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
            ),
            child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: AppTheme.cream, size: 20),
          ),
        );
      },
    );
  }
}
