import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_auto_parts/validation/validators.dart';
import 'package:shop_auto_parts/widgets/entity_form.dart';

void main() {
  testWidgets('форма не отправляется с пустым названием', (tester) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityFormScaffold(
            title: 'Новая запчасть',
            fallbackPath: '/parts',
            formKey: formKey,
            isDirty: false,
            onSave: () {
              if (formKey.currentState?.validate() ?? false) {
                saved = true;
              }
            },
            fields: [
              FieldSpec.text(
                label: 'Название',
                controller: name,
                validator: Validators.name,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(find.textContaining('Заполните поле'), findsOneWidget);
    expect(saved, isFalse);
  });
}
