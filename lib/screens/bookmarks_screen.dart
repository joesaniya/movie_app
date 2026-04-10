import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark_model.dart';
import '../widgets/loading_widgets.dart' as loading_widgets;
import 'movie_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const BookmarksScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late TextEditingController _searchController;
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookmarkProvider = context.read<BookmarkProvider>();
      bookmarkProvider.loadUserBookmarks(widget.userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bookmark> _getFilteredBookmarks(List<Bookmark> bookmarks) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return bookmarks;
    }
    return bookmarks
        .where((b) => b.movieTitle.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.userName}\'s Bookmarks',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          Tooltip(
            message: _gridView ? 'List view' : 'Grid view',
            child: IconButton(
              icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _gridView = !_gridView;
                });
              },
            ),
          ),
        ],
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, bookmarkProvider, _) {
          if (bookmarkProvider.isLoading &&
              bookmarkProvider.bookmarks.isEmpty) {
            return const loading_widgets.LoadingWidget(
              message: 'Loading bookmarks...',
            );
          }

          final bookmarks = bookmarkProvider.bookmarks;
          final filteredBookmarks = _getFilteredBookmarks(bookmarks);

          if (bookmarks.isEmpty) {
            return Center(
              child: loading_widgets.EmptyWidget(
                icon: Icons.bookmark_outline,
                title: 'No Bookmarks Yet',
                message:
                    'Start bookmarking movies to see them here!\nVisit the movie list to add your favorites.',
                onRetry: () {
                  context.read<BookmarkProvider>().loadUserBookmarks(
                    widget.userId,
                  );
                },
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bookmarks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              // Bookmarks Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${filteredBookmarks.length} Bookmarked',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Bookmarks List/Grid
              Expanded(
                child: filteredBookmarks.isEmpty
                    ? Center(
                        child: Text(
                          'No bookmarks match your search',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      )
                    : _gridView
                    ? _buildGridView(filteredBookmarks)
                    : _buildListView(filteredBookmarks),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridView(List<Bookmark> bookmarks) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildMovieCard(context, bookmark);
      },
    );
  }

  Widget _buildListView(List<Bookmark> bookmarks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildMovieListTile(context, bookmark);
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, Bookmark bookmark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(
              imdbId: bookmark.movieImdbId,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child:
                    bookmark.moviePoster.isNotEmpty &&
                        bookmark.moviePoster != 'N/A'
                    ? Image.network(
                        bookmark.moviePoster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.movie, size: 48)),
                      )
                    : const Center(child: Icon(Icons.movie, size: 48)),
              ),
            ),
            // Title and Remove Button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.movieTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _removeBookmark(context, bookmark);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildMovieListTile(BuildContext context, Bookmark bookmark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child:
              bookmark.moviePoster.isNotEmpty && bookmark.moviePoster != 'N/A'
              ? Image.network(
                  bookmark.moviePoster,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.movie, size: 32)),
                )
              : const Center(child: Icon(Icons.movie, size: 32)),
        ),
        title: Text(
          bookmark.movieTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Bookmarked on ${_formatDate(bookmark.createdAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'remove') {
              _removeBookmark(context, bookmark);
            } else if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(
                    imdbId: bookmark.movieImdbId,
                    userId: widget.userId,
                  ),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(
                imdbId: bookmark.movieImdbId,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeBookmark(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark?'),
        content: Text(
          'Are you sure you want to remove "${bookmark.movieTitle}" from your bookmarks?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookmarkProvider>().removeBookmark(
                userId: widget.userId,
                bookmarkId: bookmark.id,
                movieImdbId: bookmark.movieImdbId,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '"${bookmark.movieTitle}" removed from bookmarks',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
