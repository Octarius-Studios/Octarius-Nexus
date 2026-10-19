import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/passwords.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeated = TextEditingController();
  var _validate = AutovalidateMode.disabled;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeated.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _validate = AutovalidateMode.onUserInteraction);
      return;
    }
    final error = AppScope.of(context).registerPresident(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      repeatedPassword: _repeated.text,
    );
    if (error != null) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Form(
        key: _formKey,
        autovalidateMode: _validate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pierwsze uruchomienie',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.azureDeep,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Załóż konto prezesa',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.ice,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To pierwsze konto w studiu. Dostajesz rangę prezesa i potem nadajesz rangi innym.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Imię'),
              validator: (value) => validateName(value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => validateEmail(value ?? ''),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _password,
              label: 'Hasło',
              textInputAction: TextInputAction.next,
              validator: (value) => validatePassword(value ?? ''),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _repeated,
              label: 'Powtórz hasło',
              textInputAction: TextInputAction.done,
              validator: (value) {
                if ((value ?? '') != _password.text) {
                  return 'Hasła nie są takie same.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(onPressed: _submit, child: const Text('Utwórz konto')),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final error = AppScope.of(context)
        .login(email: _email.text, password: _password.text);
    if (error != null) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Witaj z powrotem',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.azureDeep,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Zaloguj się',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.ice,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wpisz e-mail i hasło albo załóż własne konto.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => validateEmail(value ?? ''),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _password,
              label: 'Hasło',
              textInputAction: TextInputAction.done,
              validator: (value) => validatePassword(value ?? ''),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(onPressed: _submit, child: const Text('Zaloguj się')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const JoinScreen()),
                );
              },
              child: const Text('Nie masz konta? Załóż je'),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeated = TextEditingController();
  var _validate = AutovalidateMode.disabled;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeated.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _validate = AutovalidateMode.onUserInteraction);
      return;
    }
    final error = AppScope.of(context).registerMember(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      repeatedPassword: _repeated.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seats = maxTeamSize - AppScope.of(context).activeUsers.length;
    return AuthFrame(
      child: Form(
        key: _formKey,
        autovalidateMode: _validate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nowe konto',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.azure,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dołącz do studia',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.ice,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              seats > 0
                  ? 'Konto dostaje rangę pracownika i czeka na potwierdzenie prezesa albo współwłaściciela. Wolnych miejsc: $seats.'
                  : 'Zespół jest pełny. Mieści się w nim 5 osób.',
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Imię'),
              validator: (value) => validateName(value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) => validateEmail(value ?? ''),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _password,
              label: 'Hasło',
              textInputAction: TextInputAction.next,
              validator: (value) => validatePassword(value ?? ''),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _repeated,
              label: 'Powtórz hasło',
              textInputAction: TextInputAction.done,
              validator: (value) {
                if ((value ?? '') != _password.text) {
                  return 'Hasła nie są takie same.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: seats > 0 ? _submit : null,
              child: const Text('Utwórz konto'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mam już konto'),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.8),
            radius: 1.3,
            colors: [Color(0xFF14506E), AppColors.abyss, Color(0xFF08111C)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azure.withValues(alpha: 0.18),
                      blurRadius: 48,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoMark(size: 64)),
                      const SizedBox(height: 16),
                      const Text(
                        'Octarius Nexus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ice,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Studio gier i aplikacji',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser;
    return AuthFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Czeka na potwierdzenie',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ice,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${user?.name ?? 'Konto'} jest zapisane jako pracownik. Wejście do panelu odblokuje prezes albo współwłaściciel.',
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () => AppScope.of(context).logout(),
            child: const Text('Wyloguj'),
          ),
        ],
      ),
    );
  }
}
