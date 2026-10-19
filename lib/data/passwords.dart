import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String createSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}

String? validateName(String value) {
  if (value.trim().length < 2) {
    return 'Podaj imię (co najmniej 2 znaki).';
  }
  return null;
}

String? validateEmail(String value) {
  final email = value.trim().toLowerCase();
  if (email.isEmpty) {
    return 'Podaj adres e-mail.';
  }
  if (!emailPattern.hasMatch(email)) {
    return 'Ten adres e-mail wygląda niepoprawnie.';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.length < 6) {
    return 'Hasło musi mieć co najmniej 6 znaków.';
  }
  return null;
}

String normalizeEmail(String value) => value.trim().toLowerCase();
