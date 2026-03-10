import 'package:flutter/material.dart';

import 'app_state.dart';
import '../features/auth/auth_flow.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

class RiderApp extends StatefulWidget {
  const RiderApp({super.key});

  @override
  State<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends State<RiderApp> {
  late final AppState _state;
  late final Future<void> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _state = AppState();
    _restoreFuture = _state.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _state,
      child: FutureBuilder<void>(
        future: _restoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return MaterialApp(
              title: 'Rider',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final appState = AppStateScope.of(context);
          return MaterialApp(
            title: 'Rider',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: appState.isLoggedIn ? const _HomeGate() : const AuthFlow(),
            routes: {
              '/auth': (_) => const AuthFlow(),
              '/onboarding': (_) => const OnboardingFlow(),
              '/under-review': (_) => const ApplicationReviewScreen(),
              '/home': (_) => const _HomeGate(),
            },
          );
        },
      ),
    );
  }
}

class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (!state.isLoggedIn) return const AuthFlow();
    if (state.rider.verification != VerificationStatus.verified) {
      return const ApplicationReviewScreen();
    }
    if (!state.isOnboardingComplete) return const OnboardingFlow();
    return const HomeShell();
  }
}
