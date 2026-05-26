import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/responsive/breakpoints.dart';

/// Barra superiore premium e responsive per Hatsune Assistant.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String statusText;
  final bool isOnline;
  final VoidCallback? onClearChat;

  const AppTopBar({
    super.key,
    this.statusText = "Ollama Local: Attivo",
    this.isOnline = true,
    this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    // Su mobile, riduciamo il testo dello stato per salvare spazio orizzontale ed evitare overflow
    String displayStatusText = statusText;
    if (isMobile) {
      if (statusText.contains('Ollama: Connesso (')) {
        // "Ollama: Connesso (llama3)" -> "llama3"
        final start = statusText.indexOf('(') + 1;
        final end = statusText.indexOf(')');
        if (start > 0 && end > start) {
          displayStatusText = statusText.substring(start, end);
        } else {
          displayStatusText = "Connesso";
        }
      } else if (statusText == "Ollama: Disconnesso") {
        displayStatusText = "Offline";
      }
    }

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Icona o Logo con gradiente Hatsune Miku
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.cyberGradient,
              borderRadius: AppRadius.borderRadiusSm,
            ),
            child: Text(
              'MIKU',
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.background,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Avvolgiamo il titolo in un Expanded per consentire la contrazione su mobile senza overflow
          Expanded(
            child: Text(
              'HATSUNE ASSISTANT',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onClearChat != null) ...[
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
            tooltip: 'Cancella cronologia chat',
            onPressed: onClearChat,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        // Indicatore di stato connessione a Ollama/Cloud
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.borderRadiusCircular,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pallino luminoso lampeggiante dello stato
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isOnline)
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  displayStatusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
