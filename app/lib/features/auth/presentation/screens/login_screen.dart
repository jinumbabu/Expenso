import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _showDevPanel = Platform.environment.containsKey('FLUTTER_TEST');

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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 4),
                      
                      // Pulse Glowing Logo Center
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0066FF).withOpacity(0.35 * _glowAnimation.value),
                                  blurRadius: 25 + (15 * _glowAnimation.value),
                                  spreadRadius: 1 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.18 * _glowAnimation.value),
                                  blurRadius: 35 + (20 * _glowAnimation.value),
                                  spreadRadius: 0.5 * _glowAnimation.value,
                                ),
                              ],
                            ),
                          ),
                          const BrandLogo(size: 80, showGlow: false),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Brand Title (lowercase 'expenso' wordmark)
                      const BrandWordmark(fontSize: 26),
                      const SizedBox(height: 4),
                      
                      // Brand Subtitle
                      const Text(
                        'AI Powered Personal Finance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Color(0xFF8A99AD),
                        ),
                      ),
                      const SizedBox(height: 12),

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
                                  fontSize: 21,
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
                            const SizedBox(height: 6),

                            // Hero Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Track expenses, manage budgets and achieve your financial goals with AI.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.55),
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

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
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildFeatureHighlight(
                                    icon: Icons.smart_toy_outlined,
                                    title: 'AI Assistant',
                                    subtitle: 'Smart insights',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: _buildFeatureHighlight(
                                    icon: Icons.pie_chart_outline,
                                    title: 'All-in-One',
                                    subtitle: 'Track, plan, achieve',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Authentication Error Banner
                            if (authState.errorMessage != null) ...[
                              Builder(
                                builder: (context) {
                                  final errorMessage = authState.errorMessage!;
                                  final isConnectionError = errorMessage.contains('SocketException') ||
                                      errorMessage.contains('Failed host lookup') ||
                                      errorMessage.contains('connection error') ||
                                      errorMessage.toLowerCase().contains('network') ||
                                      errorMessage.toLowerCase().contains('unreachable');
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                errorMessage,
                                                style: const TextStyle(color: Colors.white, fontSize: 11.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isConnectionError) ...[
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0066FF),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              ref.read(authProvider.notifier).loginOffline();
                                            },
                                            icon: const Icon(Icons.wifi_off_outlined, size: 14),
                                            label: const Text(
                                              'Proceed in Offline Mode',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ],

                            // Google Authentication Button
                            if (authState.status == AuthStatus.loading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
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
                              const SizedBox(height: 10),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00E5FF),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.25), width: 1),
                                  ),
                                  backgroundColor: Colors.white.withOpacity(0.02),
                                ),
                                onPressed: () {
                                  ref.read(authProvider.notifier).loginOffline();
                                },
                                icon: const Icon(Icons.wifi_off_outlined, size: 16),
                                label: const Text(
                                  'Continue in Offline Mode',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Privacy & Security Notice Box
                            GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0066FF).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.security_outlined, color: Color(0xFF00E5FF), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'We never post without permission.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Your data is safe with us.',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Interactive Legal Policy Links
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white38, fontSize: 10.5, height: 1.3),
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
                            const SizedBox(height: 8),
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
                        if (_showDevPanel)
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0066FF), size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
    // Only use the mock token if we are in a test environment or if we are in debug mode and the dev panel is explicitly expanded.
    final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
    final useMock = isTesting || (kDebugMode && _showDevPanel && (token == 'mock-google-id-token' || token.startsWith('mock-')));

    if (useMock) {
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
            try {
              // Sign in to Firebase Authentication using Google Credentials
              final AuthCredential credential = GoogleAuthProvider.credential(
                accessToken: auth.accessToken,
                idToken: idToken,
              );
              await FirebaseAuth.instance.signInWithCredential(credential);

              await ref.read(authProvider.notifier).loginWithGoogle(idToken);
              
              final currentAuthState = ref.read(authProvider);
              if (currentAuthState.status == AuthStatus.unauthenticated) {
                final err = currentAuthState.errorMessage;
                if (err != null &&
                    (err.contains('SocketException') ||
                     err.contains('Failed host lookup') ||
                     err.contains('connection error') ||
                     err.toLowerCase().contains('network') ||
                     err.toLowerCase().contains('unreachable'))) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server unreachable. Proceeding offline as ${account.displayName ?? "User"}...'),
                        backgroundColor: const Color(0xFF0066FF),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  await ref.read(authProvider.notifier).loginOffline(
                    email: account.email,
                    displayName: account.displayName,
                    googleId: account.id,
                  );
                }
              }
            } catch (_) {
              await ref.read(authProvider.notifier).loginOffline(
                email: account.email,
                displayName: account.displayName,
                googleId: account.id,
              );
            }
          } else {
            throw Exception('Failed to obtain Google ID token.');
          }
        }
      } catch (e) {
        if (!mounted) return;
        if (kDebugMode) {
          debugPrint('Real Google Sign-In failed, falling back to mock text field: $e');
          ref.read(authProvider.notifier).loginWithGoogle(token);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0F1A1C),
              title: const Text('Google Sign-In Unreachable', style: TextStyle(color: Colors.white)),
              content: Text(
                'Google Sign-In is currently unavailable (could be due to missing SHA-1 signature configuration or offline constraints).\n\nDetails: $e\n\nWould you like to proceed to the app in Offline Mode?',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).loginOffline();
                  },
                  child: const Text('Proceed Offline', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    }
  }


}
