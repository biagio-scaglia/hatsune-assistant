import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/responsive/breakpoints.dart';
import 'app_top_bar.dart';

// Importazioni delle schermate feature
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/models/presentation/screens/models_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// La Shell dell'app. Gestisce il cambio schermata principale e adatta
/// il layout tra Bottom Navigation Bar (Mobile) e Navigation Rail (Tablet/Desktop).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // Lista delle schermate principali dell'applicazione
  final List<Widget> _screens = const [
    HomeScreen(),
    ChatScreen(),
    ModelsScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    return Scaffold(
      appBar: const AppTopBar(),
      body: SafeArea(
        top: false, // Gestito dall'AppBar per evitare sovrapposizioni visive
        bottom: true,
        child: Row(
          children: [
            // Mostra il Navigation Rail laterale solo se non siamo su Mobile (Tablet/Desktop)
            if (!isMobile) ...[
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabSelected,
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
            ],
            // Contenuto principale dello schermo attivo
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      // Mostra la barra inferiore solo su dispositivi Mobile
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
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
  }
}
