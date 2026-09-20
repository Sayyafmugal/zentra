import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/widgets/app_text_field.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Form(child: child)),
  );

  testWidgets('shows the validator error when the form is validated', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextField(
              controller: controller,
              label: 'Email',
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('obscures text by default when obscureText is true, and toggles visibility', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'secret');

    await tester.pumpWidget(wrap(AppTextField(controller: controller, obscureText: true)));

    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
  });

  testWidgets('typing updates the bound controller', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(AppTextField(controller: controller)));

    await tester.enterText(find.byType(TextField), 'hello@zentra.app');

    expect(controller.text, 'hello@zentra.app');
  });
}
