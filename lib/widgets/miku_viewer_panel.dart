import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../theme/app_theme.dart';

/// Pannello premium per il viewer 3D di Hatsune Miku.
///
/// Carica il modello GLB corrispondente allo stato corrente
/// e mostra un fallback elegante in caso di errore.
class MikuViewerPanel extends StatelessWidget {
  const MikuViewerPanel({super.key, required this.currentState});

  final String currentState;

  /// Percorso asset in base allo stato
  String get _modelPath {
    return currentState == 'Talking'
        ? 'assets/models/talking.glb'
        : 'assets/models/thinking.glb';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MikuColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color.fromRGBO(57, 197, 187, 0.3),
          width: 1,
        ),
        // Bagliore sottile cyan sul bordo
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(57, 197, 187, 0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Sfondo sfumato dietro il modello
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.3),
                  radius: 1.2,
                  colors: [
                    Color.fromRGBO(57, 197, 187, 0.06),
                    MikuColors.surface,
                  ],
                ),
              ),
            ),
          ),

          // Viewer 3D con key per forzare rebuild al cambio stato
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(currentState),
              src: _modelPath,
              alt: 'Modello 3D Hatsune Miku — $currentState',
              autoRotate: true,
              cameraControls: true,
              autoPlay: true,
              backgroundColor: Colors.transparent,
              // Disabilita AR (non serve per il mockup)
              ar: false,
            ),
          ),

          // Badge stato sovrapposto in alto a destra
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _ViewerBadge(state: currentState),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge decorativo sovrapposto al viewer
// ---------------------------------------------------------------------------

class _ViewerBadge extends StatelessWidget {
  const _ViewerBadge({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(10, 14, 26, 0.75),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: const Color.fromRGBO(57, 197, 187, 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MikuColors.cyan,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: MikuColors.cyan,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
