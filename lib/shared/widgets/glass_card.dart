import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';

/// Una card personalizzata con estetica Glassmorphism per l'interfaccia futuristica.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderCol = borderColor ?? AppColors.border;
    final bgCol = backgroundColor ?? AppColors.surface.withValues(alpha: 0.85);

    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? AppSpacing.edgeInsetsAllMd,
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: borderCol,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: card,
      );
    }

    return card;
  }
}
