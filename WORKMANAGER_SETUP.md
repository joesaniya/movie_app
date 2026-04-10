# WorkManager Setup Guide

## Current Status
The app is now running with **foreground sync fallback**. This means:
- ✅ Offline data is stored in Hive
- ✅ When device goes online, sync starts automatically
- ✅ Sync happens while app is running (foreground)
- ⚠️ Background sync (when app is closed) requires native setup

## Option 1: Using Foreground Sync (Works Now - No Setup Needed)
The app will automatically sync offline data whenever:
1. Device transitions from offline → online
2. App is in foreground
3. User returns to app after going online

This is sufficient for most use cases and **requires no additional setup**.

## Option 2: Complete Native Setup for Background Sync

If you want background sync (syncing even when app is closed), follow these steps:

### Android Setup

1. **Update `android/app/build.gradle`:**
   ```gradle
   android {
       // ... existing config ...
       compileSdkVersion 34  // or higher
       
       defaultConfig {
           // ... existing config ...
           minSdkVersion 21  // WorkManager requires min 21
       }
   }
   ```

2. **Add to `android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <manifest xmlns:android="http://schemas.android.com/apk/res/android">
       <!-- ... existing permissions ... -->
       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
       <uses-permission android:name="android.permission.WAKE_LOCK" />
       <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
       
       <application>
           <!-- ... existing config ... -->
       </application>
   </manifest>
   ```

3. **Run the following commands:**
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Rebuild the app:**
   ```bash
   flutter run --release
   ```

### iOS Setup

1. **Update `ios/Podfile`:**
   ```ruby
   platform :ios, '12.0'  # WorkManager requires iOS 12.0+
   
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
     end
   end
   ```

2. **Run:**
   ```bash
   cd ios
   pod install
   cd ..
   flutter clean
   flutter pub get
   flutter run --release
   ```

## Testing

### Test Foreground Sync (Works Now)
```
1. Go offline (disable WiFi/mobile data)
2. Add a new user
   → User appears with orange "local" badge ✓
3. Re-enable WiFi/mobile data
   → App automatically syncs
   → Orange badge disappears ✓
4. Check logs - should see "Foreground sync completed successfully"
```

### Test Background Sync (After Native Setup)
```
1. Go offline
2. Add a new user
3. Re-enable network
4. Force close the app
5. Wait 5-10 seconds
   → WorkManager executes sync task in background
6. Reopen app
   → User is synced (no orange badge)
```

## Troubleshooting

### Error: "No implementation found for method initialize"
**Solution:** This is expected if you haven't completed native setup. The app will use foreground sync instead.

### Sync not happening when device goes online
**Solution:** 
- Check that app has internet permission in manifest
- Verify connectivity is actually detected (check online indicator in app)
- Try reconnecting network manually
- Check logs for error messages

### Logs show "WorkManager not available"
**Solution:** This is normal. The app will use foreground sync. If you want background sync, complete the native setup above.

## Dependencies
- **workmanager: ^0.5.2** - Already in `pubspec.yaml`

## Architecture Benefits

✅ **Graceful fallback** - Works even without WorkManager
✅ **Foreground sync** - Syncs when user opens app after going online
✅ **Automatic retry** - Tries background, falls back to foreground
✅ **No crashes** - Handles missing native implementation gracefully
✅ **Future-proof** - Can enable background sync anytime with native setup

## Summary

**Right now:** App syncs offline data automatically when device goes online (foreground sync) ✅

**Optional:** Complete native setup above to enable background sync
