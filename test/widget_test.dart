// Test base per verificare che l'app si avvii correttamente.

import 'package:flutter_test/flutter_test.dart';

import 'package:hatsune/main.dart';

void main() {
  testWidgets('App si avvia e mostra il titolo', (WidgetTester tester) async {
    await tester.pumpWidget(const AssistantApp());

    // Verifica che il titolo dell'app sia presente
    expect(find.text('Hatsune Assistant'), findsOneWidget);
  });
}
