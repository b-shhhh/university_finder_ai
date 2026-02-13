import 'package:Uniguide/features/auth/presentation/pages/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterScreen Widget Test', () {
    testWidgets('All input fields and buttons exist', (WidgetTester tester) async {
      // Wrap the screen in MaterialApp for routing
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
        ),
      );

      // Let all widgets settle
      await tester.pumpAndSettle();

      // Find all text fields
      final fullNameField = find.byType(TextFormField).at(0);
      final emailField = find.byType(TextFormField).at(1);
      final passwordField = find.byType(TextFormField).at(2);
      final confirmPasswordField = find.byType(TextFormField).at(3);
      final phoneField = find.byType(TextFormField).at(4);

      // Buttons
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      final loginTextButton = find.byType(TextButton);

      // Assertions
      expect(fullNameField, findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(confirmPasswordField, findsOneWidget);
      expect(phoneField, findsOneWidget);
      expect(registerButton, findsOneWidget);
      expect(loginTextButton, findsOneWidget);
    });

    testWidgets('Register button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final registerButton = find.widgetWithText(ElevatedButton, 'Register');

      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Since API call fails in test, we just check button exists and is tappable
      expect(registerButton, findsOneWidget);
    });

    testWidgets('Login TextButton is tappable and navigates', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Page')),
          },
          home: const RegisterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final loginTextButton = find.byType(TextButton);
      await tester.ensureVisible(loginTextButton);

      // Tap the Login button
      await tester.tap(loginTextButton);
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}

