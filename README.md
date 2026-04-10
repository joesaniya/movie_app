# Movie Task Application

A professional Flutter application that fetches paginated lists of users and movies, supports offline functionality with local storage, and provides advanced features like bookmarking with automatic syncing when online.

## Features

### 1. User Management
- **Paginated User List**: Fetch and display users from the ReqRes API with infinite scrolling
- **Add User Functionality**: Create users with offline support
- **Offline Support**: Users created offline are stored locally using Hive and automatically synced when internet is restored
- **User Avatar Display**: Cached network images for fast loading

### 2. Movie Browser
- **Movie Listing**: Search and browse movies from the OMDb API
- **Trending Movies**: Default view shows trending movies
- **Search Functionality**: Search for specific movies with pagination support
- **Infinite Scrolling**: Automatically load more movies as user scrolls
- **Movie Details**: View comprehensive movie information including:
  - Title, year, release date
  - Director, cast, and plot summary
  - Genre, rating, and runtime
  - Poster images with caching

### 3. Offline Bookmarking
- **Local Bookmarking**: Bookmark movies even when offline
- **User-Specific Bookmarks**: Each user has their own bookmarks
- **Offline-First**: Fully operational without internet connection
- **Automatic Syncing**: Bookmarks sync automatically when online
- **Offline User Support**: Create users offline and immediately bookmark movies

### 4. Network Resilience
- **Automatic Retry Mechanism**: Implements exponential backoff for failed requests
- **Simulated Failures**: 30% of GET requests randomly fail to test resilience
- **Silent Error Handling**: Graceful failure handling with reconnecting indicators
- **No Data Duplication**: Pagination handles errors without duplicating data

### 5. Connectivity Management
- **Real-time Status**: App displays online/offline status
- **Graceful Degradation**: Features adapt based on connectivity
- **No Internet Widget**: Warns users when offline
- **Reconnecting Indicator**: Shows when attempting to reconnect

## Architecture

### Technical Stack
- **Framework**: Flutter with Provider for state management
- **Language**: Dart 3.9.2+
- **UI Library**: Material Design 3
- **Networking**: Dio with custom interceptors
- **Local Storage**: Hive (key-value store)
- **Connectivity**: connectivity_plus
- **Dependency Injection**: GetIt
- **Image Caching**: CachedNetworkImage
- **Fonts**: Google Fonts

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── config/
│   └── app_theme.dart            # Theme configuration
├── models/
│   ├── user_model.dart           # User data models
│   ├── movie_model.dart          # Movie data models
│   └── bookmark_model.dart       # Bookmark and LocalUser models
├── services/
│   ├── api_service.dart          # API calls using Dio
│   ├── network_interceptor.dart  # Network failure simulation & retry logic
│   ├── local_storage_service.dart # Hive-based local storage
│   ├── connectivity_service.dart  # Connectivity monitoring
│   ├── sync_service.dart         # Offline data syncing
│   └── service_locator.dart      # GetIt configuration
├── providers/
│   ├── user_provider.dart        # User state management
│   ├── movie_provider.dart       # Movie state management
│   ├── movie_detail_provider.dart # Movie details state
│   ├── bookmark_provider.dart    # Bookmark state management
│   └── connectivity_provider.dart # Connectivity state
├── screens/
│   ├── user_list_screen.dart     # User listing with pagination
│   ├── add_user_screen.dart      # User creation
│   ├── movie_list_screen.dart    # Movie listing and search
│   └── movie_detail_screen.dart  # Movie details
└── widgets/
    └── loading_widgets.dart       # Reusable UI components
```

### State Management
The application uses **Provider** for state management with the following providers:
- `PaginatedUsersProvider`: Manages user list and pagination
- `PaginatedMoviesProvider`: Manages movie search and pagination
- `MovieDetailProvider`: Manages selected movie details
- `BookmarkProvider`: Manages user bookmarks locally
- `ConnectivityProvider`: Monitors internet connectivity

## API Integration

### ReqRes API
- **Base URL**: `https://reqres.in/api`
- **Users Endpoint**: `GET /users?page={page}&per_page=6`
- **Create User**: `POST /users` with name and job
- **Per Page**: 6 users per page

### OMDb API
- **Base URL**: `https://www.omdbapi.com`
- **API Key**: `eac7cc99`
- **Search Movies**: `GET /?s={query}&page={page}&apikey={key}&type=movie`
- **Movie Details**: `GET /?i={imdbId}&apikey={key}&type=movie`

## Offline Features

### Local Storage with Hive
The application stores the following data locally:
1. **Local Users**: Users created while offline
   - Auto-sync status tracking
   - API ID mapping after sync
2. **Bookmarks**: Movie bookmarks linked to users
   - Sync status tracking
   - Never loses data

### Automatic Syncing
When connectivity is restored, the app automatically:
1. Syncs unsynced users to the API
2. Updates local user records with API IDs
3. Marks bookmarks as synced
4. No data loss or relationship errors

### Data Persistence
- All offline data persists across app restarts
- Bookmarks remain linked to users after sync
- Automatic cleanup after successful sync

## Network Resilience Implementation

### Failure Simulation
- Simulates 30% failure rate on GET requests
- Random SocketException or 500 errors
- Only affects GET requests, POST requests pass through

### Automatic Retry Logic
- Exponential backoff: 100ms, 200ms, 400ms, etc.
- Maximum 3 retries per request
- Transparent to UI (silent retry)

### UI Handling
- Subtle "Reconnecting..." indicator instead of error dialogs
- No data flickering or duplication
- Graceful degradation of features
- User-friendly error messages

## User Experience Features

### Design
- Clean Material Design 3 interface
- Gradient backgrounds and smooth animations
- Responsive layout for different screen sizes
- Custom fonts using Google Fonts (Poppins)

### Navigation
- Intuitive flow: Users → Movies → Details
- Back navigation preserves state
- Floating action buttons for primary actions

### Loading States
- Shimmer loading animations
- Loading indicators for pagination
- Clear empty states with action buttons

### Error Handling
- User-friendly error messages
- Retry buttons for failed operations
- Clear offline indicators
- Non-intrusive reconnecting notifications

## Installation & Setup

### Requirements
- Flutter 3.9.2 or higher
- Dart 3.9.2 or higher
- iOS 11.0+ (iOS development)
- Android API 21+ (Android development)

### Steps
1. Clone the repository
2. Navigate to project directory: `cd movie_task_ap`
3. Get dependencies: `flutter pub get`
4. Run the app: `flutter run`

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## Testing

### Network Resilience Testing
The app simulates random network failures:
1. Launch the app
2. Try to load users or movies
3. About 30% of requests will fail silently
4. The app automatically retries with exponential backoff
5. UI continues to work without interruption

### Offline Testing
1. Create users while in airplane mode
2. Navigate to movies and bookmark them
3. Turn on internet - data syncs automatically
4. Verify all bookmarks are preserved

### Pagination Testing
1. Scroll through user/movie lists
2. Observe infinite scrolling with new data loads
3. Verify no duplicate data appears
4. Test with simulated failures

## Performance Optimizations

1. **Image Caching**: Cached network images prevent re-downloading
2. **Lazy Loading**: Pagination loads data as needed
3. **Provider Pattern**: Efficient state updates only for affected widgets
4. **Hive Database**: Fast local storage with minimal overhead
5. **Dio Interceptors**: Efficient request/response handling

## Dependencies

Key dependencies and their versions:
- `provider: ^6.1.0` - State management
- `dio: ^5.3.1` - HTTP client
- `hive: ^2.2.3` & `hive_flutter: ^1.1.0` - Local storage
- `connectivity_plus: ^5.0.0` - Connectivity monitoring
- `cached_network_image: ^3.3.0` - Image caching
- `google_fonts: ^6.1.0` - Typography
- `uuid: ^4.0.0` - ID generation
- `shimmer: ^3.0.0` - Loading animations
- `get_it: ^7.6.0` - Service locator
- `logging: ^1.2.0` - Logging framework

## Best Practices Implemented

1. **SOLID Principles**: Single responsibility, open/closed
2. **Clean Architecture**: Separation of concerns
3. **DRY Code**: Reusable widgets and services
4. **Error Handling**: Comprehensive error management
5. **Logging**: Complete logging for debugging
6. **Type Safety**: Strong typing throughout
7. **Documentation**: Well-documented code
8. **Responsive Design**: Works on various screen sizes

## Future Enhancement Ideas

1. **Authentication**: User login/registration
2. **Advanced Search Filters**: Genre, year, rating filters
3. **User Preferences**: Theme customization
4. **Backend Sync API**: Custom backend for bookmarks
5. **Movie Reviews**: User ratings and reviews
6. **Favorites Management**: Organize and manage bookmarks
7. **Push Notifications**: Sync completion notifications
8. **Offline Viewing**: Download movies for offline watch

## Troubleshooting

### Dependencies Not Installing
```bash
flutter clean
flutter pub get
```

### Build Issues
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Runtime Errors
- Check device logs: `flutter logs`
- Ensure APIs are accessible
- Verify Hive initialization completed

## License

This project is part of a Flutter developer assignment.

## Support

For issues or questions, please refer to the in-app help or test the features manually following the user guide above.

---

**Remember**: This app works great offline! Create users, browse movies, and bookmark them even without internet. Everything syncs automatically when you're back online!
