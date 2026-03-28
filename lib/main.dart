import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/pantry/views/pantry_screen.dart';
import 'features/pantry/view_models/pantry_view_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PantryViewModel(),
      child: const MyApp(),
    ),
  );
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
