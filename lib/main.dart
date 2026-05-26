import 'package:flutter/material.dart';
import 'core/design_system/app_theme.dart';
import 'core/state/assistant_state.dart';
import 'shared/widgets/app_shell.dart';

void main() {
  final state = AssistantState();
  runApp(AssistantApp(state: state));
}

/// Root dell'applicazione Hatsune Assistant.
class AssistantApp extends StatelessWidget {
  final AssistantState state;

  const AssistantApp({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hatsune Assistant',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: AppShell(state: state),
        );
      },
    );
  }
}
