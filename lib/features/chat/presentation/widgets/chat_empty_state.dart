import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Schermata iniziale di benvenuto per la chat quando non ci sono messaggi inviati dall'utente.
/// Mostra un'intestazione cyber e dei suggerimenti di domande pronte da inviare a Miku.
class ChatEmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionSelected;

  const ChatEmptyState({
    super.key,
    required this.onSuggestionSelected,
  });

  static const List<String> _suggestions = [
    'Scrivi una funzione Dart per calcolare Fibonacci',
    'Differenza tra StatelessWidget e StatefulWidget',
    'Aiutami a fare il debug di un layout Flutter',
    'Come si usa ChangeNotifier con ListenableBuilder?',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icona decorativa futuristica
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.terminal_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Titolo principale
              Text(
                'CYBER CHAT',
                style: GoogleFonts.rajdhani(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),

              // Sottotitolo
              Text(
                'Inizia a programmare con l\'aiuto di Hatsune Miku! Fai una domanda o seleziona uno dei suggerimenti sotto.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Intestazione suggerimenti
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUGGERIMENTI RAPIDI',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Lista dei suggerimenti
              ..._suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    borderColor: AppColors.border,
                    backgroundColor: AppColors.surface,
                    onTap: () => onSuggestionSelected(suggestion),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
