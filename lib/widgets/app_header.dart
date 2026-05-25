import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header superiore dell'app con nome, stato corrente e indicatore decorativo.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.currentState});

  final String currentState;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.xl : AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: MikuColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: MikuColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Indicatore decorativo pulsante
          const _PulsingDot(),
          const SizedBox(width: AppSpacing.sm),

          // Nome app
          Text(
            'Hatsune Assistant',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: MikuColors.cyan,
              letterSpacing: 1.2,
            ),
          ),

          const Spacer(),

          // Badge stato corrente
          _StatusBadge(state: currentState),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge stato — mostra "Thinking" o "Talking" con icona e colore
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final isTalking = state == 'Talking';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isTalking
            ? const Color.fromRGBO(57, 197, 187, 0.15)
            : const Color.fromRGBO(255, 107, 157, 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isTalking ? MikuColors.cyan : MikuColors.pink,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTalking ? Icons.chat_bubble_outline : Icons.psychology_outlined,
            size: 16,
            color: isTalking ? MikuColors.cyan : MikuColors.pink,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isTalking ? MikuColors.cyan : MikuColors.pink,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Indicatore pulsante decorativo — piccolo dot cyan animato
// ---------------------------------------------------------------------------

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MikuColors.cyan.withValues(alpha: _animation.value),
            boxShadow: [
              BoxShadow(
                color: MikuColors.cyan.withValues(alpha: _animation.value * 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
