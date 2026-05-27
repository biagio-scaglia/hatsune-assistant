import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class WaveformIndicator extends StatefulWidget {
  final bool isAnimated;

  const WaveformIndicator({
    super.key,
    required this.isAnimated,
  });

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [0.2, 0.5, 0.8, 0.4, 0.7, 0.9, 0.3, 0.6, 0.2, 0.5, 0.8, 0.4];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_baseHeights.length, (index) {
              // Calcola l'altezza sinusoidale basata sul controller e sul seno per sfasare le barre
              final phase = (index / _baseHeights.length) * 2 * pi;
              final multiplier = widget.isAnimated
                  ? (sin(_controller.value * 2 * pi + phase) + 1.0) / 2.0
                  : 0.1;
                  
              final barHeight = 15.0 + (35.0 * _baseHeights[index] * multiplier);

              return Container(
                width: 4,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  gradient: AppColors.cyberGradient,
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: [
                    if (widget.isAnimated)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
