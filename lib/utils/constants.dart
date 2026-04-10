class AppConstants {
 
  static const int apiTimeoutSeconds = 10;
  static const int maxRetries = 3;
  static const int initialRetryDelayMs = 100;
  static const double networkFailureRate = 0.30;


  static const int usersPerPage = 6;
  static const int moviesPerPage = 10;

 
  static const String localUsersBox = 'local_users';
  static const String bookmarksBox = 'bookmarks';

  
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 10);

  
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);


  static const String appTitle = 'Movie Task';
  static const String appName = 'MovieTask';

 
  static const String offlineMessage =
      'You\'re offline. Some features may be limited.';
  static const String reconnectingMessage = 'Reconnecting...';
  static const String noInternetMessage = 'No internet connection';
  static const String unexpectedError = 'An unexpected error occurred';
  static const String userCreatedSuccess = 'User created successfully!';
  static const String movieBookmarked = 'Added to bookmarks';
  static const String movieUnbookmarked = 'Removed from bookmarks';
}

class AppMetrics {
  
  static const double paddingXXSmall = 4.0;
  static const double paddingXSmall = 8.0;
  static const double paddingSmall = 12.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;


  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

 
  static const double userAvatarSize = 80.0;
  static const double moviePosterHeight = 250.0;
}
