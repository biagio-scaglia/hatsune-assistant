import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Selettore stato Thinking / Talking con chip animati.
class StateSwitcher extends StatelessWidget {
  const StateSwitcher({
    super.key,
    required this.currentState,
    required this.onChanged,
  });

  final String currentState;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StateChip(
            label: 'Thinking',
            icon: Icons.psychology_outlined,
            isSelected: currentState == 'Thinking',
            onTap: () => onChanged('Thinking'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StateChip(
            label: 'Talking',
            icon: Icons.chat_bubble_outline,
            isSelected: currentState == 'Talking',
            onTap: () => onChanged('Talking'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Singolo chip stato con animazione selezionato/deselezionato
// ---------------------------------------------------------------------------

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(57, 197, 187, 0.2)
              : MikuColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected ? MikuColors.cyan : MikuColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? MikuColors.cyan : MikuColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? MikuColors.cyan : MikuColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
