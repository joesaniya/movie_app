import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/movie_detail_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/user_list_screen.dart';
import 'services/service_locator.dart';
import 'services/background_sync_service.dart';
import 'utils/animation_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  _setupLogging();

  // Initialize WorkManager before service locator
  // This must happen before any async operations that might trigger sync
  await BackgroundSyncService.initialize();

  await setupServiceLocator();

  // Register periodic sync task (15 minute intervals when device is connected)
  await BackgroundSyncService.registerPeriodicSync();

  runApp(const MovieTaskApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });
}

class MovieTaskApp extends StatelessWidget {
  const MovieTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PaginatedUsersProvider()),
        ChangeNotifierProvider(create: (_) => PaginatedMoviesProvider()),
        ChangeNotifierProvider(create: (_) => MovieDetailProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: MaterialApp(
        title: 'Movie Task',
        theme: AppTheme.theme,
        home: const UserListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
