import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/security/app_lock_service.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  String _enteredPin = '';
  int _pinLength = 4;
  bool _isLoading = true;
  bool _isLockedOut = false;
  int _lockoutSecondsLeft = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _initLockState();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLockState() async {
    final appLock = ref.read(appLockServiceProvider);
    final user = ref.read(authProvider).user;
    final userId = user?.id ?? '';

    // If no PIN is configured, bypass the lock screen entirely
    final hasPin = await appLock.isPinSet(userId);
    if (!hasPin) {
      if (mounted) {
        ref.read(isUnlockedProvider.notifier).state = true;
        context.go('/dashboard');
      }
      return;
    }

    final len = await appLock.getPinLength(userId);
    final lockedOut = await appLock.isLockedOut(userId);

    setState(() {
      _pinLength = len;
      _isLockedOut = lockedOut;
      _isLoading = false;
    });

    if (lockedOut) {
      _startLockoutCountdown();
    } else {
      // Auto prompt biometrics if enabled
      final isBioEnabled = await appLock.isBiometricEnabled(userId);
      if (isBioEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _authenticateWithBiometrics();
        });
      }
    }
  }

  Future<void> _startLockoutCountdown() async {
    final appLock = ref.read(appLockServiceProvider);
    final userId = ref.read(authProvider).user?.id ?? '';
    
    _lockoutTimer?.cancel();
    final seconds = await appLock.getRemainingLockoutSeconds(userId);
    setState(() {
      _lockoutSecondsLeft = seconds;
      _isLockedOut = true;
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final left = await appLock.getRemainingLockoutSeconds(userId);
      if (left <= 0) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _lockoutSecondsLeft = 0;
          _enteredPin = '';
        });
      } else {
        setState(() {
          _lockoutSecondsLeft = left;
        });
      }
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLockedOut) return;
    final appLock = ref.read(appLockServiceProvider);
    final success = await appLock.authenticateWithBiometrics();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      ref.read(isUnlockedProvider.notifier).state = true;
      context.go('/dashboard');
    }
  }

  Future<void> _onKeyPress(String val) async {
    if (_isLockedOut || _isLoading) return;
    HapticFeedback.lightImpact();

    setState(() {
      if (_enteredPin.length < _pinLength) {
        _enteredPin += val;
      }
    });

    if (_enteredPin.length == _pinLength) {
      final appLock = ref.read(appLockServiceProvider);
      final userId = ref.read(authProvider).user?.id ?? '';
      
      final verified = await appLock.verifyPin(userId, _enteredPin);
      if (verified) {
        HapticFeedback.mediumImpact();
        ref.read(isUnlockedProvider.notifier).state = true;
        context.go('/dashboard');
      } else {
        HapticFeedback.vibrate();
        final locked = await appLock.isLockedOut(userId);
        if (locked) {
          _startLockoutCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Too many failed attempts. Device locked.'),
              backgroundColor: Color(0xFFFF3B30),
            ),
          );
        } else {
          final attempts = await appLock.getFailedAttempts(userId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incorrect PIN! Try "1234"'),
              backgroundColor: const Color(0xFFFF3B30),
            ),
          );
          setState(() {
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _handleForgotPin() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Show confirmation dialog before launching Google Sign-In reset
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        title: const Text('Reset PIN?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'To reset your PIN, you must verify your identity by signing in to your Google Account.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final googleSignIn = ref.read(googleSignInProvider);
      // Force account selection to ensure fresh re-authentication
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account != null) {
        // Confirm that the signing-in user matches our active email session
        if (account.email == user.email) {
          final appLock = ref.read(appLockServiceProvider);
          await appLock.removePin(user.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Identity verified. Please set up a new PIN.'),
                backgroundColor: Color(0xFF0066FF),
              ),
            );
            // Redirect to onboarding page (so they configure their new PIN)
            ref.read(onboardingCompletedProvider.notifier).state = false;
            context.go('/onboarding');
          }
        } else {
          throw Exception('The Google account does not match the active session profile.');
        }
      } else {
        throw Exception('Google verification cancelled.');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F1A1C),
            title: const Text('Verification Failed', style: TextStyle(color: Colors.white)),
            content: Text(
              e.toString().replaceAll('Exception:', '').trim(),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050E1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final remainingSecondsText = _lockoutSecondsLeft > 60
        ? '${(_lockoutSecondsLeft / 60).ceil()}m'
        : '${_lockoutSecondsLeft}s';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1A), Color(0xFF050505)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.35),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLockedOut ? Icons.gpp_bad_rounded : Icons.lock_outline_rounded,
                      color: _isLockedOut ? Colors.redAccent : const Color(0xFF00E5FF),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLockedOut ? 'SECURITY LOCKOUT' : 'SECURITY LOCK',
                    style: TextStyle(
                      color: _isLockedOut ? Colors.redAccent : const Color(0xFF00E5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLockedOut
                        ? 'Too many failed attempts. Try again in $remainingSecondsText'
                        : 'Enter PIN to unlock Expenso',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final active = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? const Color(0xFF00E5FF) : Colors.transparent,
                      border: Border.all(
                        color: active ? const Color(0xFF0066FF) : Colors.white30,
                        width: 1.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildKeypadButton('1'),
                          _buildKeypadButton('2'),
                          _buildKeypadButton('3'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildKeypadButton('4'),
                          _buildKeypadButton('5'),
                          _buildKeypadButton('6'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildKeypadButton('7'),
                          _buildKeypadButton('8'),
                          _buildKeypadButton('9'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: _isLockedOut ? null : _authenticateWithBiometrics,
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                color: _isLockedOut ? Colors.white10 : const Color(0xFF00E5FF),
                                size: 28,
                              ),
                            ),
                          ),
                          _buildKeypadButton('0'),
                          GestureDetector(
                            onTap: _onBackspace,
                            child: Container(
                              height: 60,
                              width: 60,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: const Icon(Icons.backspace_outlined, color: Colors.white60, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              TextButton(
                onPressed: _handleForgotPin,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    final disabled = _isLockedOut;
    return GestureDetector(
      onTap: disabled ? null : () => _onKeyPress(digit),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: disabled ? Colors.white.withOpacity(0.01) : Colors.white.withOpacity(0.02),
          shape: BoxShape.circle,
          border: Border.all(
            color: disabled ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              color: disabled ? Colors.white24 : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
