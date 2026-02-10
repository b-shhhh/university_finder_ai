import 'package:Uniguide/app/theme/theme_data.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/register_screen.dart';
import '../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../features/onboarding/presentation/page/onboarding_screen.dart';
import '../features/splash/presentation/page/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniGuide',
      debugShowCheckedModeBanner: false,
      theme: getApplicationTheme(),
      // darkTheme: getDarkTheme(), // only if you define it
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => OnboardingScreen(), // remove const if constructor not const
        '/login': (_) => LoginScreen(),
        '/register': (_) => RegisterScreen(),
        '/dashboard': (_) => DashboardScreen(),
      },
    );
  }
}