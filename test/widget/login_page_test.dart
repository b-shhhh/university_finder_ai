import 'package:Uniguide/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen shows email, password fields and login button',
            (WidgetTester tester) async {
          // Render the LoginScreen
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          // Find email field by hint text
          final emailField = find.widgetWithText(TextFormField, 'Email Address');
          expect(emailField, findsOneWidget);

          // Find password field by hint text
          final passwordField = find.widgetWithText(TextFormField, 'Password');
          expect(passwordField, findsOneWidget);

          // Find login button by text
          final loginButton = find.widgetWithText(ElevatedButton, 'Login');
          expect(loginButton, findsOneWidget);

          // Optional: type into fields
          await tester.enterText(emailField, 'test@example.com');
          await tester.enterText(passwordField, '123456');

          // Tap the login button
          await tester.tap(loginButton);
          await tester.pump(); // pump once to process tap
        });

    testWidgets('LoginScreen navigates to Register page',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              routes: {
                '/register': (context) =>
                const Scaffold(body: Center(child: Text('Register Page'))),
              },
              home: const LoginScreen(),
            ),
          );

          // Find all TextButtons
          final textButtons = find.byType(TextButton);
          expect(textButtons, findsWidgets);

          // Tap the Register button (the second TextButton, first is 'Forgot password?')
          await tester.tap(textButtons.at(1));
          await tester.pumpAndSettle();

          // Verify navigation
          expect(find.text('Register Page'), findsOneWidget);
        });

    testWidgets('LoginScreen has Forgot password button',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          final forgotButton = find.widgetWithText(TextButton, 'Forgot password?');
          expect(forgotButton, findsOneWidget);
        });

    testWidgets('LoginScreen toggles password visibility',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          // Find the password field
          final passwordField = find.widgetWithText(TextFormField, 'Password');
          expect(passwordField, findsOneWidget);

          // Find the visibility toggle icon button
          final toggleButton = find.byIcon(Icons.visibility_outlined);
          expect(toggleButton, findsOneWidget);

          // Tap to toggle visibility
          await tester.tap(toggleButton);
          await tester.pump();

          // Icon should change to visibility_off_outlined
          expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
        });
  });
}
