import '../../../../core/database/app_database.dart';

/// Extension on [Account] providing standardized display titles and subtitles.
extension AccountDisplayExtension on Account {
  /// Single Source of Truth for Account Display Title.
  /// Examples: "Cash", "Google Pay", "SBI 8589", "ICICI 1254", "HDFC", "Axis 6935"
  String get displayTitle => formatAccountTitle(this);

  /// Single Source of Truth for Account Display Subtitle.
  /// Examples: "Cash", "Wallet", "Savings Account", "Current Account", "Credit Card"
  String get displaySubtitle => getAccountSubtitle(this);

  /// Formatted title with optional emoji icon prefix.
  String displayTitleWithEmoji({bool includeEmoji = true}) => formatAccountTitle(this, includeEmoji: includeEmoji);
}

/// Sanitizes raw account names by stripping internal terms like "Savings", "Credit Card", "****", etc.
String sanitizeAccountName(String name) {
  var clean = name.replaceAll(
    RegExp(r'\b(?:savings|current|salary|debit|credit\s+card|credit|card|account|a/c|upi|wallet|wallet\s+account|bank)\b', caseSensitive: false),
    '',
  );
  clean = clean.replaceAll('****', '');
  clean = clean.replaceAll(RegExp(r'\s+-\s*'), ' ');
  clean = clean.replaceAll('-', ' ');
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  if (clean.isEmpty) {
    clean = name.replaceAll('****', '').trim();
  }

  // Deduplicate consecutive identical words or repeated 4-digit account numbers (e.g. "SBI 8589 8589" -> "SBI 8589")
  final words = clean.split(' ');
  final resultWords = <String>[];
  for (var word in words) {
    if (word.isEmpty) continue;
    if (resultWords.contains(word) && RegExp(r'^\d{4}$').hasMatch(word)) {
      continue;
    }
    if (resultWords.isNotEmpty && resultWords.last.toLowerCase() == word.toLowerCase()) {
      continue;
    }
    resultWords.add(word);
  }
  
  return resultWords.join(' ');
}

/// Formats account display title ensuring standard format like "<Bank Name> <Last 4 Digits>".
String formatAccountTitle(Account acc, {bool includeEmoji = false}) {
  if (acc.type == 'cash') {
    return includeEmoji ? '👛 Cash' : 'Cash';
  }

  String prefixEmoji = '🏦';
  if (acc.type == 'credit_card') {
    prefixEmoji = '💳';
  } else if (acc.type == 'wallet' || acc.type == 'upi_wallet' || acc.type == 'digital_wallet') {
    prefixEmoji = '👛';
  }

  final String cleanName = sanitizeAccountName(acc.name);
  final String? last4 = acc.last4Digits;

  String title = cleanName;
  if (last4 != null && last4.isNotEmpty && last4 != 'XXXX') {
    final has4DigitsInName = RegExp(r'\b\d{4}\b').hasMatch(cleanName);
    if (!cleanName.contains(last4) && !has4DigitsInName) {
      title = '$cleanName $last4';
    }
  }

  if (includeEmoji) {
    return '$prefixEmoji $title';
  }
  return title;
}

/// Helper for raw string properties formatting when full [Account] object is unavailable.
String formatAccountTitleFromRaw({
  required String name,
  String? type,
  String? last4Digits,
  bool includeEmoji = false,
}) {
  if (type == 'cash' || name.toLowerCase() == 'cash' || name.toLowerCase() == 'cash wallet') {
    return includeEmoji ? '👛 Cash' : 'Cash';
  }

  String prefixEmoji = '🏦';
  if (type == 'credit_card') {
    prefixEmoji = '💳';
  } else if (type == 'wallet' || type == 'upi_wallet' || type == 'digital_wallet') {
    prefixEmoji = '👛';
  }

  final String cleanName = sanitizeAccountName(name);
  String title = cleanName;

  if (last4Digits != null && last4Digits.isNotEmpty && last4Digits != 'XXXX') {
    final has4DigitsInName = RegExp(r'\b\d{4}\b').hasMatch(cleanName);
    if (!cleanName.contains(last4Digits) && !has4DigitsInName) {
      title = '$cleanName $last4Digits';
    }
  }

  if (includeEmoji) {
    return '$prefixEmoji $title';
  }
  return title;
}

/// Safely formats credit card amounts ensuring no double minus sign (--₹...) occurs.
String formatCreditCardAmount(String text) {
  final clean = text.replaceAll('-', '').replaceAll('–', '').replaceAll('—', '').replaceAll('−', '').trim();
  if (clean.isEmpty || clean == '₹0.00' || clean == '0' || clean == '0.00') {
    return '₹0.00';
  }
  return '-$clean';
}

/// Generates a consistent subtitle for each account type.
String getAccountSubtitle(Account acc) {
  return getAccountSubtitleFromType(acc.type);
}

/// Generates a consistent subtitle from an account type string.
String getAccountSubtitleFromType(String? type) {
  if (type == null || type.isEmpty) return 'Account';
  final lower = type.toLowerCase();
  
  if (lower == 'credit_card') return 'Credit Card';
  if (lower == 'cash') return 'Cash';
  if (lower == 'wallet' || lower == 'upi_wallet' || lower == 'digital_wallet') return 'Wallet';
  
  switch (lower) {
    case 'savings':
      return 'Savings Account';
    case 'current':
      return 'Current Account';
    case 'salary':
      return 'Salary Account';
    case 'loan':
    case 'loan_account':
      return 'Loan Account';
    case 'investment':
    case 'fixed_deposit':
    case 'gold':
    case 'crypto':
      return 'Investment';
    default:
      final formatted = type.replaceAll('_', ' ').trim();
      if (formatted.toLowerCase().endsWith('account')) {
        return formatted.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
      }
      return '${formatted.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')} Account';
  }
}


