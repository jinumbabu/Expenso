import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final List<BoxShadow>? customShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
    this.blur = 16.0,
    this.borderColor,
    this.gradientColors,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: customShadows ?? [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.04),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? [
                  const Color(0xFF0066FF).withOpacity(0.08),
                  const Color(0xFF050505).withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? const Color(0xFF0066FF).withOpacity(0.18),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
