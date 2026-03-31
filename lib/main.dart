import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'features/pantry/models/pantry_item_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/notification/background_worker.dart';
import 'core/services/notification/expiry_notification_service.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/auth/auth_repository.dart';
import 'features/auth/view_models/auth_view_model.dart';
import 'routes/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    _initHive(),
  ]);
  await NotificationService().initialize();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundWorker.initialize(debugMode: false);
    await BackgroundWorker.scheduleCheckExpiredItems();
    await BackgroundWorker.schedulePantrySyncTask();
  }

  await ExpiryNotificationService.checkAndNotifyExpiringItems();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ProxyProvider<AuthService, AuthRepository>(
          create: (context) =>
              AuthRepository(authService: context.read<AuthService>()),
          update: (context, authService, previous) =>
              AuthRepository(authService: authService),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            authRepository: context.read<AuthRepository>(),
          ),
          update: (context, authRepository, previous) => AuthViewModel(
            authService: context.read<AuthService>(),
            authRepository: authRepository,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
