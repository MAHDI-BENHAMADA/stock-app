import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: StockApp(),
    ),
  );
}

class StockApp extends ConsumerWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Stock App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Defaulting to dark theme for premium feel
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
