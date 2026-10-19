import 'package:flutter/material.dart';

import '../data/passwords.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeated = TextEditingController();
  String? _error;
  String? _success;
  String? _nameMessage;
  var _nameReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameReady) {
      return;
    }
    _nameReady = true;
    _name.text = AppScope.of(context).currentUser?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _next.dispose();
    _repeated.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _error = null;
      _success = null;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final error = AppScope.of(context).changePassword(
      current: _current.text,
      next: _next.text,
      repeated: _repeated.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _current.clear();
    _next.clear();
    _repeated.clear();
    setState(() => _success = 'Hasło zostało zmienione.');
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser!;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeader(
          title: 'Konto',
          subtitle: 'Imię, ranga i hasło. E-mail zostaje loginem.',
        ),
        const SizedBox(height: 20),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 6),
              Text(
                'W studiu od ${formatDay(user.createdAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              StatusChip(label: user.roleLabel, tone: toneForRank(user.role)),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Imię'),
              ),
              if (_nameMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _nameMessage!,
                  style: TextStyle(
                    color: _nameMessage == 'Imię zostało zmienione.'
                        ? AppColors.green
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final error = AppScope.of(context).changeName(_name.text);
                  setState(() {
                    _nameMessage = error ?? 'Imię zostało zmienione.';
                  });
                },
                child: const Text('Zapisz imię'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Zmiana hasła',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _current,
                  label: 'Obecne hasło',
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Podaj obecne hasło.' : null,
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _next,
                  label: 'Nowe hasło',
                  validator: (value) => validatePassword(value ?? ''),
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _repeated,
                  label: 'Powtórz nowe hasło',
                  validator: (value) {
                    if ((value ?? '') != _next.text) {
                      return 'Nowe hasła nie są takie same.';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Hasło zostało zmienione.',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Zapisz hasło'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => AppScope.of(context).logout(),
            child: const Text('Wyloguj'),
          ),
        ),
      ],
    );
  }
}
