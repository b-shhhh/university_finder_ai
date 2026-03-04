import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Uniguide/features/dashboard/presentation/widgets/country_widget.dart';
import 'package:Uniguide/features/dashboard/presentation/widgets/course_widget.dart';

void main() {
  group('CountryCard', () {
    testWidgets('shows name and university count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountryCard(name: 'Nepal', universityCount: 12),
          ),
        ),
      );

      expect(find.text('Nepal'), findsOneWidget);
      expect(find.text('12 universities'), findsOneWidget);
    });

    testWidgets('uses fallback avatar when flagUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountryCard(name: 'India', universityCount: 8, flagUrl: null),
          ),
        ),
      );

      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryCard(
              name: 'USA',
              universityCount: 20,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CountryCard));
      expect(tapped, isTrue);
    });
  });

  group('CourseCard', () {
    testWidgets('shows course name and count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseCard(name: 'Computer Science', universityCount: 30),
          ),
        ),
      );

      expect(find.text('Computer Science'), findsOneWidget);
      expect(find.text('30 universities'), findsOneWidget);
    });

    testWidgets('default tap opens bottom sheet with countries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseCard(
              name: 'Business',
              universityCount: 10,
              countries: ['France', 'Spain'],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();

      expect(find.text('France'), findsOneWidget);
      expect(find.text('Spain'), findsOneWidget);
    });

    testWidgets('countries are shown sorted alphabetically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseCard(
              name: 'Design',
              universityCount: 5,
              countries: ['Germany', 'Canada', 'Brazil'],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles.first.title, isA<Text>());
      final firstTitle = tiles.first.title as Text;
      expect(firstTitle.data, 'Brazil'); // alphabetically first
    });

    testWidgets('tapping a country triggers onCountryTap', (tester) async {
      String? tappedCountry;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              name: 'Engineering',
              universityCount: 15,
              countries: ['UK', 'Japan'],
              onCountryTap: (c) => tappedCountry = c,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Japan'));
      await tester.pumpAndSettle();

      expect(tappedCountry, 'Japan');
    });

    testWidgets('empty countries does not open bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourseCard(name: 'Law', universityCount: 3, countries: []),
          ),
        ),
      );

      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('custom onTap overrides default bottom sheet', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              name: 'Medicine',
              universityCount: 9,
              countries: ['Italy'],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CourseCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.text('Italy'), findsNothing); // bottom sheet not shown
    });
  });
}
