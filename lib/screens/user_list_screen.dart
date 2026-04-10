import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/loading_widgets.dart' as lw;
import '../widgets/avatar_image_widget.dart';
import '../config/app_theme.dart';
import '../config/ui_components.dart';
import 'add_user_screen.dart';
import 'movie_list_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  final bool _showConnectingIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _headerController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _headerFade = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usersProvider = Provider.of<PaginatedUsersProvider>(context, listen: false);
      final connectivityProvider = Provider.of<ConnectivityProvider>(context, listen: false);
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
    _headerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = Provider.of<PaginatedUsersProvider>(context, listen: false);
    final pos = _scrollController.position;
    if (pos.pixels >= (pos.maxScrollExtent * 0.8) - 500 && p.hasMore && !p.isLoading) {
      p.fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBlack,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
            ),
          ),
          // Decorative film grain texture overlay (subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/7/76/1k_Dissolve_Noise_Texture.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── OFFLINE BANNER ──
                Consumer<ConnectivityProvider>(
                  builder: (ctx, conn, _) => Column(children: [
                    if (!conn.isOnline) const lw.NoInternetWidget(),
                    if (_showConnectingIndicator && conn.isOnline) const lw.ConnectingIndicator(),
                  ]),
                ),

                // ── HEADER ──
                FadeTransition(
                  opacity: _headerFade,
                  child: _buildHeader(),
                ),

                // ── LIST ──
                Expanded(
                  child: Consumer<PaginatedUsersProvider>(
                    builder: (ctx, provider, _) {
                      if (provider.allUsers.isEmpty && provider.isLoading) {
                        return const lw.LoadingWidget(message: 'Loading profiles...');
                      }
                      if (provider.allUsers.isEmpty && provider.error != null) {
                        return lw.ErrorWidget(message: provider.error!, onRetry: () => provider.fetchUsers(refresh: true));
                      }
                      if (provider.allUsers.isEmpty) {
                        return lw.EmptyWidget(title: 'No Profiles Found', message: 'Create a profile to start discovering films.', icon: Icons.person_outline_rounded, onRetry: () => provider.fetchUsers(refresh: true));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: provider.allUsers.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == provider.allUsers.length) {
                            return const Padding(padding: EdgeInsets.all(20), child: lw.LoadingWidget(isSmall: true));
                          }
                          final user = provider.allUsers[i];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 250 + i * 55),
                            curve: Curves.easeOut,
                            builder: (ctx, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
                            child: UserCard(
                              user: user,
                              isLocal: user.id == null,
                              onTap: () {
                                final bk = context.read<BookmarkProvider>();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => MultiProvider(
                                    providers: [ChangeNotifierProvider.value(value: bk)],
                                    child: MovieListScreen(userId: user.localId ?? user.id?.toString() ?? user.firstName, userName: user.fullName),
                                  ),
                                ));
                              },
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

      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo mark
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: AppTheme.goldGlow,
                ),
                child: const Icon(Icons.local_movies_rounded, color: AppTheme.inkBlack, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('CINEPLEX', style: TextStyle(fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.gold, letterSpacing: 3)),
              const Spacer(),
              Consumer<ConnectivityProvider>(
                builder: (_, conn, __) => ConnectivityDot(isOnline: conn.isOnline),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Who\'s\nWatching?', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.cream, height: 1.1, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Select your profile to browse the collection.', style: TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.ashGray)),
          const SizedBox(height: 18),
          const GoldDivider(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.goldGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final p = context.read<PaginatedUsersProvider>();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()))
                .then((_) { if (mounted) p.loadLocalUsers(); });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.inkBlack, size: 20),
                SizedBox(width: 8),
                Text('ADD PROFILE', style: TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.inkBlack, letterSpacing: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// USER CARD
// ─────────────────────────────────────────────
class UserCard extends StatefulWidget {
  final User user;
  final bool isLocal;
  final VoidCallback onTap;

  const UserCard({super.key, required this.user, required this.isLocal, required this.onTap});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _pressed
                ? AppTheme.gold.withOpacity(0.4)
                : widget.isLocal
                    ? AppTheme.amber.withOpacity(0.3)
                    : AppTheme.warmGray.withOpacity(0.4),
            width: _pressed ? 1 : 0.5,
          ),
          boxShadow: _pressed ? AppTheme.goldGlow : AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.user.fullName, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.cream), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (widget.isLocal) ...[
                          const SizedBox(width: 8),
                          const FilmBadge(label: 'LOCAL', color: AppTheme.amber, icon: Icons.cloud_off_rounded),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(widget.user.email, style: const TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.dustGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMoviesBtn(),
                        const SizedBox(width: 10),
                        if (widget.user.id != null)
                          Text('ID #${widget.user.id.toString().padLeft(3,'0')}', style: const TextStyle(fontFamily: 'DMSans', fontSize: 10, color: AppTheme.dustGray)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.dustGray, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.isLocal) {
      final initials = widget.user.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
      return Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.amber.withOpacity(0.3), AppTheme.amber.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.amber.withOpacity(0.4), width: 0.5),
        ),
        child: Center(child: Text(initials, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.amber))),
      );
    }

    final colors = [
      [AppTheme.gold, AppTheme.amber],
      [AppTheme.crimsonSoft, AppTheme.crimson],
      [AppTheme.jade, AppTheme.jadeSoft],
      [AppTheme.goldLight, AppTheme.gold],
    ];
    final idx = (widget.user.id ?? 0) % 4;
    final gradient = LinearGradient(colors: colors[idx], begin: Alignment.topLeft, end: Alignment.bottomRight);

    if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AvatarImageWidget(imageUrl: widget.user.avatar!, width: 54, height: 54, isCircle: false),
      );
    }

    final initials = widget.user.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(initials, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.inkBlack))),
    );
  }

  Widget _buildMoviesBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3), width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_outlined, size: 11, color: AppTheme.gold),
          SizedBox(width: 5),
          Text('BROWSE FILMS', style: TextStyle(fontFamily: 'DMSans', fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.gold, letterSpacing: 1)),
        ],
      ),
    );
  }
}
