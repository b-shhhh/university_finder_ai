import 'package:Uniguide/features/auth/presentation/pages/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegisterScreen Widget Test', () {
    testWidgets('All input fields, dropdown, and buttons exist', (WidgetTester tester) async {
      // Wrap the screen in MaterialApp for routing
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
        ),
      );

      // Let all widgets settle
      await tester.pumpAndSettle();

      // Find all text fields
      final firstNameField = find.byType(TextFormField).at(0);
      final lastNameField = find.byType(TextFormField).at(1);
      final emailField = find.byType(TextFormField).at(2);
      final passwordField = find.byType(TextFormField).at(3);
      final confirmPasswordField = find.byType(TextFormField).at(4);
      final phoneField = find.byType(TextFormField).at(5);

      // Dropdown
      final educationDropdown = find.byType(DropdownButtonFormField<String>);

      // Buttons
      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      final loginTextButton = find.byType(TextButton);

      // Assertions
      expect(firstNameField, findsOneWidget);
      expect(lastNameField, findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(confirmPasswordField, findsOneWidget);
      expect(phoneField, findsOneWidget);
      expect(educationDropdown, findsOneWidget);
      expect(registerButton, findsOneWidget);
      expect(loginTextButton, findsOneWidget);
    });

    testWidgets('Dropdown can be selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final educationDropdown = find.byType(DropdownButtonFormField<String>);

      // Scroll into view
      await tester.ensureVisible(educationDropdown);

      // Tap dropdown to open menu
      await tester.tap(educationDropdown);
      await tester.pumpAndSettle();

      // Select "Bachelors"
      await tester.tap(find.text('Bachelors').last);
      await tester.pumpAndSettle();

      // Verify selection
      final selected = find.text('Bachelors').last;
      expect(selected, findsOneWidget);
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
