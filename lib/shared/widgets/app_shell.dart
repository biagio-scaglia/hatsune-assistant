import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/state/assistant_state.dart';
import 'app_top_bar.dart';
import 'miku_3d_viewer.dart';

// Importazioni delle schermate feature
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/models/presentation/screens/models_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// La Shell dell'app. Gestisce il cambio schermata principale e adatta
/// il layout tra Bottom Navigation Bar (Mobile) e Navigation Rail (Tablet/Desktop).
/// Integra anche il visualizzatore 3D di Hatsune Miku in modo responsive.
class AppShell extends StatefulWidget {
  final AssistantState state;

  const AppShell({
    super.key,
    required this.state,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    
    // Rileva se la tastiera software è aperta
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Lista delle schermate principali dell'applicazione
    final List<Widget> screens = [
      HomeScreen(state: widget.state),
      ChatScreen(state: widget.state),
      ModelsScreen(state: widget.state),
      SettingsScreen(state: widget.state),
    ];

    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true, // Consente il ridimensionamento automatico del body con la tastiera
          appBar: AppTopBar(
            statusText: widget.state.isConnected
                ? "Ollama: Connesso (${widget.state.activeModel?.name ?? 'nessuno'})"
                : "Ollama: Disconnesso",
            isOnline: widget.state.isConnected,
            onClearChat: _currentIndex == 1 ? () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Cancella Cronologia', style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text('Sei sicuro di voler cancellare tutta la cronologia della chat sia in locale che sul database?', style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Cancella'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                widget.state.clearChat();
              }
            } : null,
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            child: isMobile
                ? Column(
                    children: [
                      // Su Mobile mostra il visualizzatore 3D solo in Home o Chat, e solo se la tastiera è CHIUSA
                      if ((_currentIndex == 0 || _currentIndex == 1) && !isKeyboardOpen)
                        SizedBox(
                          height: 240,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.md,
                              AppSpacing.md,
                              0,
                            ),
                            child: Miku3DViewer(state: widget.state.mikuState),
                          ),
                        ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Sidebar laterale per tablet/desktop
                      NavigationRail(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                        labelType: NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Home'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.chat_bubble_outline),
                            selectedIcon: Icon(Icons.chat_bubble),
                            label: Text('Chat'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.dns_outlined),
                            selectedIcon: Icon(Icons.dns),
                            label: Text('Models'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings),
                            label: Text('Settings'),
                          ),
                        ],
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      
                      // Schermata tab attiva
                      Expanded(
                        flex: 3,
                        child: IndexedStack(
                          index: _currentIndex,
                          children: screens,
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                      
                      // Pannello destro fisso per Miku 3D su desktop/tablet
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Miku3DViewer(state: widget.state.mikuState),
                        ),
                      ),
                    ],
                  ),
          ),
          // Nasconde la barra di navigazione mobile se la tastiera è aperta per evitare overlap e recuperare spazio
          bottomNavigationBar: (isMobile && !isKeyboardOpen)
              ? NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble),
                      label: 'Chat',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.dns_outlined),
                      selectedIcon: Icon(Icons.dns),
                      label: 'Models',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
