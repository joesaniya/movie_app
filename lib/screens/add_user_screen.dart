import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/connectivity_provider.dart';
import '../config/app_theme.dart';
import '../config/ui_components.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _jobController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  bool _nameFocused = false;
  bool _jobFocused = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _jobController = TextEditingController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final job = _jobController.text.trim();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (name.isEmpty || job.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both name and job fields');
      return;
    }
    if (name.length < 2) {
      setState(() => _errorMessage = 'Name must be at least 2 characters');
      return;
    }
    if (job.length < 2) {
      setState(() => _errorMessage = 'Job must be at least 2 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final usersProvider = Provider.of<PaginatedUsersProvider>(
        context,
        listen: false,
      );
      final connectivity = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );

      if (connectivity.isOnline) {
        await usersProvider.createUserOnlineSimple(name: name, job: job);
        setState(() {
          _successMessage = 'Profile created successfully!';
          _isLoading = false;
          _nameController.clear();
          _jobController.clear();
        });
      } else {
        await usersProvider.createLocalUser(name: name, job: job);
        setState(() {
          _successMessage = 'Profile saved locally. Will sync when online.';
          _isLoading = false;
          _nameController.clear();
          _jobController.clear();
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create profile: $e';
        _isLoading = false;
      });
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
                _buildTopBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeading(),
                            const SizedBox(height: 24),
                            Consumer<ConnectivityProvider>(
                              builder: (ctx, conn, _) => !conn.isOnline
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: _buildOfflineCard(),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            _buildFormCard(),
                            const SizedBox(height: 20),
                            if (_errorMessage != null)
                              _buildMessageCard(isError: true),
                            if (_successMessage != null)
                              _buildMessageCard(isError: false),
                            if (_errorMessage != null ||
                                _successMessage != null)
                              const SizedBox(height: 20),
                            Consumer<ConnectivityProvider>(
                              builder: (context, connectivity, _) {
                                final buttonLabel = connectivity.isOnline
                                    ? 'CREATE & SYNC'
                                    : 'SAVE OFFLINE';
                                return GoldButton(
                                  label: buttonLabel,
                                  onPressed: _submitForm,
                                  isLoading: _isLoading,
                                  icon: Icons.person_add_rounded,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            // _buildActualSubmitButton(),
                            // const SizedBox(height: 12),
                            GoldButton(
                              label: 'CANCEL',
                              outlined: true,
                              color: AppTheme.ashGray,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 32),
                            _buildInfoCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualSubmitButton() {
    return Consumer<ConnectivityProvider>(
      builder: (ctx, conn, _) {
        final label = conn.isOnline ? 'CREATE & SYNC' : 'SAVE OFFLINE';
        final icon = conn.isOnline
            ? Icons.cloud_upload_rounded
            : Icons.save_rounded;
        return GoldButton(
          label: label,
          onPressed: _submitForm,
          isLoading: _isLoading,
          icon: icon,
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          FilmBackButton(),
          const SizedBox(width: 12),
          const Text(
            'NEW PROFILE',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              color: AppTheme.ashGray,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const FilmBadge(
            label: 'CREATE',
            color: AppTheme.gold,
            icon: Icons.add_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Create Your\nProfile',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppTheme.cream,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Works with or without internet.\nOffline profiles sync automatically.',
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            color: AppTheme.ashGray,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const GoldDivider(),
      ],
    );
  }

  Widget _buildOfflineCard() {
    return EditorialCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.amber.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.amber,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFFLINE MODE',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.amber,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Profile stored locally and will sync automatically when connection is restored.',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.amber,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return EditorialCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildField(
            controller: _nameController,
            label: 'FULL NAME',
            hint: 'e.g. morpheus',
            icon: Icons.person_outline_rounded,
            focused: _nameFocused,
            onFocusChange: (v) => setState(() => _nameFocused = v),
            action: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          const GoldDivider(),
          const SizedBox(height: 8),
          _buildField(
            controller: _jobController,
            label: 'JOB TITLE',
            hint: 'e.g. leader',
            icon: Icons.work_outline_rounded,
            focused: _jobFocused,
            onFocusChange: (v) => setState(() => _jobFocused = v),
            action: TextInputAction.done,
            onSubmitted: (_) => !_isLoading ? _submitForm() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool focused,
    required Function(bool) onFocusChange,
    TextInputAction? action,
    ValueChanged<String>? onSubmitted,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7, left: 2),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: focused ? AppTheme.gold : AppTheme.ashGray,
                letterSpacing: 2,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.inkBlack.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: focused
                    ? AppTheme.gold.withOpacity(0.7)
                    : AppTheme.warmGray.withOpacity(0.5),
                width: focused ? 1 : 0.5,
              ),
              boxShadow: focused ? AppTheme.goldGlow : null,
            ),
            child: TextField(
              controller: controller,
              textInputAction: action,
              onSubmitted: onSubmitted,
              enabled: !_isLoading,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                color: AppTheme.cream,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  color: AppTheme.dustGray,
                ),
                prefixIcon: Icon(
                  icon,
                  color: focused ? AppTheme.gold : AppTheme.dustGray,
                  size: 17,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({required bool isError}) {
    final color = isError ? AppTheme.crimson : AppTheme.jade;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final text = isError ? _errorMessage! : _successMessage!;
    return EditorialCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final items = [
      (
        Icons.sync_rounded,
        AppTheme.gold,
        'Offline profiles sync automatically when connectivity is restored.',
      ),
      (
        Icons.bookmark_add_rounded,
        AppTheme.crimsonSoft,
        'Browse and bookmark films immediately after creating a profile.',
      ),
      (
        Icons.lock_outline_rounded,
        AppTheme.jade,
        'All your data is stored securely on-device and in the cloud.',
      ),
    ];
    return EditorialCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'How it works',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.$2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(item.$1, color: item.$2, size: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$3,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.ashGray,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
