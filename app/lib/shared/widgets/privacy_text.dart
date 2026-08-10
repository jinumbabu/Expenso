import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/providers/hide_balance_provider.dart';
import '../../features/dashboard/presentation/providers/privacy_provider.dart';

class PrivacyText extends ConsumerStatefulWidget {
  final String rawValue;
  final TextStyle style;
  final String mask;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isNetWorth;
  final bool isAccountBalance;
  final bool isTransactionAmount;
  final bool isAnalyticsAmount;
  final bool isDashboard;
  final bool isAccountDetail;
  final bool isCard;

  const PrivacyText({
    super.key,
    required this.rawValue,
    required this.style,
    this.mask = '₹ ••••••',
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isNetWorth = false,
    this.isAccountBalance = false,
    this.isTransactionAmount = false,
    this.isAnalyticsAmount = false,
    this.isDashboard = false,
    this.isAccountDetail = false,
    this.isCard = false,
  });

  @override
  ConsumerState<PrivacyText> createState() => _PrivacyTextState();
}

class _PrivacyTextState extends ConsumerState<PrivacyText> {
  bool _tempReveal = false;

  @override
  Widget build(BuildContext context) {
    final hideState = ref.watch(hideBalanceProvider);
    final globalPrivate = ref.watch(privacyModeProvider);

    // Determine if this specific text should be masked based on its type
    bool shouldMask = globalPrivate;
    if (!shouldMask) {
      if (widget.isNetWorth) {
        shouldMask = hideState.hideNetWorth || hideState.hideDashboard;
      } else if (widget.isAccountBalance) {
        shouldMask = hideState.hideAccountBalances || hideState.hideNetWorth;
      } else if (widget.isTransactionAmount) {
        shouldMask = hideState.hideTransactionAmounts || hideState.hideNetWorth;
      } else if (widget.isAnalyticsAmount) {
        shouldMask = hideState.hideAnalyticsAmounts || hideState.hideNetWorth;
      } else if (widget.isDashboard) {
        shouldMask = hideState.hideDashboard || hideState.hideNetWorth;
      } else if (widget.isAccountDetail) {
        shouldMask = hideState.hideAccountDetails || hideState.hideNetWorth;
      } else if (widget.isCard) {
        shouldMask = hideState.hideCards || hideState.hideAccountBalances || hideState.hideNetWorth;
      } else {
        // For legacy compatibility, default to hideNetWorth || hideDashboard
        shouldMask = hideState.hideNetWorth || hideState.hideDashboard;
      }
    }

    final displayMasked = shouldMask && !_tempReveal;

    return GestureDetector(
      onLongPressStart: (_) {
        if (shouldMask) {
          setState(() {
            _tempReveal = true;
          });
        }
      },
      onLongPressEnd: (_) {
        if (shouldMask) {
          setState(() {
            _tempReveal = false;
          });
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          displayMasked ? widget.mask : widget.rawValue,
          key: ValueKey<String>('${displayMasked ? "masked" : "raw"}_${widget.rawValue}'),
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        ),
      ),
    );
  }
}
