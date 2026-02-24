import 'package:flutter/material.dart';

import 'app_state.dart';
import '../features/auth/auth_flow.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AppStateScope(
      notifier: state,
      child: Builder(
        builder: (context) {
          final appState = AppStateScope.of(context);
          return MaterialApp(
            title: 'Rider',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            initialRoute: appState.isLoggedIn ? '/home' : '/auth',
            routes: {
              '/auth': (_) => const AuthFlow(),
              '/onboarding': (_) => const OnboardingFlow(),
              '/home': (_) => const HomeShell(),
            },
          );
        },
      ),
    );
  }
}
