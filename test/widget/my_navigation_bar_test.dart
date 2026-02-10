import 'package:Uniguide/common/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyNavigationBar displays items and responds to taps', (WidgetTester tester) async {
    int tappedIndex = -1;

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(),
          bottomNavigationBar: MyNavigationBar(
            currentIndex: 0,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    // Check if all three items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // The first item should be selected (currentIndex = 0)
    BottomNavigationBar bottomNav = tester.widget(find.byType(BottomNavigationBar));
    expect(bottomNav.currentIndex, 0);

    // Tap on the second item
    await tester.tap(find.text('Application'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 1);

    // Tap on the third item
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 2);

    // Tap back on the first item
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 0);
  });
}
