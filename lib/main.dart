import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/pantry/models/pantry_item_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/pantry/views/pantry_screen.dart';
import 'features/pantry/view_models/pantry_view_model.dart';

void main() {
	WidgetsFlutterBinding.ensureInitialized();
	_initHive().then((_) {
		runApp(
			ChangeNotifierProvider(
				create: (_) => PantryViewModel(),
				child: const MyApp(),
			),
		);
	});
}

Future<void> _initHive() async {
	await Hive.initFlutter();
	Hive.registerAdapter(PantryItemModelAdapter());
	await Hive.openBox<PantryItemModel>('pantry_items');
}

class MyApp extends StatelessWidget {
	const MyApp({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Bếp Trợ Lý',
			theme: ThemeData(
				primarySwatch: Colors.green,
			),
			home: const PantryScreen(),
			debugShowCheckedModeBanner: false,
			localizationsDelegates: [
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate,
				GlobalCupertinoLocalizations.delegate,
			],
			supportedLocales: [
				const Locale('vi', 'VN'),
				const Locale('en', 'US'),
			],
		);
	}
}
