import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_card.dart';

class MainLayoutScreen extends StatefulWidget {
  final Widget child;

  const MainLayoutScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit.'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF0F1A1C),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 100, left: 24, right: 24),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        extendBody: false, // Crucial to prevent content from scrolling behind/underneath
        body: widget.child,
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF050505).withOpacity(0.65),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.22),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context: context,
                      isSelected: false,
                      icon: Icons.account_balance_outlined,
                      activeIcon: Icons.account_balance,
                      label: 'Account',
                      onTap: () => context.push('/accounts'),
                    ),
                    _buildNavItem(
                      context: context,
                      isSelected: false,
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet,
                      label: 'Transaction',
                      onTap: () => context.push('/expenses'),
                    ),
                    // Center Floating Action Button
                    GestureDetector(
                      onTap: () => context.push('/expenses/add'),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066FF), Color(0xFF00E5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    _buildNavItem(
                      context: context,
                      isSelected: false,
                      icon: Icons.pie_chart_outline_outlined,
                      activeIcon: Icons.pie_chart_rounded,
                      label: 'Analytics',
                      onTap: () => context.push('/analytics'),
                    ),
                    _buildNavItem(
                      context: context,
                      isSelected: false,
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'AI Chat',
                      onTap: () => context.push('/chat'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFF0066FF) : Colors.white54;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
