import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/responsive_shell.dart';
import 'widgets/state_switcher.dart';

void main() {
  runApp(const AssistantApp());
}

/// Root dell'applicazione — MaterialApp con tema dark Miku.
class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hatsune Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AssistantHomePage(),
    );
  }
}

/// Pagina principale — unico StatefulWidget, gestisce lo stato Miku.
class AssistantHomePage extends StatefulWidget {
  const AssistantHomePage({super.key});

  @override
  State<AssistantHomePage> createState() => _AssistantHomePageState();
}

class _AssistantHomePageState extends State<AssistantHomePage> {
  /// Stato corrente del modello 3D
  String _currentState = 'Thinking';

  void _onStateChanged(String newState) {
    if (newState != _currentState) {
      setState(() => _currentState = newState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header con nome app e badge stato
          AppHeader(currentState: _currentState),

          // Selettore Thinking / Talking
          StateSwitcher(
            currentState: _currentState,
            onChanged: _onStateChanged,
          ),

          // Contenuto principale responsive (chat + viewer 3D)
          Expanded(
            child: ResponsiveShell(currentState: _currentState),
          ),
        ],
      ),
    );
  }
}
