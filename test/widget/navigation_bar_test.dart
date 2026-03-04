import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Uniguide/common/navigation_bar.dart';

void main() {
  Widget _wrapNav({int currentIndex = 0, void Function(int)? onTap}) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: MyNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          savedIds: const ['1', '2'],
          allUniversities: const [],
        ),
      ),
    );
  }

  group('MyNavigationBar', () {
    testWidgets('renders three navigation items', (tester) async {
      await tester.pumpWidget(_wrapNav());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('uses provided currentIndex', (tester) async {
      await tester.pumpWidget(_wrapNav(currentIndex: 1));

      final bar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.currentIndex, 1);
    });

    testWidgets('invokes onTap callback when item tapped', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(_wrapNav(onTap: (i) => tappedIndex = i));

      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(tappedIndex, 2);
    });
  });
}
