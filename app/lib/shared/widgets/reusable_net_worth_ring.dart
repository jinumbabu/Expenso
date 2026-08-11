import 'dart:math';
import 'package:flutter/material.dart';

class ReusableNetWorthRing extends StatefulWidget {
  final double valueFraction; // e.g. 0.66 (representing Assets or Remaining fraction)
  final double size;
  final Color trackColor; // e.g. Color(0xFFFF3B30) for Liabilities or Expenses

  const ReusableNetWorthRing({
    super.key,
    required this.valueFraction,
    this.size = 54.0,
    required this.trackColor,
  });

  @override
  State<ReusableNetWorthRing> createState() => _ReusableNetWorthRingState();
}

class _ReusableNetWorthRingState extends State<ReusableNetWorthRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _oldFraction = widget.valueFraction;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700), // 1100ms for asset, 600ms for liability
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ReusableNetWorthRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueFraction != widget.valueFraction) {
      _oldFraction = oldWidget.valueFraction;
    }
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
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _oldFraction, end: widget.valueFraction),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          builder: (context, animatedFraction, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: NetWorthRingPainter(
                  progress: _animation.value,
                  valueFraction: animatedFraction,
                  trackColor: widget.trackColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class NetWorthRingPainter extends CustomPainter {
  final double progress;
  final double valueFraction;
  final Color trackColor;

  NetWorthRingPainter({
    required this.progress,
    required this.valueFraction,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;
    final radius = min(size.width, size.height) / 2 - 6;

    // Handle invalid values safely
    double fraction = valueFraction;
    if (fraction.isNaN || fraction.isInfinite) {
      fraction = 0.0;
    } else {
      fraction = fraction.clamp(0.0, 1.0);
    }

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate dynamic gap angle based on stroke width and radius
    final capExtension = (strokeWidth / 2) / radius;
    const visualGap = 0.08; 
    final gapAngle = 2 * capExtension + visualGap;

    // Total available angle for both arcs
    final totalArcAngle = 2 * pi - 2 * gapAngle;

    // Split progress into Phase 1 (Asset: 0.0 -> 0.65) and Phase 2 (Liability: 0.65 -> 1.0)
    final double rawAssetProgress = (progress / 0.65).clamp(0.0, 1.0);
    final double rawLiabilityProgress = ((progress - 0.65) / 0.35).clamp(0.0, 1.0);

    final double assetProgress = Curves.easeOut.transform(rawAssetProgress);
    final double liabilityProgress = Curves.easeOut.transform(rawLiabilityProgress);

    // If fraction is 1.0 (or very close), draw a full blue/cyan gradient circle in Phase 1
    if (fraction >= 0.995) {
      final bluePaint = Paint()
        ..shader = const SweepGradient(
          colors: [Color(0xFF0052D4), Color(0xFF0066FF), Color(0xFF00E5FF), Color(0xFF0052D4)],
          stops: [0.0, 0.4, 0.8, 1.0],
          transform: GradientRotation(-pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      // Draws clockwise smoothly in Phase 1
      canvas.drawArc(rect, -pi / 2, 2 * pi * assetProgress, false, bluePaint);
      return;
    }

    // If fraction is 0.0 (or very close), draw a full red circle in Phase 2
    if (fraction <= 0.005) {
      final redPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      // Draws clockwise smoothly in Phase 2
      canvas.drawArc(rect, -pi / 2, 2 * pi * liabilityProgress, false, redPaint);
      return;
    }

    // Draw Segment A (Blue/Cyan gradient representing Assets/Remaining)
    // It starts at -pi/2 + gapAngle/2, and grows clockwise during Phase 1
    final sweepA = totalArcAngle * fraction * assetProgress;
    final paintA = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF0052D4), Color(0xFF0066FF), Color(0xFF00E5FF), Color(0xFF0052D4)],
        stops: [0.0, 0.4, 0.8, 1.0],
        transform: GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startA = -pi / 2 + gapAngle / 2;
    canvas.drawArc(rect, startA, sweepA, false, paintA);

    // Draw Segment B (Red representing Liabilities/Expenses)
    // It starts at the end of Segment A + gap Angle, and grows clockwise during Phase 2
    // The start angle startB remains stationary during the animation
    final sweepB = totalArcAngle * (1.0 - fraction) * liabilityProgress;
    final paintB = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startB = startA + totalArcAngle * fraction + gapAngle;
    canvas.drawArc(rect, startB, sweepB, false, paintB);
  }

  @override
  bool shouldRepaint(covariant NetWorthRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.valueFraction != valueFraction ||
        oldDelegate.trackColor != trackColor;
  }
}
