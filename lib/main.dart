import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'routes/app_router.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/notification/background_worker.dart';
import 'core/services/notification/deep_link_handler.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize(
    onNotificationTapped: _handleNotificationTap,
  );

  // Initialize background worker (only on Mobile platforms)
  // workmanager is not supported on web
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundWorker.initialize(debugMode: false);

    // Schedule background tasks
    await BackgroundWorker.scheduleCheckExpiredItems();
    await BackgroundWorker.schedulePantrySyncTask();
  }

  runApp(const FridgeToForkApp());
}

/// Handle notification tap and perform smart deep linking
Future<void> _handleNotificationTap(String? payload) async {
  debugPrint('Notification tapped with payload: $payload');

  if (payload == null) return;

  // Parse the payload using DeepLinkHandler for intelligent routing
  appRouter.goWithDeepLink(payload);
}

class FridgeToForkApp extends StatelessWidget {
  const FridgeToForkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fridge to Fork Assistant',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
      debugShowCheckedModeBanner: false,
    );
  }
}
