import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/scanner/scanner_service.dart';
import 'core/theme/app_theme.dart';
import 'features/pantry/views/receipt_scanner_screen.dart';

void main() {
  runApp(const BepTroLyApp());
}

class BepTroLyApp extends StatelessWidget {
  const BepTroLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ScannerService>(create: (_) => ScannerService()),
        // Team members 1,2,3,4 can register their providers here.
      ],
      child: MaterialApp(
        title: 'Bếp Trợ Lý',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ReceiptScannerScreen(),
      ),
    );
  }
}
