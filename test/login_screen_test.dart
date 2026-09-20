import 'package:agrocontrol/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login exposes primary auth actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('authSubmitButton')), findsOneWidget);
    expect(find.byKey(const Key('forgotButton')), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('switches between login and registration', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('switchAuthModeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nameField')), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('switchAuthModeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nameField')), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('password visibility button responds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('togglePassword')));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
