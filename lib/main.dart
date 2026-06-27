import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';

import 'core/theme/app_theme.dart';
import 'core/services/audio_handler.dart';
import 'providers/app_providers.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized before interacting with native OS channels
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize local storage for instant offline access
  await Hive.initFlutter();
  await Hive.openBox('settings_box');
  await Hive.openBox('history_box');
  await Hive.openBox('favorites_box');

  // 3. Initialize the background audio service
  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quran.offline.audio',
      androidNotificationChannelName: 'Qur\'an Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // 4. Run the app, injecting the initialized audio handler globally
  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const OfflineQuranApp(),
    ),
  );
}

class OfflineQuranApp extends ConsumerWidget {
  const OfflineQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider we just created!
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Offline Qur\'an Audio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Now it dynamically updates when toggled
      home: const SplashScreen(),
    );
  }
}
