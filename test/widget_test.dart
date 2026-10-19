import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octarius_nexus/data/passwords.dart';
import 'package:octarius_nexus/widgets/common.dart';

void main() {
  testWidgets('znak studia pokazuje ON', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LogoMark())),
    );
    expect(find.text('ON'), findsOneWidget);
  });

  test('e-mail i hasło mają proste reguły', () {
    expect(validateEmail('prezes@octarius.test'), isNull);
    expect(validateEmail('zle'), isNotNull);
    expect(validatePassword('krotk'), isNotNull);
    expect(validatePassword('haslo123'), isNull);
  });
}
