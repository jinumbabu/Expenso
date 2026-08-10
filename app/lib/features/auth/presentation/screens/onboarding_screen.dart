import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/security/app_lock_service.dart';
import '../../../backup/presentation/providers/backup_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // PIN step states
  int _selectedPinLength = 4;
  String _pin = '';
  String _confirmPin = '';
  bool _pinError = false;

  // Biometrics states
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;

  // Permissions states
  bool _smsGranted = false;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceCapabilities();
  }

  Future<void> _checkDeviceCapabilities() async {
    final appLock = ref.read(appLockServiceProvider);
    final bioAvail = await appLock.canUseBiometrics();
    
    final smsStatus = await Permission.sms.status;
    final notifStatus = await Permission.notification.status;

    setState(() {
      _biometricsSupported = bioAvail;
      _smsGranted = smsStatus.isGranted;
      _notifGranted = notifStatus.isGranted;
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentStep++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.heavyImpact();
    final user = ref.read(authProvider).user;
    if (user != null) {
      // Save PIN
      final appLock = ref.read(appLockServiceProvider);
      await appLock.savePin(user.id, _pin, length: _selectedPinLength);
      await appLock.setBiometricEnabled(user.id, _biometricsEnabled);
      
      // Mark onboarding as completed
      await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: List.generate(_totalSteps, (index) {
                    final active = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF00E5FF) : Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildStepContent(),
                  ),
                ),
              ),

              // Bottom navigation actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _prevStep,
                        child: const Text('Back', style: TextStyle(color: Colors.white54, fontSize: 15)),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: _isNextEnabled() ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white30,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1 ? 'Get Started' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
  }

  bool _isNextEnabled() {
    switch (_currentStep) {
      case 0:
        // Permissions
        return true;
      case 1:
        // PIN Setup
        return _pin.length == _selectedPinLength && _confirmPin == _pin;
      case 2:
        // Biometrics Setup
        return true;
      case 3:
        // Cloud Backup
        return true;
      default:
        return false;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPermissionsStep();
      case 1:
        return _buildPinStep();
      case 2:
        return _buildBiometricsStep();
      case 3:
        return _buildBackupStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Permissions ---
  Widget _buildPermissionsStep() {
    return Column(
      key: const ValueKey('step_permissions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'SETUP PERMISSIONS',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Allow permissions for complete financial tracking',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        _buildPermissionTile(
          icon: Icons.sms_outlined,
          title: 'SMS Access',
          description: 'Allows Expenso to read bank transaction SMS messages and automatically categorize them with zero manual effort.',
          granted: _smsGranted,
          onRequest: () async {
            final res = await Permission.sms.request();
            setState(() {
              _smsGranted = res.isGranted;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildPermissionTile(
          icon: Icons.notifications_none_outlined,
          title: 'Push Notifications',
          description: 'Used for daily budgets thresholds, payment reminders, and sync warnings.',
          granted: _notifGranted,
          onRequest: () async {
            final res = await Permission.notification.request();
            setState(() {
              _notifGranted = res.isGranted;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required VoidCallback onRequest,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (granted ? const Color(0xFF00E5FF) : const Color(0xFF0066FF)).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: granted ? const Color(0xFF00E5FF) : Colors.white60, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: granted ? null : onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    disabledBackgroundColor: Colors.white.withOpacity(0.04),
                    disabledForegroundColor: const Color(0xFF00E5FF),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    granted ? '✓ Granted' : 'Grant Permission',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: PIN Setup ---
  Widget _buildPinStep() {
    return Column(
      key: const ValueKey('step_pin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'SECURE YOUR DATA',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create your secure App Lock PIN',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPinLengthTab(4),
            const SizedBox(width: 16),
            _buildPinLengthTab(6),
          ],
        ),
        const SizedBox(height: 24),

        // PIN Input Fields
        const Text('Enter PIN:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        _buildPinInputRow(_pin),
        const SizedBox(height: 24),

        const Text('Confirm PIN:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        _buildPinInputRow(_confirmPin),
        
        if (_pinError) ...[
          const SizedBox(height: 12),
          const Text(
            'PINs do not match. Please try again.',
            style: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],

        const SizedBox(height: 24),
        // Simple Virtual Numeric Pad inside the step content
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                if (index == 9) {
                  return TextButton(
                    onPressed: () {
                      setState(() {
                        _pin = '';
                        _confirmPin = '';
                        _pinError = false;
                      });
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.white54)),
                  );
                }
                if (index == 11) {
                  return IconButton(
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white60),
                    onPressed: () {
                      setState(() {
                        if (_confirmPin.isNotEmpty) {
                          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                        } else if (_pin.isNotEmpty) {
                          _pin = _pin.substring(0, _pin.length - 1);
                        }
                        _pinError = false;
                      });
                    },
                  );
                }
                final digit = index == 10 ? '0' : '${index + 1}';
                return ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_pin.length < _selectedPinLength) {
                        _pin += digit;
                      } else if (_confirmPin.length < _selectedPinLength) {
                        _confirmPin += digit;
                      }

                      if (_pin.length == _selectedPinLength && _confirmPin.length == _selectedPinLength) {
                        if (_pin != _confirmPin) {
                          _pinError = true;
                          _confirmPin = '';
                        } else {
                          _pinError = false;
                        }
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.03),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(digit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinLengthTab(int length) {
    final active = _selectedPinLength == length;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPinLength = length;
          _pin = '';
          _confirmPin = '';
          _pinError = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          '$length Digit PIN',
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPinInputRow(String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_selectedPinLength, (index) {
        final filled = index < value.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          height: 14,
          width: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(0xFF00E5FF) : Colors.white12,
            border: Border.all(color: filled ? const Color(0xFF0066FF) : Colors.transparent),
          ),
        );
      }),
    );
  }

  // --- Step 3: Biometrics Setup ---
  Widget _buildBiometricsStep() {
    return Column(
      key: const ValueKey('step_biometrics'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'BIOMETRIC UNLOCK',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enable instant access with Biometrics',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF00E5FF), size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock with Fingerprint or Face',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Use your device biometrics for secure, fast authentication. No need to type your PIN every time you launch the app.',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              if (_biometricsSupported)
                SwitchListTile(
                  title: const Text('Biometric Unlock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Use biometrics to unlock the app', style: TextStyle(color: Colors.white54)),
                  value: _biometricsEnabled,
                  activeColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
                  onChanged: (val) {
                    setState(() {
                      _biometricsEnabled = val;
                    });
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Biometric sensors are not configured or supported on this device.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 4: Cloud Backup Setup ---
  Widget _buildBackupStep() {
    return Column(
      key: const ValueKey('step_backup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'SECURE BACKUPS',
          style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'Configure Google Drive Backups',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Encrypted Cloud Sync', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Back up your databases securely to your personal Google Drive in the app\'s sandboxed space.\nAll backup files are encrypted with AES-256 before leaving your device.',
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(backupNotifierProvider.notifier).loadBackupInfo();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Drive Backup connection established!'),
                          backgroundColor: Color(0xFF0066FF),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to connect: $e'),
                          backgroundColor: const Color(0xFFFF3B30),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Connect Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
