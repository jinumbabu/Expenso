import 'dart:io';

void main() {
  final clean = 'ICICI Statement Rs 1707 Due 08-Jul';
  String lower = clean.toLowerCase();

  // 1. Extract amount using regex.
  final amountRegex = RegExp(r'(?:rs\.?|₹|inr|\$)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
  final matches = amountRegex.allMatches(clean);

  print('Matches: ${matches.map((m) => m.group(0)).toList()}');

  double? amount;
  int amountMatchIndex = -1;

  for (int i = 0; i < matches.length; i++) {
    final m = matches.elementAt(i);
    final fullMatch = m.group(0)!.toLowerCase();
    if (fullMatch.contains('rs') || fullMatch.contains('₹') || fullMatch.contains('inr') || fullMatch.contains('\$')) {
      amount = double.tryParse(m.group(1) ?? '');
      amountMatchIndex = i;
      break;
    }
  }

  if (amount == null) {
    final m = matches.last;
    amount = double.tryParse(m.group(1) ?? '');
    amountMatchIndex = matches.length - 1;
  }

  print('Amount: $amount, Match Index: $amountMatchIndex');

  final matchTextToRemove = matches.elementAt(amountMatchIndex).group(0)!;
  String textWithoutAmount = clean.replaceAll(matchTextToRemove, '');
  lower = textWithoutAmount.toLowerCase();

  print('Text without amount: "$textWithoutAmount", lower: "$lower"');

  // Date parsing
  DateTime transactionDate = DateTime.now();
  String? dateTokenFound;
  final dateKeywords = [
    'last monday', 'last tuesday', 'last wednesday', 'last thursday', 'last friday', 'last saturday', 'last sunday',
    'next monday', 'next tuesday', 'next wednesday', 'next thursday', 'next friday', 'next saturday', 'next sunday',
    '2 days ago', '3 days ago', '4 days ago', '5 days ago', '6 days ago', '7 days ago',
    'last month', 'yesterday', 'tomorrow', 'today'
  ];

  for (var kw in dateKeywords) {
    if (lower.contains(kw)) {
      dateTokenFound = kw;
      break;
    }
  }

  const monthPattern = r'(?:jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)';

  if (dateTokenFound == null) {
    final dayMonthRegex = RegExp('\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+$monthPattern\\b', caseSensitive: false);
    final dmMatch = dayMonthRegex.firstMatch(lower);
    if (dmMatch != null) {
      dateTokenFound = dmMatch.group(0)!;
      print('Matched dayMonthRegex: $dateTokenFound');
    } else {
      final monthDayRegex = RegExp('\\b$monthPattern\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b', caseSensitive: false);
      final mdMatch = monthDayRegex.firstMatch(lower);
      if (mdMatch != null) {
        dateTokenFound = mdMatch.group(0)!;
        print('Matched monthDayRegex: $dateTokenFound');
      }
    }
  }

  print('dateTokenFound: $dateTokenFound');

  if (dateTokenFound != null) {
    textWithoutAmount = textWithoutAmount.replaceAll(RegExp('\\b$dateTokenFound\\b', caseSensitive: false), '');
    lower = textWithoutAmount.toLowerCase();
  }

  print('After date removal: lower: "$lower"');

  final hasStatement = lower.contains('statement');
  final hasDue = lower.contains('due');
  print('hasStatement: $hasStatement, hasDue: $hasDue');
}
