// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop/app.dart';

void main() {
  testWidgets('pet shop renders the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PetShopApp());

    expect(find.text('Pet Shop da Vânia'), findsOneWidget);
    expect(find.text('Encontre seu novo melhor amigo'), findsOneWidget);
  });
}
