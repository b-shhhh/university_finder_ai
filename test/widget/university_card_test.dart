import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Uniguide/features/dashboard/presentation/widgets/university_widget.dart';

void main() {
  group('UniversityCard', () {
    testWidgets('returns nothing when name is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': '', 'country': 'USA'},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('returns nothing when name equals country', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': 'France', 'country': 'France'},
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('shows university name and country', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': 'MIT', 'country': 'USA'},
            ),
          ),
        ),
      );

      expect(find.text('MIT'), findsOneWidget);
      expect(find.text('USA'), findsOneWidget);
    });

    testWidgets('shows filled heart when saved', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              isSaved: true,
              university: {'name': 'MIT', 'country': 'USA'},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows outline heart when not saved', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              isSaved: false,
              university: {'name': 'MIT', 'country': 'USA'},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('invokes onSave when heart tapped', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': 'Stanford', 'country': 'USA'},
              onSave: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(toggled, isTrue);
    });

    testWidgets('omits website button when url missing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': 'Oxford', 'country': 'UK', 'website_url': ''},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.language), findsNothing);
    });

    testWidgets('shows placeholder avatar when logo missing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UniversityCard(
              university: {'name': 'Harvard', 'country': 'USA'},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byIcon(Icons.school),
        ),
        findsOneWidget,
      );
    });
  });
}
