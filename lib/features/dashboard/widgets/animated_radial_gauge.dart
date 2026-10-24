import 'dart:math';
import 'package:flutter/material.dart';
import '../../exposure/exposure_controller.dart';

class AnimatedRadialGauge extends StatefulWidget {
  final AirQualityLevel level;
  final int pm25;
  final bool isSpikeActive;

  const AnimatedRadialGauge({
    super.key,
    required this.level,
    required this.pm25,
    this.isSpikeActive = false,
  });

  @override
  State<AnimatedRadialGauge> createState() => _AnimatedRadialGaugeState();
}

class _AnimatedRadialGaugeState extends State<AnimatedRadialGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpikeActive != oldWidget.isSpikeActive) {
      if (widget.isSpikeActive) {
        _glowController.duration = const Duration(milliseconds: 600);
        _glowController.repeat(reverse: true);
      } else {
        _glowController.duration = const Duration(milliseconds: 1400);
        _glowController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.level.color;
    final clampedProgress = (widget.pm25 / 100.0).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Aura Glow Ring
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: widget.isSpikeActive ? 0.45 : 0.22,
                    ),
                    blurRadius: _glowAnimation.value * (widget.isSpikeActive ? 1.6 : 1.0),
                    spreadRadius: widget.isSpikeActive ? 6.0 : 2.0,
                  ),
                ],
              ),
            ),

            // Background circular track
            SizedBox(
              width: 154,
              height: 154,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 12,
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            ),

            // Foreground animated progress indicator
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clampedProgress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return SizedBox(
                  width: 154,
                  height: 154,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                );
              },
            ),

            // Center Content: Smooth Digit Counter
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: widget.pm25.toDouble()),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Text(
                      val.round().toString(),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'µg/m³ PM2.5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
