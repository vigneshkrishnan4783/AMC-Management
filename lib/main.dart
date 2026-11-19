import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'providers/contract_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/document_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/service_visit_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/navigation/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop & mobile
  AppDatabase.initializePlatform();

  // Initialize database & load pre-seeded data if any
  final db = AppDatabase.instance;
  await db.database;

  runApp(const AmcManagerApp());
}

class AmcManagerApp extends StatelessWidget {
  const AmcManagerApp({super.key});

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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProv, _) {
          return MaterialApp(
            title: 'AMC Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProv.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
