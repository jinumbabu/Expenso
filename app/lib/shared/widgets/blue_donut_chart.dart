import 'dart:math';
import 'package:flutter/material.dart';

class BlueDonutChart extends StatefulWidget {
  final double savingsPercentage; // e.g. 0.66
  final double size;
  final Color? trackColor;

  const BlueDonutChart({
    super.key,
    required this.savingsPercentage,
    this.size = 80.0,
    this.trackColor,
  });

  @override
  State<BlueDonutChart> createState() => _BlueDonutChartState();
}

class _BlueDonutChartState extends State<BlueDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: DonutPainter(
              progress: _animation.value,
              savingsFraction: widget.savingsPercentage,
              trackColor: widget.trackColor,
            ),
          ),
        );
      },
    );
  }
}

class DonutPainter extends CustomPainter {
  final double progress;
  final double savingsFraction;
  final Color? trackColor;

  DonutPainter({
    required this.progress,
    required this.savingsFraction,
    this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    // Handle empty state (both assets and liabilities are 0)
    if (savingsFraction < 0) {
      final neutralPaint = Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, neutralPaint);
      return;
    }

    // Track Paint for Expenses (the remainder)
    final expensePaint = Paint()
      ..color = trackColor ?? const Color(0xFF0A182E) // Dark navy/blue background track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Drawing base track circle
    canvas.drawCircle(center, radius, expensePaint);

    // Savings Arc Paint (glowing electric blue gradient)
    final rect = Rect.fromCircle(center: center, radius: radius);
    final savingsPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF0052D4), Color(0xFF0066FF), Color(0xFF00E5FF), Color(0xFF0052D4)],
        stops: [0.0, 0.4, 0.8, 1.0],
        transform: GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw Savings portion (start from -pi/2 which is top center)
    final sweepAngle = 2 * pi * savingsFraction * progress;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, savingsPaint);
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.savingsFraction != savingsFraction ||
        oldDelegate.trackColor != trackColor;
  }
}
