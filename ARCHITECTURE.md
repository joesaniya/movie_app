# Architecture Overview

## Design Principles

The Movie Task application follows industry best practices and proven architectural patterns:

### 1. **Clean Architecture**
- **Separation of Concerns**: Each layer has a specific responsibility
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Testability**: Components are designed to be independently testable

### 2. **Provider Pattern for State Management**
- **Reactive Programming**: UI rebuilds automatically when state changes
- **Efficient Updates**: Only affected widgets rebuild
- **Single Responsibility**: Each provider manages one aspect of state

### 3. **Service Locator Pattern (GetIt)**
- **Dependency Injection**: Services are registered and injected
- **Loose Coupling**: Components don't create their dependencies
- **Easy Testing**: Mock services can be injected for testing

### 4. **Offline-First Architecture**
- **Local-First**: Data stored locally by default
- **Sync When Possible**: Automatic sync when connectivity restored
- **No Data Loss**: Persistence across app restarts

## Architectural Layers

```
┌─────────────────────────────────────────────────────┐
│                   UI LAYER (Screens)                │
│  ┌─────────────────────────────────────────────┐   │
│  │ UserListScreen │ MovieListScreen │ Detail...│   │
│  └─────────────────────────────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│               PROVIDER LAYER (State)                │
│  ┌─────────────────────────────────────────────┐   │
│  │ UserProvider │ MovieProvider │ Bookmark... │   │
│  └─────────────────────────────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              SERVICE LAYER (Business Logic)         │
│  ┌─────────────────────────────────────────────┐   │
│  │ ApiService │ LocalStorageService │ Sync... │   │
│  └─────────────────────────────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│           DATA LAYER (Models & Storage)             │
│  ┌─────────────────────────────────────────────┐   │
│  │ User │ Movie │ Bookmark │ Hive Database    │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Component Interactions

### User Creation Flow

```
UserListScreen
    ↓
  (FAB click)
    ↓
AddUserScreen
    ↓
PaginatedUsersProvider.createLocalUser()
    ↓
LocalStorageService.createUser()
    ↓
Hive Box ['local_users']
    ↓
(If Online) UpdateUI immediately
(If Offline) UpdateUI + mark for sync
```

### Movie Bookmarking Flow

```
MovieDetailScreen
    ↓
BookmarkButton.onPressed()
    ↓
BookmarkProvider.bookmarkMovie()
    ↓
LocalStorageService.bookmarkMovie()
    ↓
Hive Box ['bookmarks']
    ↓
UpdateUI + mark sync status
    ↓
(When Online) SyncService.syncOfflineData()
    ↓
Mark bookmarks as synced
```

### Offline Sync Flow

```
App Startup
    ↓
ConnectivityProvider detects Online
    ↓
SyncService.syncOfflineData()
    ↓
├─ Check unsynced users
│   ├─ For each user:
│   │  ├─ POST to API (/users)
│   │  └─ Update local user with API ID
│   └─ Mark as synced
│
└─ Check unsynced bookmarks
    ├─ For each bookmark:
    │  └─ Send to backend (if implemented)
    └─ Mark as synced
    
(All without UI interruption)
```

## Data Models

### User Entity
```dart
class User {
  int? id;           // API ID (null for offline users)
  String email;
  String firstName;
  String lastName;
  String avatar;
}

class LocalUser extends User {
  String localId;           // Local UUID
  DateTime createdAt;
  bool isSynced;           // Sync status
  String? apiId;           // API ID after sync
}
```

### Movie Entity
```dart
class Movie {
  String title;
  String imdbId;
  String poster;
  String year;
  String type;
}

class MovieDetail extends Movie {
  String plot;
  String director;
  String actors;
  String rated;
  String runtime;
  String releaseDate;
}
```

### Bookmark Entity
```dart
class Bookmark {
  String id;                // Local UUID
  String userId;            // Link to user
  String movieImdbId;       // Link to movie
  String movieTitle;
  String moviePoster;
  DateTime createdAt;
  bool isSynced;            // Sync status
}
```

## Network Architecture

### Dio Client Configuration
```
Dio (HTTP Client)
  ├─ Base URL: ReqRes API / OMDb API
  ├─ Timeout: 10 seconds
  ├─ Redirects: 5
  └─ Interceptors:
      ├─ SimulatedFailureInterceptor (30% failure rate)
      └─ NetworkInterceptor (retry logic)
           ├─ Exponential backoff
           ├─ Max 3 retries
           └─ Silent retry (no UI disruption)
```

### API Endpoints

**ReqRes API (User Management)**
```
GET  /api/users?page=1&per_page=6
POST /api/users { "name": "...", "job": "..." }
```

**OMDb API (Movie Browsing)**
```
GET /?s={query}&page={page}&apikey=eac7cc99
GET /?i={imdbId}&apikey=eac7cc99
```

## State Management Flow

### Provider Hierarchy
```
root:MultiProvider
├─ PaginatedUsersProvider
│   ├─ listeners: [UserListScreen]
│   └─ state: {users, page, isLoading, error, hasMore}
│
├─ PaginatedMoviesProvider
│   ├─ listeners: [MovieListScreen]
│   └─ state: {movies, page, isLoading, error, hasMore}
│
├─ MovieDetailProvider
│   ├─ listeners: [MovieDetailScreen]
│   └─ state: {movieDetail, isLoading, error}
│
├─ BookmarkProvider
│   ├─ listeners: [MovieCard, BookmarkButton]
│   └─ state: {bookmarks, isLoading, error}
│
└─ ConnectivityProvider
    ├─ listeners: [All screens]
    └─ state: {isOnline}
```

### State Update Pattern
```
User Action
    ↓
Provider Method Called
    ↓
setLoading(true) → UI rebuilds (shows spinner)
    ↓
Call Service Method
    ↓
Operation Completes
    ↓
Update State (data/error)
    ↓
notifyListeners() → UI rebuilds (shows result)
```

## Offline Data Synchronization

### Local Storage Strategy
```
Hive Database Structure:
├─ local_users (Box<Map>)
│  └─ {id: {...user data...}, isSynced: 0}
│
└─ bookmarks (Box<Map>)
   └─ {id: {...bookmark data...}, isSynced: 0}
```

### Sync Algorithm
```
1. Detect Online (via ConnectivityService)
2. Query Unsynced Records:
   - getUnsyncedUsers() → List<LocalUser>
   - getUnsyncedBookmarks() → List<Bookmark>
3. For Each Unsynced Item:
   - Attempt API call
   - If Success: updateSyncStatus(true)
   - If Failure: Log error, continue with next
4. UI Updates Automatically (via Provider listeners)
```

## Error Handling Strategy

### Network Failures
```
GET Request
    ↓
SimulatedFailureInterceptor (30% random fail)
    ├─ If fail: throw SocketException/500
    └─ If pass: continue
    ↓
Request executes
    ├─ If timeout: catch TimeoutException
    ├─ If network error: catch DioException
    └─ If success: return Response
    ↓
NetworkInterceptor.onError()
    ├─ If GET: attempt retry
    │  └─ for i < 3:
    │     ├─ wait(exponentialBackoff(i))
    │     └─ retry request
    ├─ If max retries exceeded: throw error
    └─ If not GET: throw error immediately
    ↓
Provider catches error:
    ├─ Set _error = errorMessage
    ├─ Set _isLoading = false
    └─ notifyListeners()
    ↓
UI shows error OR reconnecting indicator
```

### Data Validation
```
API Response
    ├─ Validate JSON structure
    ├─ Check required fields
    ├─ Type casting with defaults
    └─ Return model or null
    
Offline Storage
    ├─ User-broker link validation
    ├─ UUID format check
    ├─ Timestamp validation
    └─ Data consistency check
```

## Performance Optimizations

### 1. Image Caching
- CachedNetworkImage automatically caches
- Images stored in app cache directory
- Network calls skipped for cached images

### 2. Lazy Loading
- Pagination loads data on-demand
- Only ~6-10 items in memory at a time
- Scroll trigger at 500px from bottom

### 3. Provider Optimization
- Consumer rebuilds only specific widgets
- ChangeNotifier only notifies on state change
- No unnecessary provider creates

### 4. Database Performance
- Hive: In-memory + persistent storage
- O(1) lookups for user/bookmark
- No complex queries needed

### 5. Pagination
- API requests: page-by-page
- UI: append mode (no full reload)
- No duplicate data tracking

## Security Considerations

### Data Privacy
- ✓ No user credentials stored
- ✓ All data stored locally on device
- ✓ No external analytics
- ✓ No sensitive data in logs

### API Security
- ✓ HTTPS for all API calls
- ✓ No API keys in Flutter code (moved to request)
- ✓ Timeout protection
- ⚠️ OMDb API key visible (acceptable for demo)

### Local Storage Security
- ✓ Standard Hive encryption available
- ✓ App-specific storage directory
- ⚠️ No encryption implemented (add if needed)

## Testing Strategy

### Unit Tests (Recommended)
```
✓ Model serialization/deserialization
✓ Provider state transitions
✓ LocalStorage CRUD operations
✓ Extension functions
✓ Validation logic
```

### Widget Tests (Recommended)
```
✓ Screen rendering
✓ Button interactions
✓ Form validation
✓ Error display
✓ Loading indicators
```

### Integration Tests (Recommended)
```
✓ Complete offline flow
✓ API integration
✓ Sync functionality
✓ Navigation flow
```

### Manual Testing (Required)
```
✓ Network resilience (30% failure)
✓ Offline user creation
✓ Bookmark creation offline
✓ Auto-sync on reconnection
✓ Pagination edge cases
```

## Extensibility

### Adding New Features
1. Create new Model in `/models/`
2. Create new Provider in `/providers/`
3. Add service methods in `/services/`
4. Create new Screen in `/screens/`
5. Update navigation in screens

### Integrating Backend
1. Add endpoints to `ApiService`
2. Create new models for backend data
3. Update `SyncService` for syncing
4. Call sync from `ConnectivityProvider`

### Customizing UI
1. Modify `app_theme.dart` for colors
2. Update widgets in `/widgets/`
3. Adjust screen layouts
4. Add animations as needed

## Conclusion

This architecture provides:
- **Scalability**: Easy to add features
- **Maintainability**: Clear separation of concerns
- **Reliability**: Comprehensive error handling
- **Performance**: Optimized for mobile
- **Testability**: All components independently testable
- **Offline-First**: Works without internet

The design is production-ready and follows Flutter/Dart best practices.
