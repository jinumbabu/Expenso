import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/ai_models.dart';
import '../../../../core/services/ai_provider_orchestrator.dart';
import '../../../../shared/widgets/glass_card.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final Map<String, String> _providerDisplayNames = {
    'gemini': 'Google Gemini',
    'openai': 'OpenAI',
    'claude': 'Claude',
    'groq': 'Groq',
    'openrouter': 'OpenRouter',
    'deepseek': 'DeepSeek',
    'together': 'Together AI',
    'mistral': 'Mistral',
  };

  // Get available models for selected provider
  List<AIModel> _getModelsForProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return [
          const AIModel(id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash'),
          const AIModel(id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', isPremium: true),
          const AIModel(id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash'),
          const AIModel(id: 'gemini-2.0-flash-lite', name: 'Gemini 2.0 Flash Lite'),
        ];
      case 'openai':
        return [
          const AIModel(id: 'gpt-5', name: 'GPT-5', isPremium: true),
          const AIModel(id: 'gpt-5-mini', name: 'GPT-5 Mini'),
          const AIModel(id: 'gpt-5-nano', name: 'GPT-5 Nano'),
          const AIModel(id: 'gpt-4.1', name: 'GPT-4.1', isPremium: true),
          const AIModel(id: 'gpt-4.1-mini', name: 'GPT-4.1 Mini'),
        ];
      case 'claude':
        return [
          const AIModel(id: 'claude-4-sonnet', name: 'Claude Sonnet 4'),
          const AIModel(id: 'claude-4-opus', name: 'Claude Opus 4', isPremium: true),
        ];
      case 'groq':
        return [
          const AIModel(id: 'llama-4', name: 'Llama 4', isPremium: true),
          const AIModel(id: 'llama-3.3-70b-specdec', name: 'Llama 3.3 70B'),
          const AIModel(id: 'deepseek-r1-distill-llama-70b', name: 'DeepSeek R1'),
          const AIModel(id: 'qwen-2.5-coder-32b', name: 'Qwen'),
        ];
      case 'openrouter':
        return [
          const AIModel(id: 'google/gemini-2.5-pro', name: 'Gemini', isPremium: true),
          const AIModel(id: 'openai/gpt-4o', name: 'GPT'),
          const AIModel(id: 'anthropic/claude-3-5-sonnet', name: 'Claude'),
          const AIModel(id: 'deepseek/deepseek-chat', name: 'DeepSeek'),
          const AIModel(id: 'meta-llama/llama-3.1-70b-instruct', name: 'Llama'),
          const AIModel(id: 'mistralai/mistral-large', name: 'Mistral'),
          const AIModel(id: 'qwen/qwen-2.5-72b-instruct', name: 'Qwen'),
        ];
      case 'deepseek':
        return [
          const AIModel(id: 'deepseek-chat', name: 'DeepSeek Chat'),
          const AIModel(id: 'deepseek-reasoner', name: 'DeepSeek Reasoner', isPremium: true),
        ];
      case 'together':
        return [
          const AIModel(id: 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', name: 'Llama 3.1 70B'),
          const AIModel(id: 'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo', name: 'Llama 3.1 8B'),
          const AIModel(id: 'deepseek-ai/DeepSeek-V3', name: 'DeepSeek V3', isPremium: true),
        ];
      case 'mistral':
        return [
          const AIModel(id: 'mistral-large-latest', name: 'Mistral Large', isPremium: true),
          const AIModel(id: 'mistral-medium-latest', name: 'Mistral Medium'),
          const AIModel(id: 'mistral-small-latest', name: 'Mistral Small'),
          const AIModel(id: 'open-mixtral-8x22b', name: 'Mixtral 8x22B'),
        ];
      default:
        return [const AIModel(id: 'offline-ai', name: 'Offline AI')];
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiProviderOrchestratorProvider);
    final orchestrator = ref.read(aiProviderOrchestratorProvider.notifier);

    final isOfflineMode = config.aiMode == 'offline';

    final activeModelsList = _getModelsForProvider(config.aiProvider);
    final currentSelectedModel = config.selectedModels[config.aiProvider] ?? activeModelsList.first.id;

    // Check if currentSelectedModel exists in the active provider models list
    final bool modelExists = activeModelsList.any((m) => m.id == currentSelectedModel);
    final String selectedModelId = modelExists ? currentSelectedModel : activeModelsList.first.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI SETTINGS',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure Expenso\'s intelligence settings. All AI model API calls are made directly from your device using your keys. Personal data is never stored outside your local device.',
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Section 1: AI Mode
              _buildSectionTitle('AI MODE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      title: 'Offline AI',
                      subtitle: 'Local-only summary',
                      icon: Icons.wifi_off_rounded,
                      activeColor: Colors.tealAccent,
                      selected: isOfflineMode,
                      onTap: () async {
                        await orchestrator.setAiMode('offline');
                        await orchestrator.setAiProvider('offline');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeCard(
                      title: 'Online AI',
                      subtitle: 'Powered by Cloud LLMs',
                      icon: Icons.cloud_done_rounded,
                      activeColor: const Color(0xFF0066FF),
                      selected: !isOfflineMode,
                      onTap: () async {
                        await orchestrator.setAiMode('online');
                        if (config.aiProvider == 'offline') {
                          await orchestrator.setAiProvider('gemini');
                        }
                      },
                    ),
                  ),
                ],
              ),

              if (!isOfflineMode) ...[
                const SizedBox(height: 28),

                // Section 2: AI Provider
                _buildSectionTitle('ONLINE AI PROVIDER'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: config.aiProvider == 'offline' ? 'gemini' : config.aiProvider,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141926),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF)),
                      items: _providerDisplayNames.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          await orchestrator.setAiProvider(val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Model Selector
                _buildSectionTitle('MODEL'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedModelId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF141926),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF)),
                      items: activeModelsList.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Row(
                            children: [
                              Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              if (m.isPremium) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB5179E).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFB5179E).withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    'Premium',
                                    style: TextStyle(color: Color(0xFFFF007F), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          await orchestrator.setAiModel(config.aiProvider, val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Section 4: Settings Hub
                _buildSectionTitle('API MANAGEMENT'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.vpn_key_rounded, color: Colors.tealAccent),
                        title: const Text('API Keys Manager', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Add, edit, duplicate, and validate secret keys', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => context.push('/api-manager'),
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded, color: Colors.tealAccent),
                        title: const Text('How to get keys & FAQs', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Security answers and setup tutorials', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => context.push('/chat-help'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? activeColor.withOpacity(0.4) : Colors.white.withOpacity(0.05),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? activeColor : Colors.white60, size: 28),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
