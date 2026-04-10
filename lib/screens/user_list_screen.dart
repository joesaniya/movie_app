import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/loading_widgets.dart' as loading_widgets;
import '../widgets/avatar_image_widget.dart';
import 'add_user_screen.dart';
import 'movie_list_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late ScrollController _scrollController;
  final bool _showConnectingIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usersProvider = Provider.of<PaginatedUsersProvider>(
        context,
        listen: false,
      );
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );

      usersProvider.loadLocalUsers();

      if (!connectivityProvider.isOnline) {
        usersProvider.loadCachedApiUsers();
      } else {
        usersProvider.fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final usersProvider = Provider.of<PaginatedUsersProvider>(
      context,
      listen: false,
    );

    final scrollPosition = _scrollController.position;
    final isNearBottom =
        scrollPosition.pixels >= (scrollPosition.maxScrollExtent * 0.8) - 500;

    if (isNearBottom && usersProvider.hasMore && !usersProvider.isLoading) {
      usersProvider.fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Consumer<ConnectivityProvider>(
                  builder: (context, connectivity, _) {
                    return Text(
                      connectivity.isOnline ? '●  Online' : '●  Offline',
                      style: TextStyle(
                        color: connectivity.isOnline
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
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
                  if (_showConnectingIndicator && connectivity.isOnline)
                    const loading_widgets.ConnectingIndicator(),
                ],
              );
            },
          ),
          Expanded(
            child: Consumer<PaginatedUsersProvider>(
              builder: (context, usersProvider, _) {
                if (usersProvider.allUsers.isEmpty && usersProvider.isLoading) {
                  return const loading_widgets.LoadingWidget(
                    message: 'Loading users...',
                  );
                }

                if (usersProvider.allUsers.isEmpty &&
                    usersProvider.error != null) {
                  return loading_widgets.ErrorWidget(
                    message: usersProvider.error!,
                    onRetry: () => usersProvider.fetchUsers(refresh: true),
                  );
                }

                if (usersProvider.allUsers.isEmpty) {
                  return loading_widgets.EmptyWidget(
                    title: 'No Users Found',
                    message: 'Create a new user or fetch from server',
                    icon: Icons.people_outline,
                    onRetry: () => usersProvider.fetchUsers(refresh: true),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      usersProvider.allUsers.length +
                      (usersProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == usersProvider.allUsers.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const loading_widgets.LoadingWidget(
                          isSmall: true,
                        ),
                      );
                    }

                    final user = usersProvider.allUsers[index];
                    final isLocalUser = user.id == null;

                    return UserCard(
                      user: user,
                      isLocal: isLocalUser,
                      onTap: () {
                        final bookmarkProvider = context
                            .read<BookmarkProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: bookmarkProvider,
                                ),
                              ],
                              child: MovieListScreen(
                                userId:
                                    user.localId ??
                                    user.id?.toString() ??
                                    user.firstName,
                                userName: user.fullName,
                              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final usersProvider = context.read<PaginatedUsersProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          ).then((_) {
            if (mounted) {
              usersProvider.loadLocalUsers();
            }
          });
        },
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;
  final bool isLocal;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.isLocal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLocal
            ? BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isLocal
                    ? Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.3),
                              Colors.orange.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.orange,
                        ),
                      )
                    : AvatarImageWidget(
                        imageUrl: user.avatar,
                        width: 80,
                        height: 80,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Offline',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.movie, size: 18),
                          label: const Text('View Movies'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
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
    );
  }
}
