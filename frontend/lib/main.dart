import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/evaluator/presentation/evaluator_page.dart';
import 'features/comparator/presentation/comparator_page.dart';
import 'features/probability/presentation/probability_page.dart';
import 'features/health/presentation/health_page.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/api_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ApiProvider()),
      ],
      child: const PokerEvalApp(),
    ),
  );
}

class PokerEvalApp extends StatelessWidget {
  const PokerEvalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'PokerEval – Texas Hold\'em Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(ThemeData.light().textTheme),
      darkTheme: AppTheme.darkTheme(ThemeData.dark().textTheme),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (_) => const DashboardPage(),
        '/evaluate': (_) => const EvaluatorPage(),
        '/compare': (_) => const ComparatorPage(),
        '/probability': (_) => const ProbabilityPage(),
        '/health': (_) => const HealthPage(),
      },
    );
  }
}
