import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          'Privacy Policy',
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: const GlassCard(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
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
                          '1. Information We Collect\n'
                          'We collect information to provide a better, smarter financial tracking experience. This includes:\n'
                          '• Account Information: Your email, name, and profile details provided by Google Auth.\n'
                          '• Financial Data: Transactions, budgets, and categories you input.\n'
                          '• SMS Details: With your explicit permission, we parse financial SMS notifications locally on your device to create automated expense entries.\n\n'
                          '2. How We Use Information\n'
                          'We use your data strictly to:\n'
                          '• Process and display your financial summaries.\n'
                          '• Provide AI-powered spending insights and predictions.\n'
                          '• Back up your databases securely to your private Google Drive AppData folder.\n\n'
                          '3. Data Protection & Privacy Commitment\n'
                          '• We NEVER post to your social media or external accounts without your explicit permission.\n'
                          '• We NEVER sell or share your financial transactions with third-party advertising companies.\n'
                          '• All data transmission is encrypted using industry-standard SSL/TLS protocols.\n\n'
                          '4. Permissions\n'
                          'The app request access to:\n'
                          '• SMS inbox (Android only) for automated expense logging.\n'
                          '• Local authentication (biometrics) to secure app entry.\n'
                          'You can enable or disable these permissions at any time via your device settings.\n\n'
                          '5. Data Retention & Deletion\n'
                          'You can request deletion of your account and associated synced cloud databases at any time. Local databases can be cleared by uninstalling the application or purging cache files.\n\n'
                          '6. Contact Us\n'
                          'If you have any questions or feedback regarding our privacy practices, please contact our support team.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
                  child: const Text('I Agree'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
