import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/state/assistant_state.dart';

/// Pannello interattivo che renderizza l'avatar 3D di Hatsune Miku
/// caricando dinamicamente il file GLB a seconda dello stato corrente.
class Miku3DViewer extends StatelessWidget {
  final MikuState state;

  const Miku3DViewer({
    super.key,
    required this.state,
  });

  String _getModelPath() {
    switch (state) {
      case MikuState.thinking:
        return 'assets/models/thinking.glb';
      case MikuState.talking:
        return 'assets/models/talking.glb';
      case MikuState.victory:
        return 'assets/models/victory.glb';
      case MikuState.listening:
      case MikuState.idle:
        return 'assets/models/idle.glb';
    }
  }

  static bool isTesting = false;

  @override
  Widget build(BuildContext context) {
    final modelPath = _getModelPath();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderRadiusMd,
        child: Stack(
          children: [
            // Model Viewer interattivo o segnaposto di test
            if (isTesting)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face, color: AppColors.primary, size: 48),
                    SizedBox(height: 8),
                    Text('Miku 3D (Test Mode)', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ModelViewer(
                key: ValueKey(modelPath), // Forza la rigenerazione del widget al cambio modello
                src: modelPath,
                alt: "Hatsune Miku 3D Avatar",
                ar: false,
                autoRotate: state == MikuState.idle, // Ruota autonomamente solo quando è in attesa
                cameraControls: true,
                backgroundColor: Colors.transparent,
                disableZoom: false,
                autoPlay: true,
              ),

            // Badge descrittivo dello stato in alto a sinistra
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.75),
                  borderRadius: AppRadius.borderRadiusCircular,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStateIndicator(),
                    const SizedBox(width: 6),
                    Text(
                      _getStateLabel().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIndicator() {
    Color indicatorColor;
    switch (state) {
      case MikuState.thinking:
        indicatorColor = AppColors.secondary;
        break;
      case MikuState.talking:
        indicatorColor = AppColors.primary;
        break;
      case MikuState.victory:
        indicatorColor = AppColors.success;
        break;
      case MikuState.listening:
        indicatorColor = AppColors.primaryLight;
        break;
      case MikuState.idle:
        indicatorColor = AppColors.textMuted;
        break;
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: indicatorColor.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  String _getStateLabel() {
    switch (state) {
      case MikuState.thinking:
        return 'Thinking...';
      case MikuState.talking:
        return 'Talking';
      case MikuState.victory:
        return 'Victory! ✨';
      case MikuState.listening:
        return 'Listening...';
      case MikuState.idle:
        return 'Idle';
    }
  }
}
