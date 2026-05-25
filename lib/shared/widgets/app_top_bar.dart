import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';

/// Barra superiore premium e responsive per Hatsune Assistant.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String statusText;
  final bool isOnline;

  const AppTopBar({
    super.key,
    this.statusText = "Ollama Local: Attivo",
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            'HATSUNE ASSISTANT',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      actions: [
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
                  statusText,
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
