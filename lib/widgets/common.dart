import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope nie otacza tego widżetu.');
    return scope!.notifier!;
  }
}

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.azure,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.azure.withValues(alpha: 0.45),
            blurRadius: size * 0.45,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Text(
        'ON',
        style: TextStyle(
          color: AppColors.abyss,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 16), action!],
      ],
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A4464), AppColors.card],
          stops: [0, 0.22],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.azure,
  });

  final String label;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      ChipTone.azure => (AppColors.azureSoft, AppColors.azure),
      ChipTone.green => (AppColors.greenSoft, AppColors.green),
      ChipTone.sand => (AppColors.sand, AppColors.sandInk),
      ChipTone.lilac => (AppColors.lilacSoft, AppColors.lilac),
      ChipTone.muted => (AppColors.deep, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum ChipTone { azure, green, sand, lilac, muted }

ChipTone toneForRank(String role) {
  return switch (role) {
    'prezes' => ChipTone.azure,
    'wspol' => ChipTone.lilac,
    _ => ChipTone.muted,
  };
}

ChipTone toneForStatus(String status) {
  return switch (status) {
    'Wydane' => ChipTone.green,
    'Wstrzymany' => ChipTone.muted,
    'Koncept' => ChipTone.sand,
    'Polish' => ChipTone.lilac,
    _ => ChipTone.azure,
  };
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String formatDay(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null) {
    return '';
  }
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 5 || hour >= 18) {
    return 'Dobry wieczór';
  }
  return 'Dzień dobry';
}

void showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          tooltip: _hidden ? 'Pokaż hasło' : 'Ukryj hasło',
        ),
      ),
    );
  }
}
