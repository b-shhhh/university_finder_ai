import 'package:Uniguide/core/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyButton displays text and reacts to tap', (WidgetTester tester) async {
    bool tapped = false;

    // Build the widget inside a MaterialApp
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyButton(
            text: 'Click Me',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Verify the button shows the correct text
    expect(find.text('Click Me'), findsOneWidget);

    // Tap the button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify the tap callback was called
    expect(tapped, isTrue);
  });
}
