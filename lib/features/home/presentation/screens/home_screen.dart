import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/state/assistant_state.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../features/models/domain/model_info.dart';

/// La Dashboard iniziale dell'applicazione, collegata allo stato reale.
class HomeScreen extends StatelessWidget {
  final AssistantState state;

  const HomeScreen({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final useSingleColumn = MediaQuery.sizeOf(context).width < 1100;

    // Conta i modelli suddivisi per tipo
    final localCount = state.models.where((m) => m.type == ModelType.local).length;
    final cloudCount = state.models.where((m) => m.type == ModelType.cloud).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card dell'Assistente
            _AssistantHeroCard(state: state),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'STATO DEL SISTEMA REALE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Griglia responsive per lo stato del sistema
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: useSingleColumn ? 1 : 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: useSingleColumn ? 3.2 : 2.2,
              children: [
                _StatusMetricCard(
                  title: 'Modello Attivo',
                  value: state.activeModel?.name ?? 'Nessun Modello',
                  subtitle: state.activeModel != null
                      ? '${state.activeModel!.provider} • Pronto'
                      : 'Seleziona un modello dalla tab Models',
                  icon: Icons.auto_awesome,
                  accentColor: AppColors.primary,
                ),
                _StatusMetricCard(
                  title: 'Connessione Ollama',
                  value: state.isConnected ? 'ONLINE' : 'OFFLINE',
                  subtitle: 'Endpoint: ${state.ollamaUrl}',
                  icon: Icons.lan,
                  accentColor: state.isConnected ? AppColors.success : AppColors.error,
                ),
                _StatusMetricCard(
                  title: 'Modelli Disponibili',
                  value: '${state.models.length} Modelli',
                  subtitle: '$localCount Locali • $cloudCount Cloud Configurati',
                  icon: Icons.dns,
                  accentColor: AppColors.localModel,
                ),
                _StatusMetricCard(
                  title: 'Posa Corrente Avatar',
                  value: state.mikuState.name.toUpperCase(),
                  subtitle: 'Interazione 3D in tempo reale',
                  icon: Icons.face,
                  accentColor: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'AZIONI DI TEST',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Pulsanti di interazione rapida e diagnostica
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _QuickActionButton(
                  label: 'Ricarica Modelli',
                  icon: Icons.refresh,
                  onPressed: () => state.refreshModels(),
                ),
                _QuickActionButton(
                  label: 'Trigger Posa Victory (5s)',
                  icon: Icons.star,
                  onPressed: () => state.triggerVictoryManual(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card principale promozionale/infolink dell'assistente.
class _AssistantHeroCard extends StatelessWidget {
  final AssistantState state;

  const _AssistantHeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Graphic avatar di Miku stilizzato
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.face,
                size: 40,
                color: AppColors.background,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      'Hatsune Miku',
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderRadiusSm,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        state.isConnected ? 'ONLINE' : 'OFFLINE',
                        style: GoogleFonts.rajdhani(
                          color: state.isConnected ? AppColors.primary : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.isConnected
                      ? 'Connessa ed operativa con il modello ${state.activeModel?.name ?? ""}. Chiedimi pure aiuto per il codice!'
                      : 'Attualmente disconnessa da Ollama. Assicurati che l\'applicazione sia in esecuzione sulla porta 11434.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per le metriche di stato.
class _StatusMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _StatusMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottone per azioni rapide.
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusMd,
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary, size: 20),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
