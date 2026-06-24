import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const BrandLogo({
    super.key,
    this.size = 150.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            Container(
              width: size * 1.2,
              height: size * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withOpacity(0.35),
                    blurRadius: size * 0.45,
                    spreadRadius: size * 0.05,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.18),
                    blurRadius: size * 0.65,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          Image.asset(
            'assets/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  final double fontSize;

  const BrandWordmark({
    super.key,
    this.fontSize = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'e',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: fontSize * 0.05,
          ),
        ),
        SizedBox(
          width: fontSize * 0.55,
          height: fontSize * 0.55,
          child: CustomPaint(
            painter: _XWordmarkPainter(fontSize: fontSize),
          ),
        ),
        SizedBox(width: fontSize * 0.05),
        Text(
          'penso',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: fontSize * 0.05,
          ),
        ),
      ],
    );
  }
}

class _XWordmarkPainter extends CustomPainter {
  final double fontSize;

  _XWordmarkPainter({required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.height * 0.18;

    // Cyan Paint
    final paintCyan = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Blue Paint
    final paintBlue = Paint()
      ..color = const Color(0xFF0066FF)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glowing cyan filter
    final glowCyan = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.6)
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0);

    // Glowing blue filter
    final glowBlue = Paint()
      ..color = const Color(0xFF0066FF).withOpacity(0.6)
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0);

    final margin = size.height * 0.1;

    // Cyan line: top-left to bottom-right
    canvas.drawLine(
      Offset(margin, margin),
      Offset(size.width - margin, size.height - margin),
      glowCyan,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(size.width - margin, size.height - margin),
      paintCyan,
    );

    // Blue line: bottom-left to top-right
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(size.width - margin, margin),
      glowBlue,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(size.width - margin, margin),
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
