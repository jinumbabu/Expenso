import 'dart:math';
import 'package:flutter/material.dart';

class EcgPulseRing extends StatefulWidget {
  final int healthScore;
  final double size;
  final Color ringColor;

  const EcgPulseRing({
    super.key,
    required this.healthScore,
    this.size = 56.0,
    this.ringColor = const Color(0xFF0066FF),
  });

  @override
  State<EcgPulseRing> createState() => _EcgPulseRingState();
}

class _EcgPulseRingState extends State<EcgPulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedScore = widget.healthScore.clamp(0, 100);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Outer score ring
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: clampedScore / 100.0,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white10,
                  color: widget.ringColor,
                ),
              ),
              // Inner ECG pulse animation
              Positioned.fill(
                child: CustomPaint(
                  painter: EcgPainter(
                    animationValue: _controller.value,
                    pulseColor: widget.ringColor.withOpacity(0.5),
                  ),
                ),
              ),
              // Center score text
              Center(
                child: Text(
                  '$clampedScore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size * 0.32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EcgPainter extends CustomPainter {
  final double animationValue;
  final Color pulseColor;

  EcgPainter({required this.animationValue, required this.pulseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pulseColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height * 0.65; // Position below the center text

    final margin = width * 0.15; // Keep inside the circle
    final drawWidth = width - 2 * margin;

    path.moveTo(margin, centerY);
    
    // Generate ECG pulse path
    double step = drawWidth / 6;
    
    path.lineTo(margin + step, centerY);
    // P wave
    path.quadraticBezierTo(margin + step + step * 0.3, centerY - height * 0.08, margin + step + step * 0.6, centerY);
    path.lineTo(margin + step * 2, centerY);
    // QRS complex
    path.lineTo(margin + step * 2.3, centerY + height * 0.05); // Q
    path.lineTo(margin + step * 2.6, centerY - height * 0.22); // R spike
    path.lineTo(margin + step * 2.9, centerY + height * 0.12); // S dip
    path.lineTo(margin + step * 3.2, centerY);
    // T wave
    path.lineTo(margin + step * 4, centerY);
    path.quadraticBezierTo(margin + step * 4.4, centerY - height * 0.1, margin + step * 4.8, centerY);
    path.lineTo(width - margin, centerY);

    canvas.drawPath(path, paint);

    // Glowing point tracking the pulse (animated)
    final progressX = margin + (drawWidth * animationValue);
    // Simple lookup function for Y coordinate based on progressX
    double progressY = centerY;
    
    // Map animated dot position
    final relativeX = progressX - margin;
    if (relativeX > step && relativeX <= step * 1.6) {
      // P wave region
      final t = (relativeX - step) / (step * 0.6);
      progressY = centerY - (height * 0.08) * sin(t * pi);
    } else if (relativeX > step * 2.0 && relativeX <= step * 2.3) {
      final t = (relativeX - step * 2.0) / (step * 0.3);
      progressY = centerY + (height * 0.05) * t;
    } else if (relativeX > step * 2.3 && relativeX <= step * 2.6) {
      final t = (relativeX - step * 2.3) / (step * 0.3);
      progressY = (centerY + height * 0.05) - (height * 0.27) * t;
    } else if (relativeX > step * 2.6 && relativeX <= step * 2.9) {
      final t = (relativeX - step * 2.6) / (step * 0.3);
      progressY = (centerY - height * 0.22) + (height * 0.34) * t;
    } else if (relativeX > step * 2.9 && relativeX <= step * 3.2) {
      final t = (relativeX - step * 2.9) / (step * 0.3);
      progressY = (centerY + height * 0.12) - (height * 0.12) * t;
    } else if (relativeX > step * 4.0 && relativeX <= step * 4.8) {
      final t = (relativeX - step * 4.0) / (step * 0.8);
      progressY = centerY - (height * 0.1) * sin(t * pi);
    }

    final glowPaint = Paint()
      ..color = pulseColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(progressX, progressY), 2.5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
