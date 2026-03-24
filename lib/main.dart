import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/pantry/views/pantry_screen.dart';

void main() {
	runApp(const MyApp());
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
