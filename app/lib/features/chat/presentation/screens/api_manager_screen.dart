import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_models.dart';
import '../../../../core/services/ai_provider_orchestrator.dart';
import '../../../../shared/widgets/glass_card.dart';

class ApiManagerScreen extends ConsumerStatefulWidget {
  const ApiManagerScreen({super.key});

  @override
  ConsumerState<ApiManagerScreen> createState() => _ApiManagerScreenState();
}

class _ApiManagerScreenState extends ConsumerState<ApiManagerScreen> {
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

  final List<String> _providersList = [
    'gemini',
    'openai',
    'claude',
    'groq',
    'openrouter',
    'deepseek',
    'together',
    'mistral'
  ];

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

  void _showAddKeyDialog(String provider) {
    final nameController = TextEditingController(text: 'Key ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final keyController = TextEditingController();
    final models = _getModelsForProvider(provider);
    String selectedModel = models.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF162224),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add key for ${_providerDisplayNames[provider]}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    labelStyle: TextStyle(color: Colors.tealAccent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Secret Key',
                    labelStyle: TextStyle(color: Colors.tealAccent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  dropdownColor: const Color(0xFF162224),
                  decoration: const InputDecoration(
                    labelText: 'Selected Model',
                    labelStyle: TextStyle(color: Colors.tealAccent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: models
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedModel = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (keyController.text.trim().isEmpty) return;
                final newKey = SavedApiKey(
                  id: '${provider}-${DateTime.now().millisecondsSinceEpoch}',
                  provider: provider,
                  nickname: nameController.text,
                  key: keyController.text.trim(),
                  selectedModel: selectedModel,
                  createdAt: DateTime.now(),
                  validationStatus: 'not_tested',
                  latencyMs: 0,
                );
                await ref.read(aiProviderOrchestratorProvider.notifier).addSavedApiKey(newKey);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Key'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditKeyDialog(SavedApiKey savedKey) {
    final nameController = TextEditingController(text: savedKey.nickname);
    final models = _getModelsForProvider(savedKey.provider);
    String selectedModel = savedKey.selectedModel.isNotEmpty ? savedKey.selectedModel : models.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF162224),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Edit Key: ${savedKey.nickname}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    labelStyle: TextStyle(color: Colors.tealAccent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedModel,
                  dropdownColor: const Color(0xFF162224),
                  decoration: const InputDecoration(
                    labelText: 'Selected Model',
                    labelStyle: TextStyle(color: Colors.tealAccent),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: models
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.name, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedModel = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await ref.read(aiProviderOrchestratorProvider.notifier).editSavedApiKey(
                      savedKey.id,
                      nameController.text,
                      selectedModel,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportKeysDialog() {
    final exportJson = ref.read(aiProviderOrchestratorProvider.notifier).exportKeys();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162224),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Export Saved Keys', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy the JSON payload below to back up or migrate your configurations manually.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  exportJson,
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportJson));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Keys copied to clipboard.')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy JSON', style: TextStyle(color: Colors.tealAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showImportKeysDialog() {
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162224),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Import Keys', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste a valid JSON API keys payload below to import configurations.',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: importController,
              maxLines: 6,
              style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '[{"id": "...", "provider": "..."}]',
                hintStyle: TextStyle(color: Colors.white24),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await ref.read(aiProviderOrchestratorProvider.notifier).importKeys(importController.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Keys imported successfully.')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceAll('Exception:', ''))),
                );
              }
            },
            child: const Text('Import Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiProviderOrchestratorProvider);
    final orchestrator = ref.read(aiProviderOrchestratorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'API MANAGER',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined, color: Colors.tealAccent),
            tooltip: 'Import Keys',
            onPressed: _showImportKeysDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.tealAccent),
            tooltip: 'Export Keys',
            onPressed: _showExportKeysDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1D), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: _providersList.length,
          itemBuilder: (context, index) {
            final provider = _providersList[index];
            final keys = config.savedKeys.where((k) => k.provider == provider).toList();
            final activeKeyId = config.activeKeyIds[provider];

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _providerDisplayNames[provider]!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 20),
                        onPressed: () => _showAddKeyDialog(provider),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        tooltip: 'Add Key',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (keys.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.03)),
                      ),
                      child: Text(
                        'No keys configured. Tap + to add one.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    )
                  else
                    ...keys.map((k) {
                      final isActive = activeKeyId == k.id;
                      final stats = config.keyStats[k.id];
                      
                      Color statusColor;
                      String statusText;
                      switch (k.validationStatus) {
                        case 'valid':
                          statusColor = Colors.green;
                          statusText = 'Valid';
                          break;
                        case 'invalid':
                          statusColor = Colors.red;
                          statusText = 'Invalid';
                          break;
                        default:
                          statusColor = Colors.orange;
                          statusText = 'Not Tested';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          k.nickname,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.tealAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                                            ),
                                            child: const Text(
                                              'DEFAULT',
                                              style: TextStyle(color: Colors.tealAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                      if (k.validationStatus == 'valid' && k.latencyMs > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '${k.latencyMs} ms',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                      ]
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                k.key.length > 10 ? '${k.key.substring(0, 6)}...${k.key.substring(k.key.length - 4)}' : '••••••••',
                                style: const TextStyle(color: Colors.white30, fontSize: 12, fontFamily: 'monospace'),
                              ),
                              if (k.selectedModel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Model: ${k.selectedModel}',
                                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                                ),
                              ],
                              
                              if (stats != null && stats.requestsToday > 0) ...[
                                const Divider(color: Colors.white10, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Requests Today: ${stats.requestsToday}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    Text(
                                      'Avg Latency: ${stats.averageResponseSec.toStringAsFixed(2)}s',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    Text(
                                      'Est. Tokens: ${stats.estimatedTokens}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                              
                              const Divider(color: Colors.white10, height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.play_circle_outline, color: Colors.tealAccent, size: 18),
                                        onPressed: () => orchestrator.validateKey(k.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        tooltip: 'Validate Key',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                        onPressed: () => _showEditKeyDialog(k),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        tooltip: 'Edit Key',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.copy_all_outlined, color: Colors.white70, size: 18),
                                        onPressed: () => orchestrator.duplicateSavedApiKey(k.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        tooltip: 'Duplicate Key',
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        onPressed: () => orchestrator.deleteSavedApiKey(k.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        tooltip: 'Delete Key',
                                      ),
                                    ],
                                  ),
                                  if (!isActive)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.tealAccent.withOpacity(0.08),
                                        foregroundColor: Colors.tealAccent,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: Colors.tealAccent.withOpacity(0.3)),
                                        ),
                                      ),
                                      onPressed: () => orchestrator.setActiveKey(provider, k.id),
                                      child: const Text('Set Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
