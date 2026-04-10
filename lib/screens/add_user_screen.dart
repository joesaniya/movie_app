import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/connectivity_provider.dart';
import '../config/app_theme.dart';
import '../widgets/loading_widgets.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  late TextEditingController _nameController;
  late TextEditingController _jobController;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _jobController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final job = _jobController.text.trim();

    if (name.isEmpty || job.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in both name and job fields';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Name must be at least 2 characters';
      });
      return;
    }

    if (job.length < 2) {
      setState(() {
        _errorMessage = 'Job must be at least 2 characters';
      });
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
        // Online: Create user immediately via Reqres API
        await usersProvider.createUserOnlineSimple(name: name, job: job);
        setState(() {
          _successMessage = 'User created successfully on server!';
          _isLoading = false;
          _nameController.clear();
          _jobController.clear();
        });
      } else {
        await usersProvider.createLocalUser(name: name, job: job);
        setState(() {
          _successMessage = 'User created offline. Will sync when online.';
          _isLoading = false;
          _nameController.clear();
          _jobController.clear();
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create user: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create User'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a New User',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Create users with or without internet connection.\nYour offline users will sync when you\'re back online.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              Consumer<ConnectivityProvider>(
                builder: (context, connectivity, _) {
                  if (!connectivity.isOnline) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You\'re offline. This user will be created locally and synced when online.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter user name (e.g., morpheus)',
                  prefixIcon: const Icon(Icons.person),
                  enabled: !_isLoading,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _jobController,
                decoration: InputDecoration(
                  labelText: 'Job',
                  hintText: 'Enter job title (e.g., leader)',
                  prefixIcon: const Icon(Icons.work),
                  enabled: !_isLoading,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => !_isLoading ? _submitForm() : null,
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.successColor),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  border: Border.all(
                    color: AppTheme.infoColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ How it works',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Users created offline are stored locally and will sync to the server when internet is restored.\n\n• Once created, you can immediately browse and bookmark movies for this user.\n\n• All your bookmarks will automatically sync when online.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.6),
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
