import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../providers/auth_provider.dart';
import '../../../../core/routes/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;
  late Animation<double> _textFade;
  late Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.75, curve: Curves.easeInOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        ref.read(isSplashCompleteProvider.notifier).state = true;
        
        final currentAuth = ref.read(authProvider);
        if (currentAuth.status == AuthStatus.unauthenticated) {
          context.go('/login');
        } else if (currentAuth.status == AuthStatus.authenticated) {
          final isUnlocked = ref.read(isUnlockedProvider);
          if (!isUnlocked) {
            context.go('/lock');
          } else {
            context.go('/dashboard');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _screenFade.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF071A52), // Deep Navy
                    Color(0xFF050505), // Pure Black
                  ],
                  center: Alignment.center,
                  radius: 1.35,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing logo
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _logoGlow.value,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0066FF).withOpacity(0.35 * _logoGlow.value),
                                    blurRadius: 75,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.18 * _logoGlow.value),
                                    blurRadius: 95,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const BrandLogo(size: 160, showGlow: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Tagline & wordmark
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          const BrandWordmark(fontSize: 38),
                          const SizedBox(height: 12),
                          Text(
                            'AI-Powered Personal Finance'.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4.0,
                              color: Colors.white.withOpacity(0.45 * _textFade.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
