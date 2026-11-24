import 'package:flutter/material.dart';

import 'wakelock_home_page.dart';
import 'wakelock_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WakelockApp());
}

class WakelockApp extends StatelessWidget {
  const WakelockApp({
    super.key,
    this.wakelockService = const WakelockPlusService(),
  });

  final WakelockService wakelockService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awake',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
      ),
      home: WakelockHomePage(wakelockService: wakelockService),
    );
  }
}
