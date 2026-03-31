import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'features/pantry/models/pantry_item_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/notification/background_worker.dart';
import 'core/services/notification/expiry_notification_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  await NotificationService().initialize();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundWorker.initialize(debugMode: false);
    await BackgroundWorker.scheduleCheckExpiredItems();
    await BackgroundWorker.schedulePantrySyncTask();
  }

  await ExpiryNotificationService.checkAndNotifyExpiringItems();

  runApp(const MyApp());
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PantryItemModelAdapter());
  }
  await Hive.openBox<PantryItemModel>('pantry_items');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bếp Trợ Lý',
      theme: ThemeData(primarySwatch: Colors.green),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('vi', 'VN'), const Locale('en', 'US')],
    );
  }
}
