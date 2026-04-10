import 'dart:developer';

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/bookmark_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/service_locator.dart';

class PaginatedUsersProvider extends ChangeNotifier {
  final ApiService _apiService = getIt<ApiService>();
  final LocalStorageService _localStorageService = getIt<LocalStorageService>();

  final List<User> _users = [];
  List<LocalUser> _localUsers = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;

  List<User> get allUsers {
    final apiUsers = _users;


    final unsyncedLocalUsersList = _localUsers.where((lu) => !lu.isSynced).map((
      lu,
    ) {
      final nameParts = lu.name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      return User(
        email: lu.name,
        firstName: firstName,
        lastName: lastName,
        avatar: _generateAvatarUrl(firstName, lastName),
      );
    }).toList();

    return [...unsyncedLocalUsersList, ...apiUsers];
  }

  List<User> get users => _users;
  List<LocalUser> get localUsers => _localUsers;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchUsers({bool refresh = false}) async {
   
    if (!refresh && _isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _users.clear();
      _error = null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchUsers(page: _currentPage);
      log('Fetched page $_currentPage: ${response.data.length} users');
      log('Total pages: ${response.totalPages}');

      _users.addAll(response.data);
      _currentPage = response.page + 1;
      _totalPages = response.totalPages;
      _hasMore = response.page < response.totalPages;
      _error = null;

      log(
        'Now on page $_currentPage, hasMore: $_hasMore, totalUsers: ${_users.length}',
      );
    } catch (e) {
      _error = 'Failed to load users: $e';
      print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLocalUsers() async {
    try {
      _localUsers = await _localStorageService.getAllUsers();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load local users: $e';
      notifyListeners();
    }
  }

  Future<void> createLocalUser({
    required String name,
    required String job,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _localStorageService.createUser(name: name, job: job);

      await loadLocalUsers();
      _error = null;
    } catch (e) {
      _error = 'Failed to create user: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> createUserOnline({
    required String firstName,
    required String lastName,
    required String email,
    required String avatar,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.createUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        avatar: avatar.isNotEmpty
            ? avatar
            : _generateAvatarUrl(firstName, lastName),
      );

      
      final newUser = User(
        id: int.tryParse(response.id ?? ''),
        email: email,
        firstName: firstName,
        lastName: lastName,
        avatar: avatar.isNotEmpty
            ? avatar
            : _generateAvatarUrl(firstName, lastName),
      );

      log('Created user: ${newUser.toJson()}');
      _users.insert(0, newUser);
      _error = null;

     
      final apiId = response.id ?? '';
      await _localStorageService.createSyncedUser(
        name: '$firstName $lastName',
        job: email,
        apiId: apiId,
      );

     
      await loadLocalUsers();
      notifyListeners();

      return newUser;
    } catch (e) {
      _error = 'Failed to create user: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User? getUserById(String? userId) {
    if (userId == null) return null;

    try {
      return _users.firstWhere((u) => u.id?.toString() == userId);
    } catch (e) {
      return null;
    }
  }

  String _generateAvatarUrl(String firstName, String lastName) {
   
    final seed = '$firstName $lastName'.toLowerCase().replaceAll(' ', '_');
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$seed';
  }

  void reset() {
    _users.clear();
    _currentPage = 1;
    _totalPages = 1;
    _isLoading = false;
    _error = null;
    _hasMore = true;
    notifyListeners();
  }
}
