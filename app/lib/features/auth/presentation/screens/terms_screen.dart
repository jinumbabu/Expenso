import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_card.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GlassCard(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Last updated: June 25, 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                      Divider(color: Colors.white12, height: 24),
                      Text(
                        '1. Agreement to Terms\n'
                        'By using the Expenso application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.\n\n'
                        '2. Description of Service\n'
                        'Expenso is an AI-powered personal finance management tool that helps you track expenses, organize budgets, and gain insights into your financial health. The services are provided "as is" and are subject to change or discontinuation at any time.\n\n'
                        '3. Account Registration & Google Auth\n'
                        'You must authenticate using your Google account to use Expenso. You are responsible for maintaining the security of your account and all activities under it.\n\n'
                        '4. Privacy & Data Security\n'
                        'Your privacy is of the utmost importance to us. We store your data securely and use it strictly to provide and improve our services. We never post to your Google account or share your financial data without your permission.\n\n'
                        '5. AI Insights & Financial Advice\n'
                        'Expenso utilizes artificial intelligence to parse SMS data and provide budgets and predictions. These insights do not constitute official financial, legal, or investment advice. Always make financial decisions with caution.\n\n'
                        '6. User Conduct\n'
                        'You agree not to abuse, disrupt, or interfere with the service, its servers, or its security. Unauthorized access is strictly prohibited.\n\n'
                        '7. Limitation of Liability\n'
                        'Expenso, its developers, and partners shall not be liable for any financial losses, data leaks, or damages resulting from the use or inability to use the service.\n\n'
                        '8. Changes to Terms\n'
                        'We reserve the right to modify these terms at any time. Your continued use of the app constitutes acceptance of any changes.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('I Understand'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
