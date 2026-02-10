import 'package:Uniguide/features/dashboard/presentation/pages/bottom%20screen/application_page.dart';
import 'package:Uniguide/features/dashboard/presentation/pages/bottom%20screen/profile_page.dart';
import 'package:Uniguide/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  /// Helper to wrap the widget in a MaterialApp for navigation context
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: DashboardScreen(),
    );
  }

  group('DashboardScreen Widget Tests', () {

    testWidgets('Renders correctly and handles duplicate country text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify the AppBar title
      expect(find.text('Explore Courses'), findsOneWidget);

      // Verify the Search Field
      expect(find.byType(TextField), findsOneWidget);

      // Verify "USA" exists twice (once in Popular Destinations, once in University Card)
      expect(find.text('USA'), findsNWidgets(2));

      // Verify "UK" exists twice
      expect(find.text('UK'), findsNWidgets(2));

      // Verify the AI Button is present
      expect(find.text('Try our AI to find your course →'), findsOneWidget);
    });

    testWidgets('Tapping Application tab navigates to ApplicationPage', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // We look for the icon or label in your custom MyNavigationBar.
      // Since it's index 1, we tap it.
      // If MyNavigationBar uses standard BottomNavigationBar items:
      final applicationTab = find.byIcon(Icons.assignment); // Adjust icon if different

      // If the icon is hard to find, we can find by text "Application" if it exists
      // or use the index-based approach if you have access to the items.
      await tester.tap(find.text('Application').first);
      await tester.pumpAndSettle(); // Wait for navigation transition

      // Verify navigation result
      expect(find.byType(ApplicationPage), findsOneWidget);
    });

    testWidgets('Tapping Profile tab navigates to ProfilePage', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the Profile tab (index 2)
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();

      // Verify navigation result
      expect(find.byType(ProfilePage), findsOneWidget);
    });

  });
}