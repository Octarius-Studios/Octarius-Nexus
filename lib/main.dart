import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screens.dart';
import 'screens/home_shell.dart';
import 'sqlite_setup.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureSqlite();
  final state = AppState();
  state.boot();
  runApp(OctariusApp(state: state));
}

class OctariusApp extends StatelessWidget {
  const OctariusApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Octarius Nexus',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        home: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            final error = state.bootError;
            if (error != null) {
              return BootErrorScreen(message: error);
            }
            if (state.currentUser != null) {
              if (!state.currentUser!.isActive) {
                return const WaitingScreen();
              }
              return const HomeShell();
            }
            if (!state.hasUsers) {
              return const SetupScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class BootErrorScreen extends StatelessWidget {
  const BootErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoMark(),
                const SizedBox(height: 20),
                const Text(
                  'Octarius Nexus nie wstał',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
