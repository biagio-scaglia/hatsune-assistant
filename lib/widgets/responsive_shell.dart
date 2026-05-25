import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'miku_viewer_panel.dart';
import 'mock_chat_panel.dart';

/// Shell responsive: gestisce il layout in base alla larghezza.
///
/// - Desktop/tablet (≥ 900px): riga con chat a sinistra, viewer a destra
/// - Mobile (< 900px): colonna con viewer in alto, chat sotto
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({super.key, required this.currentState});

  final String currentState;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= Breakpoints.tablet;
        final padding = isWide ? AppSpacing.lg : AppSpacing.md;

        if (isWide) {
          return _WideLayout(
            currentState: currentState,
            padding: padding,
          );
        }

        return _NarrowLayout(
          currentState: currentState,
          padding: padding,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Layout desktop/tablet — pannelli affiancati
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.currentState,
    required this.padding,
  });

  final String currentState;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chat a sinistra
          const Expanded(
            flex: 4,
            child: MockChatPanel(),
          ),

          SizedBox(width: padding),

          // Viewer 3D a destra — più spazio
          Expanded(
            flex: 6,
            child: MikuViewerPanel(currentState: currentState),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout mobile — pannelli impilati
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.currentState,
    required this.padding,
  });

  final String currentState;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // Viewer 3D in alto — altezza proporzionale
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.38,
            child: MikuViewerPanel(currentState: currentState),
          ),

          SizedBox(height: padding),

          // Chat sotto — occupa lo spazio restante
          const Expanded(
            child: MockChatPanel(),
          ),
        ],
      ),
    );
  }
}
