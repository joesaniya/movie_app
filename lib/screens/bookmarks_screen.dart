import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark_model.dart';
import '../widgets/loading_widgets.dart' as lw;
import '../config/app_theme.dart';
import '../config/ui_components.dart';
import 'movie_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  bool _gridView = true;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(() => setState(() {}));
    _headerAnim = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().loadAllBookmarks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  List<Bookmark> _filtered(List<Bookmark> bookmarks) {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return bookmarks;
    return bookmarks.where((b) => b.movieTitle.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBlack,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: AppTheme.pageGradient))),
          SafeArea(
            child: Consumer<BookmarkProvider>(
              builder: (_, bk, __) {
                if (bk.isLoading && bk.bookmarks.isEmpty) return const lw.LoadingWidget(message: 'Loading collection...');

                final all = bk.bookmarks;
                final filtered = _filtered(all);

                return Column(
                  children: [
                    // Header
                    FadeTransition(opacity: _headerFade, child: _buildHeader(all.length)),

                    // Search + Toggle
                    _buildSearchAndToggle(),

                    // Count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        children: [
                          Text('${filtered.length} FILMS', style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.ashGray, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('— filtered from ${all.length}', style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.dustGray)),
                          ],
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: all.isEmpty
                          ? const lw.EmptyWidget(
                              icon: Icons.bookmark_outline_rounded,
                              title: 'No Films Saved',
                              message: 'Bookmark films from your collection to build your personal library.',
                            )
                          : filtered.isEmpty
                              ? Center(child: Text('No results for "${_searchController.text}"', style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray)))
                              : _gridView
                                  ? _buildGrid(filtered, bk)
                                  : _buildList(filtered, bk),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          FilmBackButton(),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('My Collection', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.cream)),
              Text('$count saved films', style: const TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.dustGray)),
            ],
          ),
          const Spacer(),
          // View toggle
          Container(
            decoration: BoxDecoration(color: AppTheme.graphite, borderRadius: BorderRadius.circular(AppTheme.radiusSm), border: Border.all(color: AppTheme.warmGray.withOpacity(0.4), width: 0.5)),
            child: Row(
              children: [
                _toggleBtn(Icons.grid_view_rounded, true),
                _toggleBtn(Icons.view_list_rounded, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool isGrid) {
    final active = _gridView == isGrid;
    return GestureDetector(
      onTap: () => setState(() => _gridView = isGrid),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.goldGradient : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm - 1),
        ),
        child: Icon(icon, size: 16, color: active ? AppTheme.inkBlack : AppTheme.ashGray),
      ),
    );
  }

  Widget _buildSearchAndToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Focus(
        onFocusChange: (v) => setState(() => _searchFocused = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.graphite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: _searchFocused ? AppTheme.gold.withOpacity(0.6) : AppTheme.warmGray.withOpacity(0.4), width: _searchFocused ? 1 : 0.5),
            boxShadow: _searchFocused ? AppTheme.goldGlow : null,
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.cream),
            decoration: InputDecoration(
              hintText: 'Search your collection...',
              hintStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.dustGray),
              prefixIcon: Icon(Icons.search_rounded, size: 17, color: _searchFocused ? AppTheme.gold : AppTheme.dustGray),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.dustGray, size: 15), onPressed: _searchController.clear)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Bookmark> bookmarks, BookmarkProvider bk) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 180 + i * 45),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.93 + 0.07 * v, child: child)),
          child: _GridCard(bookmark: bookmarks[i], onRemove: () => _confirmRemove(context, bookmarks[i], bk)),
        );
      },
    );
  }

  Widget _buildList(List<Bookmark> bookmarks, BookmarkProvider bk) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 150 + i * 35),
          curve: Curves.easeOut,
          builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child)),
          child: _ListCard(bookmark: bookmarks[i], onRemove: () => _confirmRemove(context, bookmarks[i], bk)),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, Bookmark bookmark, BookmarkProvider bk) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl), side: const BorderSide(color: AppTheme.warmGray, width: 0.5)),
        title: const Text('Remove from Collection?', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.cream)),
        content: Text('Remove "${bookmark.movieTitle}" from your saved films?', style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep', style: TextStyle(color: AppTheme.ashGray))),
          TextButton(
            onPressed: () {
              bk.removeBookmark(userId: bookmark.userId, bookmarkId: bookmark.id, movieImdbId: bookmark.movieImdbId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${bookmark.movieTitle}" removed'), duration: const Duration(seconds: 2)));
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.crimsonSoft, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GRID CARD
// ─────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onRemove;
  const _GridCard({required this.bookmark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MovieDetailScreen(imdbId: bookmark.movieImdbId, bookmark: bookmark, userId: bookmark.userId),
      )),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.warmGray.withOpacity(0.3), width: 0.5),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppTheme.radiusLg), topRight: Radius.circular(AppTheme.radiusLg)),
                child: bookmark.moviePoster.isNotEmpty && bookmark.moviePoster != 'N/A'
                    ? Image.network(bookmark.moviePoster, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 28)))
                    : const Center(child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 28)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bookmark.movieTitle, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.cream), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 7),
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.crimson.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.crimson.withOpacity(0.3), width: 0.5),
                      ),
                      child: const Center(child: Text('REMOVE', style: TextStyle(fontFamily: 'DMSans', fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.crimsonSoft, letterSpacing: 1))),
                    ),
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

// ─────────────────────────────────────────────
// LIST CARD
// ─────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onRemove;
  const _ListCard({required this.bookmark, required this.onRemove});

  String _formatDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MovieDetailScreen(imdbId: bookmark.movieImdbId, bookmark: bookmark, userId: bookmark.userId),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.warmGray.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppTheme.radiusLg), bottomLeft: Radius.circular(AppTheme.radiusLg)),
              child: SizedBox(
                width: 68, height: 96,
                child: bookmark.moviePoster.isNotEmpty && bookmark.moviePoster != 'N/A'
                    ? Image.network(bookmark.moviePoster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 24)))
                    : const Center(child: Icon(Icons.movie_outlined, color: AppTheme.warmGray, size: 24)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookmark.movieTitle, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.cream), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 10, color: AppTheme.dustGray),
                      const SizedBox(width: 4),
                      Text('Saved ${_formatDate(bookmark.createdAt)}', style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.dustGray)),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.gold.withOpacity(0.25), width: 0.5),
                            ),
                            child: const Center(child: Text('VIEW', style: TextStyle(fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.gold, letterSpacing: 1))),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.crimson.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.crimson.withOpacity(0.3), width: 0.5),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 13, color: AppTheme.crimsonSoft),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Popup menu
            PopupMenuButton<String>(
              color: AppTheme.charcoal,
              onSelected: (v) {
                if (v == 'remove') onRemove();
                if (v == 'view') Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(imdbId: bookmark.movieImdbId, bookmark: bookmark, userId: bookmark.userId)));
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 16, color: AppTheme.ashGray), SizedBox(width: 8), Text('View Details', style: TextStyle(fontFamily: 'DMSans', color: AppTheme.cream, fontSize: 13))])),
                const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppTheme.crimsonSoft), SizedBox(width: 8), Text('Remove', style: TextStyle(fontFamily: 'DMSans', color: AppTheme.crimsonSoft, fontSize: 13))])),
              ],
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.dustGray, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
