# Offline Sync Implementation

## Overview
The app now implements automatic background syncing of offline data when the device regains internet connectivity using WorkManager.

## Components

### 1. **BackgroundSyncService** (`lib/services/background_sync_service.dart`)
- Initializes and manages WorkManager tasks
- Provides methods to:
  - `initialize()`: Set up WorkManager
  - `registerPeriodicSync()`: Schedule periodic sync (every 15 minutes when connected)
  - `scheduleImmediateSync()`: Trigger immediate sync when going online
  - `cancelAllSyncTasks()`: Cancel all pending sync tasks

### 2. **ConnectivityProvider** (`lib/providers/connectivity_provider.dart`)
- Monitors device connectivity status in real-time
- Detects when device transitions from offline → online
- Automatically triggers background sync when going online
- Tracks state to avoid duplicate notifications

### 3. **SyncService** (`lib/services/sync_service.dart`)
- Executes the background sync task
- Syncs unsynced users and bookmarks with the API
- Updates local database with API-returned IDs
- Marks synced data as `isSynced: true` in Hive

### 4. **LocalStorageService** (`lib/services/local_storage_service.dart`)
- Provides `createSyncedUser()` for saving users with API ID
- Provides `updateUserSyncStatus()` to update local records after sync
- Tracks sync status for all offline data

## Data Flow

### Creating a User Offline
```
User Creates Account (Device is Offline)
  ↓
Saved to Hive with isSynced: false
  ↓
User shown with orange "local" badge in list
  ↓
Device goes Online
  ↓
ConnectivityProvider detects transition
  ↓
Triggers BackgroundSyncService.scheduleImmediateSync()
  ↓
WorkManager executes sync task
  ↓
SyncService calls API to create user
  ↓
API returns user ID
  ↓
SyncService updates local Hive: isSynced: true, apiId: <ID>
  ↓
User now appears without "local" badge (synced!)
```

### Creating a User Online
```
User Creates Account (Device is Online)
  ↓
API call: POST /users → returns ID
  ↓
User saved to Hive with isSynced: true, apiId: <ID>
  ↓
User appears in list with proper ID (online user)
```

## WorkManager Configuration

### Android Setup
WorkManager is automatically handled by the package. No additional setup needed.

### iOS Setup
WorkManager uses BGTaskScheduler on iOS 13+. No additional setup needed.

## Key Features

✅ **Automatic Sync** — No manual intervention needed
✅ **Reliable** — Uses exponential backoff for retry logic
✅ **Efficient** — Only syncs unsynced data
✅ **Persistent** — Uses Hive for reliable local storage
✅ **Real-time** — Detects connectivity changes instantly
✅ **Background** — Syncs even when app is not in foreground
✅ **Smart Scheduling** — Periodic (15min) + immediate sync when online

## Testing

To test offline sync:

1. **Create user while offline:**
   - Disable network in device settings
   - Create a new user
   - User appears with orange "local" badge

2. **Enable network:**
   - Re-enable network
   - App automatically triggers sync
   - Orange badge disappears after successful sync
   - Logs show "User synced successfully"

3. **Verify persistent storage:**
   - Create offline user
   - Force close app
   - Reopen app
   - Offline user still visible
   - Sync when online

## Logging

Enable logging to track sync process:
```
[INFO] BackgroundSyncService: WorkManager initialized
[INFO] SyncService: Starting offline data sync
[INFO] SyncService: Syncing user: John Doe
[INFO] SyncService: User synced successfully: John Doe -> 291
[INFO] SyncService: Offline data sync completed successfully
```

## Dependencies Added

- `workmanager: ^0.5.2` — Background task scheduling

## Architecture Benefits

✅ Clean separation of concerns
✅ Reactive programming with listeners
✅ Offline-first approach
✅ Automatic recovery
✅ No data loss
✅ Seamless user experience
