import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied link: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI CHAT HELP',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1D), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Guides, tutorials, and security FAQs for your Expenso AI integration.',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            _buildSectionTitle('FREQUENTLY ASKED QUESTIONS'),
            const SizedBox(height: 12),
            _buildFaqItem(
              question: 'What is an API Key?',
              answer: 'An API Key is a unique identifier (passcode) used to authenticate requests to AI model providers. It allows Expenso to send prompt messages and retrieve conversational replies directly from providers.',
            ),
            _buildFaqItem(
              question: 'Why is it required?',
              answer: 'To protect user privacy and avoid central subscription fees, Expenso operates using a bring-your-own-key (BYOK) model. Instead of paying a markup, you run the requests directly against the AI companies using your own developer accounts.',
            ),
            _buildFaqItem(
              question: 'Is my API key secure?',
              answer: 'Absolutely. Your keys are stored locally on your device in the encrypted FlutterSecureStorage vault. They are never transmitted to Expenso or any third party except when making direct, encrypted HTTPS requests to the AI providers.',
            ),
            _buildFaqItem(
              question: 'How does Expenso use my API?',
              answer: 'Expenso compiles a brief de-identified financial summary (e.g. current balance, upcoming bills, top spending categories) from your local database and appends it to your prompt as context, enabling context-aware financial advice.',
            ),
            _buildFaqItem(
              question: 'Does Expenso store my conversations?',
              answer: 'No. Conversation histories are stored entirely on your local device. Expenso servers never inspect, store, or train models on your data.',
            ),
            _buildFaqItem(
              question: 'Offline vs Online AI',
              answer: 'Offline AI executes a set of local rule-based diagnostics without sending data over the internet, while Online AI connects to state-of-the-art LLMs (Gemini, Claude, GPT) to provide conversational responses and deep analysis.',
            ),
            _buildFaqItem(
              question: 'Which model should I choose?',
              answer: 'For fast, cost-efficient, and general queries, choose Flash or Mini models (e.g. Gemini 2.5 Flash, Llama 4). For complex analysis, reasoning, and multi-step math, choose Pro or Reasoner models (e.g. Gemini 2.5 Pro, Claude Opus 4, DeepSeek Reasoner).',
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('PROVIDER TUTORIALS'),
            const SizedBox(height: 12),
            _buildTutorialCard(
              context: context,
              providerName: 'Google Gemini',
              url: 'https://aistudio.google.com/',
              steps: [
                '1. Go to Google AI Studio (aistudio.google.com).',
                '2. Sign in with your Google account.',
                '3. Click on "Get API key" in the sidebar.',
                '4. Create a new key and copy it into Expenso.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'OpenAI',
              url: 'https://platform.openai.com/api-keys',
              steps: [
                '1. Sign in to the OpenAI Developer Platform.',
                '2. Navigate to "API Keys" section under Settings.',
                '3. Click "Create new secret key".',
                '4. Give it a name and copy the key into Expenso.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'Anthropic Claude',
              url: 'https://console.anthropic.com/',
              steps: [
                '1. Create or sign in to Anthropic Console.',
                '2. Go to "API Keys" page.',
                '3. Click "Create Key".',
                '4. Copy the generated key securely.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'Groq',
              url: 'https://console.groq.com/keys',
              steps: [
                '1. Sign in to Groq Console.',
                '2. Click on "API Keys" in the navigation menu.',
                '3. Select "Create API Key".',
                '4. Copy the key.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'OpenRouter',
              url: 'https://openrouter.ai/keys',
              steps: [
                '1. Open openrouter.ai and sign up.',
                '2. Click on your profile icon and select "Keys".',
                '3. Click "Create Key".',
                '4. Copy the OpenRouter key.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'DeepSeek',
              url: 'https://platform.deepseek.com/',
              steps: [
                '1. Register or log in at DeepSeek Platform.',
                '2. Navigate to "API Keys".',
                '3. Generate a new API Key.',
                '4. Copy the generated key.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'Together AI',
              url: 'https://api.together.xyz/settings/api-keys',
              steps: [
                '1. Visit Together AI Console and sign up.',
                '2. Go to Settings -> API Keys.',
                '3. Create or copy the default API Key.',
                '4. Input the Together AI key in Expenso.',
              ],
            ),
            _buildTutorialCard(
              context: context,
              providerName: 'Mistral',
              url: 'https://console.mistral.ai/',
              steps: [
                '1. Access Mistral Console and log in.',
                '2. Go to "API Keys" manager.',
                '3. Create a new key.',
                '4. Copy the key.',
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.tealAccent,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconColor: Colors.tealAccent,
        collapsedIconColor: Colors.white30,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard({
    required BuildContext context,
    required String providerName,
    required String url,
    required List<String> steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(Icons.vpn_key_outlined, color: Colors.tealAccent.withOpacity(0.8), size: 20),
              const SizedBox(width: 12),
              Text(
                providerName,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          iconColor: Colors.tealAccent,
          collapsedIconColor: Colors.white30,
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          expandedAlignment: Alignment.topLeft,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        step,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                      ),
                    )),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _copyToClipboard(context, url),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Copy Link',
                          style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy, color: Colors.tealAccent, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
