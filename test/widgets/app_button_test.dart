import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/widgets/app_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders its label', (tester) async {
    await tester.pumpWidget(wrap(AppButton(label: 'Continue', onPressed: () {})));
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(AppButton(label: 'Tap me', onPressed: () => tapped = true)));

    await tester.tap(find.text('Tap me'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('shows a spinner instead of the label while loading', (tester) async {
    await tester.pumpWidget(wrap(AppButton(label: 'Save', onPressed: () {}, isLoading: true)));

    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('is disabled (no tap effect) when onPressed is null', (tester) async {
    await tester.pumpWidget(wrap(const AppButton(label: 'Disabled', onPressed: null)));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
