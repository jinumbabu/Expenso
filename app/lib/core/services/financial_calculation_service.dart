import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';

class FinancialData {
  final int openingBalance;
  final int monthlyIncome;
  final int monthlyExpenses;
  final int netWorth; // closing balance

  const FinancialData({
    required this.openingBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netWorth,
  });
}

class AccountSummary {
  final int totalAssets;
  final int totalLiabilities;
  final int netAssets; // Net Worth!
  final int cashBalance;
  final int bankBalance;
  final int walletBalance;
  final int ccOutstanding;
  final int investmentBalance;
  final int loanOutstanding;

  const AccountSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netAssets,
    required this.cashBalance,
    required this.bankBalance,
    required this.walletBalance,
    required this.ccOutstanding,
    required this.investmentBalance,
    required this.loanOutstanding,
  });
}

class FinancialCalculationService {
  /// Checks if a transaction is categorized as Income.
  static bool isIncome(Transaction tx) {
    final type = tx.type.toLowerCase();
    return type == 'income' || 
           type == 'salary' || 
           type == 'refund' || 
           type == 'cashback' || 
           type == 'interest' || 
           type == 'deposit' || 
           type == 'cash_deposit' ||
           type == 'reward' || 
           type == 'dividend' || 
           type == 'reversal';
  }

  /// Checks if a transaction is categorized as Expense.
  static bool isExpense(Transaction tx) {
    final type = tx.type.toLowerCase();
    return type == 'expense' || 
           type == 'purchase' || 
           type == 'withdrawal' || 
           type == 'atm' || 
           type == 'fees' || 
           type == 'investment' || 
           type == 'loan_payment' ||
           type == 'credit_card_purchase' || 
           type == 'loan_emi' || 
           type == 'subscription' || 
           type == 'debit_card_purchase' || 
           type == 'recharge' || 
           type == 'insurance' || 
           type == 'tax';
  }

  /// Checks if a transaction is a Credit (increases asset balance or reduces credit card outstanding).
  static bool isCredit(Transaction tx, String accountId) {
    final type = tx.type.toLowerCase();
    final isSource = tx.accountId == accountId;
    final isDest = tx.referenceNumber == accountId;

    if (isSource) {
      return type == 'income' || 
             type == 'salary' || 
             type == 'refund' || 
             type == 'cashback' || 
             type == 'interest' || 
             type == 'transfer_in' || 
             type == 'cash_deposit' ||
             type == 'deposit' || 
             type == 'reward' || 
             type == 'dividend' || 
             type == 'reversal' ||
             type == 'transfer_credit' || 
             type == 'credit_card_payment_credit';
    } else if (isDest) {
      return type == 'transfer' || 
             type == 'credit_card_payment' || 
             type == 'transfer_in';
    }
    return false;
  }

  /// Checks if a transaction is a Debit (decreases asset balance or increases credit card outstanding).
  static bool isDebit(Transaction tx, String accountId) {
    final type = tx.type.toLowerCase();
    final isSource = tx.accountId == accountId;

    if (isSource) {
      return type == 'expense' || 
             type == 'purchase' || 
             type == 'withdrawal' || 
             type == 'transfer_out' || 
             type == 'atm' || 
             type == 'fees' || 
             type == 'investment' || 
             type == 'loan_payment' ||
             type == 'credit_card_purchase' || 
             type == 'loan_emi' || 
             type == 'subscription' || 
             type == 'debit_card_purchase' || 
             type == 'recharge' || 
             type == 'insurance' || 
             type == 'tax' ||
             type == 'transfer_debit' || 
             type == 'credit_card_payment_debit' ||
             type == 'transfer' || 
             type == 'credit_card_payment';
    }
    return false;
  }

  /// Calculates the opening balance, monthly income, monthly expenses, and net worth
  /// for a given month based on all transactions.
  static FinancialData calculate({
    required List<Transaction> transactions,
    required DateTime selectedMonth,
  }) {
    final startOfSelectedMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfSelectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));

    int openingIncome = 0;
    int openingExpense = 0;
    int currentIncome = 0;
    int currentExpense = 0;

    for (var tx in transactions) {
      final date = tx.date;
      final isInc = isIncome(tx);
      final isExp = isExpense(tx);

      if (date.isBefore(startOfSelectedMonth)) {
        if (isInc) {
          openingIncome += tx.amount.toInt();
        } else if (isExp) {
          openingExpense += tx.amount.toInt();
        }
      } else if (date.isBefore(endOfSelectedMonth)) {
        if (isInc) {
          currentIncome += tx.amount.toInt();
        } else if (isExp) {
          currentExpense += tx.amount.toInt();
        }
      }
    }

    final openingBalance = openingIncome - openingExpense;
    final netWorth = openingBalance + currentIncome - currentExpense;

    return FinancialData(
      openingBalance: openingBalance,
      monthlyIncome: currentIncome,
      monthlyExpenses: currentExpense,
      netWorth: netWorth,
    );
  }

  /// Centralized calculation engine for Net Worth, Assets, Liabilities, and Balances across accounts.
  /// Net Worth = (Cash + Wallets + Bank Accounts + Investments + Fixed Deposits) - (Credit Card Outstanding + Loans)
  static AccountSummary calculateAccountSummary(List<Account> accounts) {
    int totalAssets = 0;
    int totalLiabilities = 0;
    int cash = 0;
    int bank = 0;
    int wallet = 0;
    int ccOutstanding = 0;
    int investment = 0;
    int loan = 0;

    for (var acc in accounts) {
      if (acc.isActive == false) continue;

      final type = acc.type.toLowerCase();
      final balance = acc.balance;

      if (type == 'credit_card') {
        final outstanding = acc.outstandingBalance ?? (balance < 0 ? -balance : balance);
        totalLiabilities += outstanding;
        ccOutstanding += outstanding;
      } else if (type == 'loan' || type == 'loan_account') {
        final outstanding = balance < 0 ? -balance : balance;
        totalLiabilities += outstanding;
        loan += outstanding;
      } else {
        totalAssets += balance;

        if (type == 'cash') {
          cash += balance;
        } else if (type == 'savings' || type == 'current' || type == 'salary' || type == 'debit_card' || type == 'bank') {
          bank += balance;
        } else if (type == 'wallet' || type == 'upi_wallet' || type == 'digital_wallet') {
          wallet += balance;
        } else if (type == 'investment' || type == 'fixed_deposit' || type == 'fd' || type == 'gold' || type == 'crypto' || type == 'cryptocurrency_wallet' || type == 'term_deposit' || type == 'stock' || type == 'mutual_fund') {
          investment += balance;
        } else {
          bank += balance;
        }
      }
    }

    return AccountSummary(
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netAssets: totalAssets - totalLiabilities, // Net Worth = Assets - Liabilities
      cashBalance: cash,
      bankBalance: bank,
      walletBalance: wallet,
      ccOutstanding: ccOutstanding,
      investmentBalance: investment,
      loanOutstanding: loan,
    );
  }

  /// Dynamically calculates the correct current balance for a single account from transaction records.
  static Account calculateSingleAccountBalance(Account account, List<Transaction> transactions) {
    final hasVerified = account.verifiedBalance != null && account.verifiedAt != null;
    final int baseBalance = hasVerified ? account.verifiedBalance! : (account.openingBalance ?? 0);

    int sumDebits = 0;
    int sumCredits = 0;
    int transferIn = 0;
    int transferOut = 0;

    for (var tx in transactions) {
      if (tx.deletedAt != null) continue;

      final isSource = tx.accountId == account.id;
      final isDest = tx.referenceNumber == account.id;
      if (!isSource && !isDest) continue;

      if (hasVerified && !tx.date.isAfter(account.verifiedAt!)) {
        continue;
      }

      final amount = tx.amount.toInt();
      final txIsCredit = isCredit(tx, account.id);
      final txIsDebit = isDebit(tx, account.id);

      if (txIsDebit) {
        sumDebits += amount;
      } else if (txIsCredit) {
        sumCredits += amount;
      }

      // Check if it's a transfer type
      final type = tx.type.toLowerCase();
      final isTransfer = type.contains('transfer') || type.contains('credit_card_payment');
      if (isTransfer) {
        if (txIsCredit) {
          transferIn += amount;
        } else if (txIsDebit) {
          transferOut += amount;
        }
      }
    }

    int newBal;
    int? newOutstanding;
    if (account.type == 'credit_card') {
      final int baseOutstanding = hasVerified ? account.verifiedBalance! : (account.openingBalance ?? 0);
      newOutstanding = baseOutstanding + sumDebits - sumCredits;
      newBal = -newOutstanding;
    } else {
      newBal = baseBalance + sumCredits - sumDebits;
    }

    final storedBalance = account.balance;
    final expectedBalance = account.type == 'credit_card' ? (newOutstanding ?? 0) : newBal;
    final displayedBalance = account.type == 'credit_card' ? (account.outstandingBalance ?? 0) : storedBalance;

    print('''
========================================================
FINANCIAL ENGINE AUDIT LOG: ${account.name}
========================================================
Account Name:             ${account.name}
Opening Balance:          ${account.openingBalance ?? 0}
Verified Balance:         ${account.verifiedBalance ?? 'N/A'}
Verification Date:        ${account.verifiedAt ?? 'N/A'}
Total Credits:            $sumCredits
Total Debits:             $sumDebits
Transfer In:              $transferIn
Transfer Out:             $transferOut
Calculated Balance:       $expectedBalance
Stored Database Balance:  $storedBalance
Displayed UI Balance:     $displayedBalance
Net Worth Contribution:   $newBal
${expectedBalance != displayedBalance ? 'Mismatch detected' : 'No mismatch'}
========================================================
''');

    if (account.type == 'credit_card') {
      final int limit = account.creditLimit ?? 0;
      return account.copyWith(
        outstandingBalance: Value(newOutstanding),
        balance: newBal,
        availableCredit: Value((limit - (newOutstanding ?? 0)).clamp(0, limit)),
      );
    } else {
      return account.copyWith(
        balance: newBal,
        calculatedBalance: Value(newBal),
      );
    }
  }
}
