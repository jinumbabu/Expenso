import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import '../database/app_database.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class SubscriptionAgent {
  final AppDatabase _db;

  SubscriptionAgent(this._db);

  static const List<String> _knownSubscriptions = [
    'netflix',
    'spotify',
    'prime video',
    'amazon prime',
    'google one',
    'google storage',
    'icloud',
    'apple.com/bill',
    'apple services',
    'youtube premium',
    'gym membership',
    'fitness',
    'cult.fit',
    'lic',
    'insurance',
    'figma',
    'github',
    'openai',
    'chatgpt',
    'adobe',
    'zoom',
    'slack',
    'canva',
  ];

  /// Scans transactions to detect recurring billing profiles and saves them to the subscriptions table.
  Future<List<Subscription>> scanAndDetectSubscriptions(String userId) async {
    dev.log('SubscriptionAgent: Scanning transactions for recurring subscriptions for user $userId');
    
    // Fetch all transactions
    final txs = await _db.transactionDao.getTransactionsForUser(userId);
    final expenses = txs.where((t) => t.type == 'expense').toList();

    // Group transactions by normalized merchant name
    final Map<String, List<Transaction>> groupedExpenses = {};
    for (var tx in expenses) {
      final merchant = (tx.merchant ?? tx.description ?? '').trim().toLowerCase();
      if (merchant.isEmpty) continue;
      
      // Clean up common merchant names
      String normalized = merchant;
      for (var known in _knownSubscriptions) {
        if (merchant.contains(known)) {
          normalized = known;
          break;
        }
      }
      
      groupedExpenses[normalized] = groupedExpenses[normalized] ?? [];
      groupedExpenses[normalized]!.add(tx);
    }

    final List<Subscription> detectedSubs = [];
    final now = DateTime.now();

    for (var entry in groupedExpenses.entries) {
      final normalizedMerchant = entry.key;
      final merchantTxs = entry.value;

      // Sort transactions descending by date
      merchantTxs.sort((a, b) => b.date.compareTo(a.date));

      bool isSubscription = false;
      String billingCycle = 'monthly';
      double confidence = 0.5;
      int amountCents = merchantTxs.first.amount;

      // Check 1: Is it a known subscription merchant?
      final isKnown = _knownSubscriptions.any((known) => normalizedMerchant.contains(known));
      if (isKnown) {
        isSubscription = true;
        confidence = 0.80;
      }

      // Check 2: Do we have multiple transactions with recurring intervals?
      if (merchantTxs.length >= 2) {
        // Calculate gaps between consecutive transactions
        final List<int> gapsInDays = [];
        for (int i = 0; i < merchantTxs.length - 1; i++) {
          final diff = merchantTxs[i].date.difference(merchantTxs[i + 1].date).inDays;
          gapsInDays.add(diff);
        }

        // Calculate average gap
        final double avgGap = gapsInDays.reduce((a, b) => a + b) / gapsInDays.length;
        
        // Check if interval is monthly (25 - 35 days)
        if (avgGap >= 25 && avgGap <= 35) {
          isSubscription = true;
          billingCycle = 'monthly';
          confidence = 0.95;
        } 
        // Check if interval is annual (350 - 380 days)
        else if (avgGap >= 350 && avgGap <= 380) {
          isSubscription = true;
          billingCycle = 'annual';
          confidence = 0.95;
        }
        // General check: if standard deviation of amount is low, increase confidence
        final double avgAmt = merchantTxs.map((t) => t.amount).reduce((a, b) => a + b) / merchantTxs.length;
        bool amountsAreConsistent = true;
        for (var tx in merchantTxs) {
          if ((tx.amount - avgAmt).abs() > (avgAmt * 0.15)) {
            amountsAreConsistent = false;
            break;
          }
        }
        if (amountsAreConsistent && isSubscription) {
          confidence = (confidence + 0.05).clamp(0.0, 1.0);
        }
      }

      if (isSubscription) {
        final lastTxDate = merchantTxs.first.date;
        DateTime renewalDate;
        if (billingCycle == 'monthly') {
          renewalDate = lastTxDate.add(const Duration(days: 30));
        } else {
          renewalDate = lastTxDate.add(const Duration(days: 365));
        }

        // If next renewal date has already passed, set it to the next future renewal date
        while (renewalDate.isBefore(now)) {
          if (billingCycle == 'monthly') {
            renewalDate = renewalDate.add(const Duration(days: 30));
          } else {
            renewalDate = renewalDate.add(const Duration(days: 365));
          }
        }

        final int monthlyCost = billingCycle == 'monthly' ? amountCents : amountCents ~/ 12;
        final int annualCost = billingCycle == 'annual' ? amountCents : amountCents * 12;

        final subTitle = normalizedMerchant.split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
        }).join(' ');

        final sub = Subscription(
          id: const Uuid().v4(),
          userId: userId,
          title: subTitle,
          monthlyCost: monthlyCost,
          annualCost: annualCost,
          billingCycle: billingCycle,
          renewalDate: renewalDate,
          providerName: subTitle,
          confidence: confidence,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        );

        // Check if subscription already exists under the same title/user
        final existing = await _db.subscriptionDao.getSubscriptionsForUser(userId);
        final existingMatch = existing.where((s) => s.title.toLowerCase() == subTitle.toLowerCase()).toList();

        if (existingMatch.isNotEmpty) {
          // Update subscription details instead of duplicating
          final updatedSub = existingMatch.first.copyWith(
            monthlyCost: monthlyCost,
            annualCost: annualCost,
            billingCycle: billingCycle,
            renewalDate: renewalDate,
            confidence: confidence,
            updatedAt: now,
          );
          await _db.subscriptionDao.updateSubscription(updatedSub);
          detectedSubs.add(updatedSub);
        } else {
          await _db.subscriptionDao.insertSubscription(sub);
          detectedSubs.add(sub);
        }

        // Log the decision
        await _db.agentLogDao.insertLog(
          AgentLog(
            id: const Uuid().v4(),
            agentName: 'Subscription Detection Agent',
            actionType: 'SUBSCRIPTION_DETECTED',
            decisionDescription: 'Detected recurring subscription: "$subTitle". Billing cycle: $billingCycle, Monthly cost: ₹${(monthlyCost / 100.0).toStringAsFixed(2)}, Annual Cost: ₹${(annualCost / 100.0).toStringAsFixed(2)}. Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
            confidenceScore: confidence,
            timestamp: now,
          ),
        );
      }
    }

    return detectedSubs;
  }
}

final Provider<SubscriptionAgent> subscriptionAgentProvider = Provider<SubscriptionAgent>((ref) {
  final db = ref.watch(databaseProvider);
  return SubscriptionAgent(db);
});
