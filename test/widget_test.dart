// Test base per verificare che l'app si avvii correttamente.

import 'package:flutter_test/flutter_test.dart';
import 'package:hatsune/core/state/assistant_state.dart';
import 'package:hatsune/shared/widgets/miku_3d_viewer.dart';
import 'package:hatsune/main.dart';

void main() {
  testWidgets('App si avvia e mostra il titolo', (WidgetTester tester) async {
    Miku3DViewer.isTesting = true;
    final state = AssistantState();
    await tester.pumpWidget(AssistantApp(state: state));

    // Verifica che il titolo dell'app sia presente
    expect(find.text('HATSUNE ASSISTANT'), findsOneWidget);
  });
}
