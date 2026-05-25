import 'package:flutter/material.dart';
import 'core/design_system/app_theme.dart';
import 'shared/widgets/app_shell.dart';

void main() {
  runApp(const AssistantApp());
}

/// Root dell'applicazione Hatsune Assistant.
class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hatsune Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
