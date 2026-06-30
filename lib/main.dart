import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'data/services/background_tracker_service.dart';
import 'presentation/dashboard/screen/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTrackerService.initializeService();
  runApp(const PremiumTrackerApp());
}

class PremiumTrackerApp extends StatelessWidget {
  const PremiumTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.slate900,
        colorSchemeSeed: const Color(0xFF10B981),
      ),
      home: const DashboardScreen(),
    );
  }
}