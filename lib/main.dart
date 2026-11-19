import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'providers/contract_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/document_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/service_visit_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/subscription_provider.dart';
import 'ui/navigation/app_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop & mobile
  AppDatabase.initializePlatform();

  // Initialize database
  final db = AppDatabase.instance;
  await db.database;

  // Check onboarding flag
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(AmcManagerApp(hasSeenOnboarding: hasSeenOnboarding));
}

class AmcManagerApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const AmcManagerApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()..loadCustomers()),
        ChangeNotifierProvider(create: (_) => ContractProvider()..loadContracts()),
        ChangeNotifierProvider(create: (_) => ServiceVisitProvider()..loadVisits()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..loadReminders()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()..loadDocuments()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..init()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProv, _) {
          return MaterialApp(
            title: 'AMC Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProv.themeMode,
            home: hasSeenOnboarding ? const AppShell() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
