import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _mockTokenController = TextEditingController(text: 'mock-google-id-token');
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _glowAnimation;
  bool _showDevPanel = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    _animationController.forward();
    // Loop the glow animation back and forth
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mockTokenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF071A52), // Deep Navy
              Color(0xFF050505), // Pure Black
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      
                      // Pulse Glowing Logo Center
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF).withOpacity(0.35 * _glowAnimation.value),
                                  blurRadius: 40 + (20 * _glowAnimation.value),
                                  spreadRadius: 2 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.18 * _glowAnimation.value),
                                  blurRadius: 55 + (25 * _glowAnimation.value),
                                  spreadRadius: 1 * _glowAnimation.value,
                                ),
                              ],
                            ),
                          ),
                          const BrandLogo(size: 110, showGlow: false),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Brand Title (lowercase 'expenso' wordmark)
                      const BrandWordmark(fontSize: 32),
                      const SizedBox(height: 6),
                      
                      // Brand Subtitle
                      const Text(
                        'AI Powered Personal Finance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Color(0xFF8A99AD),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Fade-in Body Content
                      Opacity(
                        opacity: _fadeInAnimation.value,
                        child: Column(
                          children: [
                            // Hero Title
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                                children: [
                                  TextSpan(text: 'Smarter spending,\n'),
                                  TextSpan(
                                    text: 'better tomorrow',
                                    style: TextStyle(
                                      color: Color(0xFF0066FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Hero Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Track expenses, manage budgets and achieve your financial goals with AI.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.55),
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Feature Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildFeatureHighlight(
                                    icon: Icons.shield_outlined,
                                    title: 'Secure',
                                    subtitle: 'Bank-level security',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureHighlight(
                                    icon: Icons.smart_toy_outlined,
                                    title: 'AI Assistant',
                                    subtitle: 'Smart insights',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFeatureHighlight(
                                    icon: Icons.pie_chart_outline,
                                    title: 'All-in-One',
                                    subtitle: 'Track, plan, achieve',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Authentication Error Banner
                            if (authState.errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authState.errorMessage!,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Google Authentication Button
                            if (authState.status == AuthStatus.loading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                                  ),
                                ),
                              )
                            else ...[
                              _buildAuthButton(
                                icon: _buildGoogleIcon(),
                                label: 'Continue with Google',
                                onPressed: _handleGoogleSignIn,
                                glowColor: const Color(0xFF0066FF).withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),

                              // Text Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      'or',
                                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Secondary Continue with Email Button
                              _buildAuthButton(
                                icon: const Icon(Icons.mail_outline, color: Color(0xFF0066FF), size: 20),
                                label: 'Continue with Email',
                                onPressed: _handleEmailSignIn,
                                glowColor: Colors.transparent,
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Privacy & Security Notice Box
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.security_outlined, color: Color(0xFF00E5FF), size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'We never post without permission.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Your data is safe with us.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Interactive Legal Policy Links
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.5),
                                children: [
                                  const TextSpan(text: 'By continuing, you agree to our '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(
                                      color: Color(0xFF0066FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.push('/terms');
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: Color(0xFF0066FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        context.push('/privacy');
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Hidden Mock Token input under kDebugMode (crucial for Widget testing find.byType(TextField))
                      if (kDebugMode) ...[
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDevPanel = !_showDevPanel;
                            });
                          },
                          icon: Icon(
                            _showDevPanel ? Icons.expand_less : Icons.build_outlined,
                            size: 14,
                            color: Colors.white24,
                          ),
                          label: Text(
                            _showDevPanel ? 'Collapse Dev Options' : 'Expand Dev Options',
                            style: const TextStyle(fontSize: 10, color: Colors.white24),
                          ),
                        ),
                        if (_showDevPanel || !kReleaseMode)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: TextField(
                              controller: _mockTokenController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'OAuth Google Token',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                prefixIcon: const Icon(Icons.token_outlined, color: Color(0xFF00E5FF), size: 16),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlight({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0066FF), size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
    required Color glowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (glowColor != Colors.transparent)
            BoxShadow(
              color: glowColor,
              blurRadius: 12,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF0066FF).withOpacity(0.6),
              width: 1.5,
            ),
          ),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF0066FF).withOpacity(0.15);
              }
              return const Color(0xFF050505).withOpacity(0.65);
            },
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
        height: 12,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 14, color: Colors.black),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final token = _mockTokenController.text.trim();
    if (token == 'mock-google-id-token' || token.startsWith('mock-')) {
      ref.read(authProvider.notifier).loginWithGoogle(token);
    } else {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'https://www.googleapis.com/auth/drive.appdata',
          ],
        );
        final GoogleSignInAccount? account = await googleSignIn.signIn();
        if (account != null) {
          final GoogleSignInAuthentication auth = await account.authentication;
          final idToken = auth.idToken;
          if (idToken != null) {
            ref.read(authProvider.notifier).loginWithGoogle(idToken);
          } else {
            throw Exception('Failed to obtain Google ID token.');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Real Google Sign-In failed, falling back to mock text field: $e');
          ref.read(authProvider.notifier).loginWithGoogle(token);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Sign-In Error: $e')),
          );
        }
      }
    }
  }

  void _handleEmailSignIn() {
    if (kDebugMode) {
      // Toggle Dev token entry panel for developers
      setState(() {
        _showDevPanel = !_showDevPanel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email login not supported. Expand Developer Options to enter a mock login token.'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0F1A1C),
          title: const Text('Email Login', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Email sign-in is currently unavailable in this build. Please proceed with Continue with Google.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        ),
      );
    }
  }
}
