import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../core/services/ai_provider_orchestrator.dart';
import '../widgets/rich_chat_widgets.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class ChatListItem {
  final String? dateHeader;
  final ChatHistoryItem? message;
  final bool isThinkingIndicator;

  ChatListItem({this.dateHeader, this.message, this.isThinkingIndicator = false});
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Attachment states
  File? _selectedFile;
  String? _selectedFileName;
  String? _selectedFileType; // 'image', 'pdf', 'csv', 'excel', 'statement'

  // UX & Scroll improvements
  final Set<String> _showSummaryMessageIds = {};
  final Map<String, String> _selectedAccountForMessage = {};
  bool _showJumpToLatest = false;
  bool _isAutoScrolling = false;

  // ChatGPT Scrolling & Streaming state variables
  String? _streamingMessageId;
  int _revealedLength = 0;
  Timer? _streamingTimer;
  bool _userHasScrolledManually = false;
  String? _lastProcessedMessageId;
  final GlobalKey _lastMessageKey = GlobalKey();

  // Suggestion chips list
  final List<String> _suggestedQueries = [
    'Where did I spend the most?',
    'Upcoming Bills',
    'Monthly Report',
    'Budget Analysis',
    'Income Trend',
    'Saving Tips',
    'Top Categories',
    'Spending Insights',
  ];

  static const List<List<String>> _suggestionSets = [
    [
      'Show my monthly summary',
      'Where did I spend the most?',
      'Upcoming bills',
      'Analyze my spending',
    ],
    [
      'How much did I save this month?',
      'What are my biggest expenses?',
      'Show my recent transactions',
      'Help me create a budget',
    ],
    [
      'What\'s affecting my net worth?',
      'Which category costs me the most?',
      'Do I have upcoming bills?',
      'Find unusual spending',
    ],
    [
      'Compare this month with last month',
      'Show my top spending categories',
      'How can I reduce my expenses?',
      'Show my financial health',
    ],
    [
      'What did I spend today?',
      'Where am I overspending?',
      'Show my income this month',
      'Give me a financial summary',
    ],
  ];

  late List<String> _currentWelcomeQueries;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_scrollListener);
    
    // Choose a random welcome queries set
    final random = math.Random();
    _currentWelcomeQueries = List.from(_suggestionSets[random.nextInt(_suggestionSets.length)]);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // Detect manual scrolling during active generation
    if (position.userScrollDirection != ScrollDirection.idle) {
      if (!_userHasScrolledManually && _streamingMessageId != null) {
        setState(() {
          _userHasScrolledManually = true;
        });
      }
    }

    final isNearBottom = position.maxScrollExtent - position.pixels < 80;
    if (!isNearBottom) {
      if (!_showJumpToLatest && !_isAutoScrolling) {
        setState(() {
          _showJumpToLatest = true;
        });
      }
    } else {
      if (_showJumpToLatest) {
        setState(() {
          _showJumpToLatest = false;
        });
      }
      // If manual override was active and user scrolled back to bottom, resume auto scroll follow
      if (_userHasScrolledManually && _streamingMessageId != null) {
        setState(() {
          _userHasScrolledManually = false;
        });
      }
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _scrollController.removeListener(_scrollListener);
    _streamingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool smooth = true}) {
    if (!_scrollController.hasClients) return;
    
    setState(() {
      _isAutoScrolling = true;
      _showJumpToLatest = false;
    });

    final target = _scrollController.position.maxScrollExtent;
    if (smooth) {
      // Use short durations and easeOut for smooth, zero-flicker scrolls
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      ).then((_) {
        _isAutoScrolling = false;
      });
    } else {
      _scrollController.jumpTo(target);
      _isAutoScrolling = false;
    }
  }

  void _startStreamingMessage(ChatHistoryItem message) {
    _streamingTimer?.cancel();
    setState(() {
      _streamingMessageId = message.id;
      _revealedLength = 0;
      _userHasScrolledManually = false;
      _showJumpToLatest = false;
    });

    final text = message.message;
    // Typing effect: reveal 4 characters every 20ms
    const int charsPerTick = 4;
    _streamingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_revealedLength + charsPerTick >= text.length) {
          _revealedLength = text.length;
          _streamingMessageId = null;
          timer.cancel();
          _scrollAfterStreamingComplete();
        } else {
          _revealedLength += charsPerTick;
          if (!_userHasScrolledManually) {
            // Smoothly push scroll viewport to follow streaming text changes
            _scrollToBottom(smooth: true);
          }
        }
      });
    });
  }

  void _scrollAfterStreamingComplete() {
    if (!_scrollController.hasClients) return;

    // Use a post frame callback to wait until layout is fully computed after final text is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final currentContext = _lastMessageKey.currentContext;
      if (currentContext == null) return;

      final RenderBox? renderBox = currentContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = _scrollController.position;
      final messageHeight = renderBox.size.height;
      final viewportHeight = position.viewportDimension;

      // If message is short enough to fit fully on screen, keep it visible without scrolling past
      if (messageHeight < viewportHeight) {
        _scrollToBottom(smooth: true);
      } else {
        // Position viewport exactly at the beginning (top) of the latest message
        Scrollable.ensureVisible(
          currentContext,
          alignment: 0.0, // align top of widget with top of viewport
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showMessageActionsBottomSheet(BuildContext context, ChatHistoryItem message, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0F1D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Message Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Color(0xFF00E5FF)),
              title: const Text('Copy Text', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: message.message));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied to clipboard.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Share Message', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing message...')));
              },
            ),
            if (message.role != 'user')
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Color(0xFF00E5FF)),
                title: const Text('Regenerate Response', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _sendMessage(userId, message.message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.volume_up_rounded, color: Color(0xFF00E5FF)),
              title: const Text('Read Aloud', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading message aloud...')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF00E5FF)),
              title: const Text('Save Note', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message saved to notes.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30)),
              title: const Text('Delete Message', style: TextStyle(color: Color(0xFFFF3B30))),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message deleted.')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPlusActionMenu(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0F1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xFF0066FF), width: 1),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'AI Input Actions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Voice Assistant & Transcription', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startVoiceEntry(userId);
              },
            ),
            const Divider(color: Colors.white10, height: 1),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Scan Receipt Photo (Camera)', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final ocrService = ref.read(ocrServiceProvider);
                final pickedFile = await ocrService.pickImage(ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _selectedFile = File(pickedFile.path);
                    _selectedFileName = pickedFile.name;
                    _selectedFileType = 'image';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Choose Receipt from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final ocrService = ref.read(ocrServiceProvider);
                final pickedFile = await ocrService.pickImage(ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _selectedFile = File(pickedFile.path);
                    _selectedFileName = pickedFile.name;
                    _selectedFileType = 'image';
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String userId, String text) async {
    if (text.trim().isEmpty && _selectedFile == null) return;

    _focusNode.unfocus();
    FocusScope.of(context).unfocus();

    String finalMessage = text;

    // Handle attachment inclusion
    if (_selectedFile != null) {
      final prefix = '[Attachment: $_selectedFileName] ';
      finalMessage = '$prefix$text'.trim();
      
      // If it's a receipt image, we can simulate scanning it locally
      if (_selectedFileType == 'image') {
        final ocrService = ref.read(ocrServiceProvider);
        try {
          final ocrResult = await ocrService.scanReceipt(_selectedFile!);
          if (ocrResult != null) {
            finalMessage = 'Scanned Receipt: Spent ₹${ocrResult.amount.toStringAsFixed(0)} at ${ocrResult.merchant} for ${ocrResult.category}. $text'.trim();
          }
        } catch (_) {}
      }
      
      // Reset attachment state
      setState(() {
        _selectedFile = null;
        _selectedFileName = null;
        _selectedFileType = null;
      });
    }

    _messageController.clear();
    final notifier = ref.read(chatNotifierProvider.notifier);

    setState(() {
      _showJumpToLatest = false;
    });

    _scrollToBottom(smooth: true);
    await notifier.sendMessage(userId, finalMessage);
    _scrollToBottom(smooth: true);
  }

  Future<void> _startVoiceEntry(String userId) async {
    final voiceNotifier = ref.read(voiceServiceProvider.notifier);
    String selectedLocale = 'en_US';
    final Map<String, String> languages = {
      '🇺🇸 English': 'en_US',
      '🇮🇳 Hindi': 'hi_IN',
      '🇪🇸 Spanish': 'es_ES',
      '🇫🇷 French': 'fr_FR',
      '🇩🇪 German': 'de_DE',
    };

    voiceNotifier.startListening(
      localeId: selectedLocale,
      onResult: (text) {
        if (text.isNotEmpty) {
          setState(() {
            _messageController.text = text;
          });
        }
      },
    );

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF0A0F1D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Consumer(
              builder: (context, ref, child) {
                final voiceState = ref.watch(voiceServiceProvider);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Voice Assistant',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedLocale,
                                dropdownColor: const Color(0xFF0A0F1D),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                onChanged: (newLocale) {
                                  if (newLocale != null) {
                                    setStateSheet(() {
                                      selectedLocale = newLocale;
                                    });
                                    voiceNotifier.stopListening().then((_) {
                                      voiceNotifier.startListening(
                                        localeId: selectedLocale,
                                        onResult: (text) {
                                          if (text.isNotEmpty) {
                                            setState(() {
                                              _messageController.text = text;
                                            });
                                          }
                                        },
                                      );
                                    });
                                  }
                                },
                                items: languages.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.value,
                                    child: Text(entry.key),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withOpacity(0.06),
                          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.12)),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E5FF).withOpacity(0.15),
                            ),
                            child: const Icon(Icons.mic, color: Color(0xFF00E5FF), size: 30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        voiceState.isListening ? 'Listening...' : 'Stopped',
                        style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            voiceState.text.isEmpty
                                ? 'Start speaking to transcribe your finances...'
                                : voiceState.text,
                            style: TextStyle(
                              color: voiceState.text.isEmpty ? Colors.white24 : Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                voiceNotifier.stopListening();
                                Navigator.pop(context);
                              },
                              child: const Text('Stop & Edit', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0066FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                final textToSend = voiceState.text;
                                voiceNotifier.stopListening();
                                Navigator.pop(context);
                                if (textToSend.isNotEmpty) {
                                  _sendMessage(userId, textToSend);
                                }
                              },
                              child: const Text('Send Immediately', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickAttachment(String userId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0F1D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Select Attachment Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Take Receipt Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final ocrService = ref.read(ocrServiceProvider);
                final pickedFile = await ocrService.pickImage(ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _selectedFile = File(pickedFile.path);
                    _selectedFileName = pickedFile.name;
                    _selectedFileType = 'image';
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFF00E5FF)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final ocrService = ref.read(ocrServiceProvider);
                final pickedFile = await ocrService.pickImage(ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _selectedFile = File(pickedFile.path);
                    _selectedFileName = pickedFile.name;
                    _selectedFileType = 'image';
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF0066FF), width: 1.2)),
        title: const Text('Clear conversation?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove the current chat from your conversation history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF0066FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatNotifierProvider.notifier).clearChat(userId);
              setState(() {
                final random = math.Random();
                _currentWelcomeQueries = List.from(_suggestionSets[random.nextInt(_suggestionSets.length)]);
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAiChatMenuBottomSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0F1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF0066FF), width: 1.5)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('AI Chat Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                                  _buildMenuSection('AI', [
                    _buildMenuItem(context, Icons.settings_outlined, 'AI Settings', () {
                      Navigator.pop(context);
                      context.push('/ai-settings');
                    }),
                    _buildMenuItem(context, Icons.vpn_key_outlined, 'API Keys Manager', () {
                      Navigator.pop(context);
                      context.push('/api-manager');
                    }),
                    _buildMenuItem(context, Icons.wifi_off_outlined, 'Offline AI', () async {
                      Navigator.pop(context);
                      final orchestrator = ref.read(aiProviderOrchestratorProvider.notifier);
                      await orchestrator.setAiMode('offline');
                      await orchestrator.setAiProvider('offline');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Offline AI mode.')));
                    }),
                    _buildMenuItem(context, Icons.wifi_outlined, 'Online AI', () async {
                      Navigator.pop(context);
                      final orchestrator = ref.read(aiProviderOrchestratorProvider.notifier);
                      await orchestrator.setAiMode('online');
                      await orchestrator.setAiProvider('gemini');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Online AI (Google Gemini).')));
                    }),
                    _buildMenuItem(context, Icons.psychology_outlined, 'AI Memory', () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF0A0F1D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('AI Memory Status', style: TextStyle(color: Colors.white)),
                          content: const Text('AI Memory is active. Relevant facts from your financial requests are remembered locally on-device to personalize financial summaries.', style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                          ],
                        ),
                      );
                    }),
                    _buildMenuItem(context, Icons.article_outlined, 'Prompt Templates', () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                          backgroundColor: const Color(0xFF0A0F1D),
                          title: const Text('Prompt Templates', style: TextStyle(color: Colors.white)),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                _messageController.text = 'Analyze my spending behavior this week.';
                                Navigator.pop(context);
                              },
                              child: const Text('Weekly Analysis', style: TextStyle(color: Colors.white70)),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                _messageController.text = 'Create a savings plan targeting 20% of monthly income.';
                                Navigator.pop(context);
                              },
                              child: const Text('Savings Target 20%', style: TextStyle(color: Colors.white70)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ]),

                  _buildMenuSection('Conversation', [
                    _buildMenuItem(context, Icons.search_rounded, 'Search Chat', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat search interface active.')));
                    }),
                    _buildMenuItem(context, Icons.share_outlined, 'Export Chat', () {
                      Navigator.pop(context);
                      final aiConfig = ref.read(aiProviderOrchestratorProvider);
                      final isOffline = aiConfig.aiMode == 'offline' || aiConfig.aiProvider == 'offline';
                      final Map<String, String> localProviderDisplayNames = {
                        'offline': 'Offline AI',
                        'gemini': 'Google Gemini',
                        'openai': 'OpenAI',
                        'claude': 'Claude',
                        'groq': 'Groq',
                        'openrouter': 'OpenRouter',
                        'deepseek': 'DeepSeek',
                        'together': 'Together AI',
                        'mistral': 'Mistral',
                      };
                      final Map<String, String> localModelMap = {
                        'offline-ai': 'Offline AI',
                        'gemini-2.5-flash': 'Gemini 2.5 Flash',
                        'gemini-2.5-pro': 'Gemini 2.5 Pro',
                        'gemini-2.0-flash': 'Gemini 2.0 Flash',
                        'gemini-2.0-flash-lite': 'Gemini 2.0 Flash Lite',
                        'gpt-5': 'GPT-5',
                        'gpt-5-mini': 'GPT-5 Mini',
                        'gpt-5-nano': 'GPT-5 Nano',
                        'gpt-4.1': 'GPT-4.1',
                        'gpt-4.1-mini': 'GPT-4.1 Mini',
                        'claude-4-sonnet': 'Claude Sonnet 4',
                        'claude-4-opus': 'Claude Opus 4',
                        'llama-4': 'Llama 4',
                        'llama-3.3-70b-specdec': 'Llama 3.3 70B',
                        'deepseek-r1-distill-llama-70b': 'DeepSeek R1',
                        'qwen-2.5-coder-32b': 'Qwen',
                        'google/gemini-2.5-pro': 'Gemini 2.5 Pro',
                        'openai/gpt-4o': 'GPT',
                        'anthropic/claude-3-5-sonnet': 'Claude',
                        'deepseek/deepseek-chat': 'DeepSeek',
                        'meta-llama/llama-3.1-70b-instruct': 'Llama',
                        'mistralai/mistral-large': 'Mistral',
                        'qwen/qwen-2.5-72b-instruct': 'Qwen',
                        'deepseek-chat': 'DeepSeek Chat',
                        'deepseek-reasoner': 'DeepSeek Reasoner',
                        'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo': 'Llama 3.1 70B',
                        'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo': 'Llama 3.1 8B',
                        'deepseek-ai/DeepSeek-V3': 'DeepSeek V3',
                        'mistral-large-latest': 'Mistral Large',
                        'mistral-medium-latest': 'Mistral Medium',
                        'mistral-small-latest': 'Mistral Small',
                        'open-mixtral-8x22b': 'Mixtral 8x22B',
                      };
                      final pName = isOffline ? 'Offline AI' : (localProviderDisplayNames[aiConfig.aiProvider] ?? aiConfig.aiProvider.toUpperCase());
                      final mId = isOffline ? 'offline' : (aiConfig.selectedModels[aiConfig.aiProvider] ?? 'gemini-2.5-flash');
                      final mDisplayName = localModelMap[mId] ?? mId;
                      final messages = ref.read(chatHistoryProvider(userId)).value ?? [];
                      _exportChatAsPdf(messages, pName, mDisplayName);
                    }),
                    _buildMenuItem(context, Icons.delete_sweep_outlined, 'Clear Conversation', () {
                      Navigator.pop(context);
                      _confirmClearHistory(userId);
                    }),
                    _buildMenuItem(context, Icons.pin_drop_outlined, 'Pin Conversation', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation pinned.')));
                    }),
                    _buildMenuItem(context, Icons.copy_all_outlined, 'Copy Entire Chat', () {
                      Navigator.pop(context);
                      final messages = ref.read(chatHistoryProvider(userId)).value ?? [];
                      _copyConversation(messages);
                    }),
                  ]),

                  _buildMenuSection('Financial Tools', [
                    _buildMenuItem(context, Icons.bar_chart_rounded, 'View Analytics', () {
                      Navigator.pop(context);
                      context.push('/analytics');
                    }),
                    _buildMenuItem(context, Icons.wallet_rounded, 'Budget Planner', () {
                      Navigator.pop(context);
                      context.push('/budgets');
                    }),
                    _buildMenuItem(context, Icons.summarize_rounded, 'Monthly Report', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Monthly Report...')));
                    }),
                    _buildMenuItem(context, Icons.swap_horizontal_circle_outlined, 'Cash Flow', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Displaying Cash Flow charts...')));
                    }),
                    _buildMenuItem(context, Icons.savings_outlined, 'Savings Analysis', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Displaying Savings analysis...')));
                    }),
                    _buildMenuItem(context, Icons.lightbulb_outline_rounded, 'Budget Insights', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Budget Insights...')));
                    }),
                    _buildMenuItem(context, Icons.trending_up_rounded, 'Spending Trends', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Spending Trends...')));
                    }),
                  ]),

                  _buildMenuSection('Support', [
                    _buildMenuItem(context, Icons.help_outline_rounded, 'Help Center', () {
                      Navigator.pop(context);
                      context.push('/chat-help');
                    }),
                    _buildMenuItem(context, Icons.school_outlined, 'API Tutorials', () {
                      Navigator.pop(context);
                      context.push('/chat-help');
                    }),
                    _buildMenuItem(context, Icons.quiz_outlined, 'FAQ', () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF0A0F1D),
                          title: const Text('FAQ', style: TextStyle(color: Colors.white)),
                          content: const Text('Q: Is my API key secure?\nA: Yes, all keys are saved in encrypted local Android SharedPreferences.', style: TextStyle(color: Colors.white70)),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }),
                    _buildMenuItem(context, Icons.mail_outline_rounded, 'Contact Support', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email support: support@expenso.ai')));
                    }),
                    _buildMenuItem(context, Icons.security_outlined, 'Privacy', () {
                      Navigator.pop(context);
                      context.push('/privacy');
                    }),
                    _buildMenuItem(context, Icons.info_outline_rounded, 'About Expenso AI', () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF0A0F1D),
                          title: const Text('About Expenso AI', style: TextStyle(color: Colors.white)),
                          content: const Text('Expenso AI Copilot v3.0\nSecure locally managed financial advisor.', style: TextStyle(color: Colors.white70)),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10, height: 24),
        Text(title.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: items,
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd MMMM yyyy').format(date);
    }
  }

  List<ChatListItem> _buildChatListItems(List<ChatHistoryItem> messages, bool isProcessing) {
    final List<ChatListItem> items = [];
    String? lastHeader;

    for (var msg in messages) {
      final header = _getDateHeader(msg.createdAt);
      if (header != lastHeader) {
        items.add(ChatListItem(dateHeader: header));
        lastHeader = header;
      }
      items.add(ChatListItem(message: msg));
    }

    if (isProcessing) {
      items.add(ChatListItem(isThinkingIndicator: true));
    }

    return items;
  }

  String _cleanMessageText(String messageText) {
    // Strip raw data status bullet lines so we do not show duplicate text alongside the FinancialStatusCard
    final lines = messageText.split('\n');
    final cleanLines = lines.where((line) {
      final l = line.toLowerCase();
      if (l.contains('current balance') ||
          l.contains('monthly income') ||
          l.contains('monthly expenses') ||
          l.contains('financial health score') ||
          (l.contains('savings') && !l.contains('saving tips') && !l.contains('savings rates'))) {
        return false;
      }
      return true;
    }).toList();
    return cleanLines.join('\n').trim();
  }

  Future<void> _exportChatAsPdf(List<ChatHistoryItem> messages, String activeProvider, String modelDisplayName) async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No conversation to export.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      final pdfDoc = pw.Document();
      
      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Expenso AI Chat History',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              
              // Metadata
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Provider: $activeProvider', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                    pw.SizedBox(height: 2),
                    pw.Text('Model: $modelDisplayName', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Messages
              ...messages.map((msg) {
                final isMe = msg.role == 'user';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: isMe ? PdfColors.blue50 : PdfColors.white,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            isMe ? 'User' : 'Expenso AI',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: isMe ? PdfColors.blue800 : PdfColors.teal800,
                            ),
                          ),
                          pw.Text(
                            DateFormat('HH:mm').format(msg.createdAt),
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _cleanMessageText(msg.message).replaceAll('₹', 'INR '),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          lineSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ];
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/expenso_chat_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdfDoc.save());

      // Share PDF through Share Sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Expenso AI Chat History Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _copyConversation(List<ChatHistoryItem> messages) async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation to copy.')),
      );
      return;
    }

    final buffer = StringBuffer();
    for (var msg in messages) {
      final role = msg.role == 'user' ? 'User' : 'Expenso AI';
      final text = _cleanMessageText(msg.message);
      buffer.writeln('$role:\n$text\n');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation copied to clipboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(child: Text('Please log in first.', style: TextStyle(color: Colors.white))),
      );
    }

    final aiConfig = ref.watch(aiProviderOrchestratorProvider);
    final String activeProvider = aiConfig.aiProvider;
    final bool isOffline = aiConfig.aiMode == 'offline' || activeProvider == 'offline';

    final Map<String, String> providerDisplayNames = {
      'offline': 'Offline AI',
      'gemini': 'Google Gemini',
      'openai': 'OpenAI',
      'claude': 'Claude',
      'groq': 'Groq',
      'openrouter': 'OpenRouter',
      'deepseek': 'DeepSeek',
      'together': 'Together AI',
      'mistral': 'Mistral',
    };

    final Map<String, String> modelMap = {
      'offline-ai': 'Offline AI',
      'gemini-2.5-flash': 'Gemini 2.5 Flash',
      'gemini-2.5-pro': 'Gemini 2.5 Pro',
      'gemini-2.0-flash': 'Gemini 2.0 Flash',
      'gemini-2.0-flash-lite': 'Gemini 2.0 Flash Lite',
      'gpt-5': 'GPT-5',
      'gpt-5-mini': 'GPT-5 Mini',
      'gpt-5-nano': 'GPT-5 Nano',
      'gpt-4.1': 'GPT-4.1',
      'gpt-4.1-mini': 'GPT-4.1 Mini',
      'claude-4-sonnet': 'Claude Sonnet 4',
      'claude-4-opus': 'Claude Opus 4',
      'llama-4': 'Llama 4',
      'llama-3.3-70b-specdec': 'Llama 3.3 70B',
      'deepseek-r1-distill-llama-70b': 'DeepSeek R1',
      'qwen-2.5-coder-32b': 'Qwen',
      'google/gemini-2.5-pro': 'Gemini 2.5 Pro',
      'openai/gpt-4o': 'GPT',
      'anthropic/claude-3-5-sonnet': 'Claude',
      'deepseek/deepseek-chat': 'DeepSeek',
      'meta-llama/llama-3.1-70b-instruct': 'Llama',
      'mistralai/mistral-large': 'Mistral',
      'qwen/qwen-2.5-72b-instruct': 'Qwen',
      'deepseek-chat': 'DeepSeek Chat',
      'deepseek-reasoner': 'DeepSeek Reasoner',
      'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo': 'Llama 3.1 70B',
      'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo': 'Llama 3.1 8B',
      'deepseek-ai/DeepSeek-V3': 'DeepSeek V3',
      'mistral-large-latest': 'Mistral Large',
      'mistral-medium-latest': 'Mistral Medium',
      'mistral-small-latest': 'Mistral Small',
      'open-mixtral-8x22b': 'Mixtral 8x22B',
    };

    String providerName = 'Offline AI';
    String modelDisplayName = 'Offline AI';
    String badgeText = 'Offline';
    Color dotColor = Colors.tealAccent;

    if (!isOffline) {
      switch (activeProvider) {
        case 'gemini':
          providerName = 'Google Gemini';
          dotColor = Colors.purpleAccent;
          break;
        case 'openai':
          providerName = 'OpenAI';
          dotColor = Colors.greenAccent;
          break;
        case 'claude':
          providerName = 'Claude';
          dotColor = Colors.orangeAccent;
          break;
        case 'groq':
          providerName = 'Groq';
          dotColor = const Color(0xFF0066FF);
          break;
        case 'openrouter':
          providerName = 'OpenRouter';
          dotColor = const Color(0xFFB5179E);
          break;
        case 'deepseek':
          providerName = 'DeepSeek';
          dotColor = Colors.deepPurpleAccent;
          break;
        case 'together':
          providerName = 'Together AI';
          dotColor = Colors.cyanAccent;
          break;
        case 'mistral':
          providerName = 'Mistral';
          dotColor = Colors.redAccent;
          break;
      }

      final selectedModelId = aiConfig.selectedModels[activeProvider] ?? '';
      modelDisplayName = modelMap[selectedModelId] ?? selectedModelId;

      final premiumModels = [
        'gemini-2.5-pro',
        'gpt-5',
        'gpt-4.1',
        'claude-4-opus',
        'llama-4',
        'google/gemini-2.5-pro',
        'deepseek-reasoner',
        'deepseek-ai/DeepSeek-V3',
        'mistral-large-latest',
      ];
      final isPremium = premiumModels.contains(selectedModelId);
      final bool isValid = aiConfig.apiValid[activeProvider] ?? false;

      if (isPremium) {
        badgeText = 'Premium Model';
      } else if (isValid) {
        badgeText = 'API Valid';
      } else {
        badgeText = 'Connected';
      }
    }

    final activeKey = ref.read(aiProviderOrchestratorProvider.notifier).getActiveKeyForProvider(activeProvider);
    final latency = activeKey?.latencyMs ?? 0;
    
    String connectionInfoText = '⚪ Offline AI • Running Locally • No Internet Required';
    if (!isOffline) {
      final latencyText = latency > 0 ? ' • $latency ms' : '';
      connectionInfoText = '🟢 Online • API Connected$latencyText • Local Financial Summary';
    }

    final chatState = ref.watch(chatNotifierProvider);
    final chatHistoryAsync = ref.watch(chatHistoryProvider(userId));
    final isProcessing = chatState.isLoading;

    ref.listen<AsyncValue<List<ChatHistoryItem>>>(chatHistoryProvider(userId), (prev, next) {
      next.whenData((messages) {
        if (messages.isEmpty) {
          _lastProcessedMessageId = null;
          return;
        }
        final lastMsg = messages.last;

        // Initialize lastProcessedMessageId on first load
        if (_lastProcessedMessageId == null) {
          _lastProcessedMessageId = lastMsg.id;
          return;
        }

        // Trigger simulated streaming only for new incoming model messages
        if (lastMsg.role == 'model' && lastMsg.id != _lastProcessedMessageId) {
          _lastProcessedMessageId = lastMsg.id;
          _startStreamingMessage(lastMsg);
        } else {
          // For other updates, scroll to bottom unless user scrolled away
          _lastProcessedMessageId = lastMsg.id;
          if (!_showJumpToLatest && _streamingMessageId == null) {
            _scrollToBottom(smooth: true);
          }
        }
      });
    });

    ref.listen<AsyncValue<void>>(chatNotifierProvider, (prev, next) {
      if (next.isLoading) {
        _scrollToBottom(smooth: true);
      }
    });

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF030A16), Color(0xFF050505)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // COMPACT HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Arrow to Dashboard
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                      ),
                      const SizedBox(width: 10),
                      // AI Avatar (Provider Logo)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: dotColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 1.2),
                        ),
                        child: Icon(Icons.auto_awesome, color: dotColor, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<MapEntry<String, String>>(
                              tooltip: 'Quick switch model',
                              offset: const Offset(0, 24),
                              onSelected: (entry) async {
                                final provider = entry.key;
                                final model = entry.value;
                                final orchestrator = ref.read(aiProviderOrchestratorProvider.notifier);
                                if (provider == 'offline') {
                                  await orchestrator.setAiMode('offline');
                                  await orchestrator.setAiProvider('offline');
                                } else {
                                  await orchestrator.setAiMode('online');
                                  await orchestrator.setAiProvider(provider);
                                  await orchestrator.setAiModel(provider, model);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Switched to ${modelMap[model] ?? model}'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) {
                                final List<PopupMenuEntry<MapEntry<String, String>>> items = [];
                                
                                // 1. Dynamic Saved/Configured Providers Section
                                final savedProviders = aiConfig.savedKeys
                                    .map((k) => k.provider)
                                    .toSet()
                                    .toList();
                                    
                                if (savedProviders.isNotEmpty) {
                                  items.add(const PopupMenuItem(
                                    enabled: false,
                                    child: Text(
                                      'AI PROVIDERS',
                                      style: TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ));
                                  
                                  for (var provider in savedProviders) {
                                    final modelId = aiConfig.selectedModels[provider] ?? 'gemini-2.5-flash';
                                    final modelName = modelMap[modelId] ?? modelId;
                                    final providerDisplayName = providerDisplayNames[provider] ?? provider.toUpperCase();
                                    
                                    items.add(PopupMenuItem(
                                      value: MapEntry(provider, modelId),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              modelName,
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Powered by $providerDisplayName',
                                              style: const TextStyle(color: Colors.white30, fontSize: 9),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ));
                                  }
                                  items.add(const PopupMenuDivider());
                                }
                                
                                // 2. Offline AI Section
                                items.add(const PopupMenuItem(
                                  enabled: false,
                                  child: Text(
                                    'OFFLINE AI',
                                    style: TextStyle(
                                      color: Colors.tealAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ));
                                items.add(const PopupMenuItem(
                                  value: MapEntry('offline', 'offline-ai'),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Offline AI',
                                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Powered by Local AI',
                                          style: TextStyle(color: Colors.white30, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                ));
                                
                                return items;
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      modelDisplayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Powered by $providerName',
                              style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right Side Column: Badge on top, Settings Icon on bottom
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: dotColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: dotColor.withOpacity(0.3), width: 0.8),
                            ),
                            child: Text(
                              badgeText.toUpperCase(),
                              style: TextStyle(color: dotColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                            color: const Color(0xFF0A0F1D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            onSelected: (value) async {
                              final chatHistoryAsync = ref.read(chatHistoryProvider(userId));
                              final messages = chatHistoryAsync.value ?? [];
                              switch (value) {
                                case 'settings':
                                  context.push('/ai-settings');
                                  break;
                                case 'api_manager':
                                  context.push('/api-manager');
                                  break;
                                case 'help':
                                  context.push('/chat-help');
                                  break;
                                case 'export':
                                  _exportChatAsPdf(messages, providerName, modelDisplayName);
                                  break;
                                case 'copy':
                                  _copyConversation(messages);
                                  break;
                                case 'clear':
                                  _confirmClearHistory(userId);
                                  break;
                                case 'privacy':
                                  context.push('/privacy');
                                  break;
                                case 'about':
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF0A0F1D),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('About Expenso AI', style: TextStyle(color: Colors.white)),
                                      content: const Text('Expenso AI Copilot v3.0\nSecure locally managed financial advisor.', style: TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                                      ],
                                    ),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOffline ? 'OFFLINE AI' : 'ONLINE AI',
                                      style: TextStyle(color: dotColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      connectionInfoText,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(Icons.settings_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('AI Settings', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'api_manager',
                                child: Row(
                                  children: [
                                    Icon(Icons.vpn_key_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('API Manager', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'help',
                                child: Row(
                                  children: [
                                    Icon(Icons.help_outline_rounded, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('Help & Tutorials', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(Icons.share_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('Export Chat', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_all_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('Copy Conversation', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'clear',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_sweep_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('Clear Conversation', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'privacy',
                                child: Row(
                                  children: [
                                    Icon(Icons.security_outlined, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('Privacy', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'about',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
                                    SizedBox(width: 10),
                                    Text('About Expenso AI', style: TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),

              if (aiConfig.fallbackMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    border: const Border(bottom: BorderSide(color: Colors.orangeAccent, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(aiConfig.fallbackMessage!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white30, size: 14),
                        onPressed: () => ref.read(aiProviderOrchestratorProvider.notifier).clearFallbackMessage(),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

              // Chat History Area
              Expanded(
                child: Stack(
                  children: [
                    chatHistoryAsync.when(
                      data: (messages) {
                        if (messages.isEmpty) {
                          return _buildWelcomeState(userId);
                        }

                        final listItems = _buildChatListItems(messages, isProcessing);

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];

                            if (item.isThinkingIndicator) {
                              return _buildThinkingIndicator();
                            }

                            if (item.dateHeader != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    item.dateHeader!,
                                    style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                  ),
                                ),
                              );
                            }

                            final message = item.message!;
                            final isMe = message.role == 'user';
                            final isLatestMessage = index == listItems.length - 1;

                            return AnimatedBubble(
                              key: isLatestMessage ? _lastMessageKey : null,
                              isMe: isMe,
                              child: _buildMessageBubble(message, isMe, userId, messages),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    ),
                    if (_showJumpToLatest)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 200),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: FloatingActionButton.small(
                            onPressed: () => _scrollToBottom(smooth: true),
                            backgroundColor: const Color(0xFF0D1527).withOpacity(0.9),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1.2),
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF00E5FF), size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Composer Container (Goal 6, 7 & 8)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF050505),
                  border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAttachmentPreview(),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(minHeight: 48, maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // "+" Action Menu Button
                            IconButton(
                              icon: const Icon(Icons.add_rounded, color: Color(0xFF00E5FF), size: 22),
                              onPressed: () => _showPlusActionMenu(context, userId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _focusNode,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Ask anything about your finances...',
                                  hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _messageController,
                              builder: (context, child) {
                                final hasText = _messageController.text.trim().isNotEmpty;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isProcessing 
                                        ? Colors.grey.shade900 
                                        : (hasText ? const Color(0xFF0066FF) : Colors.white10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                                    onPressed: (isProcessing || (!hasText && _selectedFile == null))
                                        ? null
                                        : () => _sendMessage(userId, _messageController.text),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildAttachmentPreview() {
    if (_selectedFile == null) return const SizedBox.shrink();
    
    IconData fileIcon = Icons.insert_drive_file_outlined;
    Color accentColor = const Color(0xFF00E5FF);
    
    switch (_selectedFileType) {
      case 'image':
        fileIcon = Icons.image_outlined;
        accentColor = const Color(0xFF00E676);
        break;
      case 'pdf':
        fileIcon = Icons.picture_as_pdf_outlined;
        accentColor = const Color(0xFFFF3B30);
        break;
      case 'csv':
      case 'excel':
        fileIcon = Icons.table_chart_outlined;
        accentColor = const Color(0xFFFF9500);
        break;
      default:
        fileIcon = Icons.article_outlined;
        accentColor = const Color(0xFF0066FF);
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(fileIcon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFileName ?? 'Selected File',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedFileType?.toUpperCase() ?? 'DOCUMENT',
                    style: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Colors.white30, size: 20),
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                  _selectedFileName = null;
                  _selectedFileType = null;
                });
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              splashRadius: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello 👋',
            style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "I'm Expenso AI.",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'I can help you understand your finances. Try asking:',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          ..._currentWelcomeQueries.map((query) {
            IconData itemIcon = Icons.help_outline_rounded;
            if (query.contains('summary') || query.contains('Report')) {
              itemIcon = Icons.summarize_outlined;
            } else if (query.contains('spend') || query.contains('most')) {
              itemIcon = Icons.pie_chart_outline_rounded;
            } else if (query.contains('bills') || query.contains('Bills')) {
              itemIcon = Icons.calendar_today_outlined;
            } else if (query.contains('budget')) {
              itemIcon = Icons.wallet_outlined;
            } else if (query.contains('spending')) {
              itemIcon = Icons.analytics_outlined;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _sendMessage(userId, query),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Row(
                    children: [
                      Icon(itemIcon, color: const Color(0xFF00E5FF), size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          query,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 14),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showMoreDetailsBottomSheet(BuildContext context, ParsedFinancialReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0A0F1D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFF0066FF), width: 1.5)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2.5)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text('Financial Insights & Tools', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                    if (report.healthScore != null) ...[
                      CircularHealthIndicator(score: report.healthScore!),
                      const SizedBox(height: 16),
                    ],
                    if (report.income != null || report.expenses != null || report.balance != null) ...[
                      FinancialMetricsGrid(report: report),
                      const SizedBox(height: 16),
                    ],
                    if (report.recommendations.isNotEmpty) ...[
                      RecommendationsChecklist(items: report.recommendations),
                      const SizedBox(height: 16),
                    ],
                    const Divider(color: Colors.white10, height: 24),
                    const Text(
                      'AI ASSISTANT TOOLS',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9,
                      children: [
                        _buildSheetToolButton(
                          context,
                          icon: Icons.bar_chart_rounded,
                          label: 'View Analytics',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/analytics');
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'Export PDF',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting report as PDF...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: 'Budget Planner',
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/budgets');
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.lightbulb_rounded,
                          label: 'Savings Tips',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Savings Tip: Automating 20% of your deposits helps keep budget targets healthy.'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.trending_up_rounded,
                          label: 'Spending Trends',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analyzing your spending velocity and trends...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.swap_horiz_rounded,
                          label: 'Cash Flow',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Cash Flow details...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.psychology_rounded,
                          label: 'Budget Insights',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Displaying Budget Insights...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.summarize_rounded,
                          label: 'Monthly Report',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Monthly Report...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                        _buildSheetToolButton(
                          context,
                          icon: Icons.account_balance_rounded,
                          label: 'Income Analysis',
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calculating your monthly income distribution...'), backgroundColor: Color(0xFF0066FF)));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetToolButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF0066FF).withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  bool _isFinancialSummaryExplicitlyRequested(List<ChatHistoryItem> messages, ChatHistoryItem modelMessage) {
    final idx = messages.indexOf(modelMessage);
    if (idx > 0) {
      final prev = messages[idx - 1];
      if (prev.role == 'user') {
        final text = prev.message.toLowerCase();
        return text.contains('summary') || text.contains('report') || text.contains('📊');
      }
    }
    return false;
  }

  Widget _buildMessageBubble(ChatHistoryItem message, bool isMe, String userId, List<ChatHistoryItem> messages) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    final report = isMe ? null : ChatResponseParser.parse(message.message);
    final isStreaming = message.id == _streamingMessageId;
    
    final showSummary = !isMe && !isStreaming && report != null && !report.isEmpty && (
      _showSummaryMessageIds.contains(message.id) ||
      _isFinancialSummaryExplicitlyRequested(messages, message)
    );

    final isPayConfirm = !isMe && !isStreaming && message.message.startsWith('[PAY_CONFIRM:');
    String cleanContent = (isMe || !showSummary) ? message.message : _cleanMessageText(message.message);
    if (isPayConfirm) {
      cleanContent = cleanContent.replaceFirst(RegExp(r'^\[PAY_CONFIRM:.*?\]'), '');
    }

    if (isStreaming) {
      final int limit = _revealedLength.clamp(0, cleanContent.length);
      cleanContent = cleanContent.substring(0, limit);
    }

    return GestureDetector(
      onLongPress: () => _showMessageActionsBottomSheet(context, message, userId),
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          // Goal 4: AI messages use approximately 90% of available screen width
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isMe ? 0.82 : 0.90)),
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isMe 
                      ? const LinearGradient(
                          colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe 
                      ? null 
                      : const Color(0xFF1E1E1E).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe 
                        ? const Color(0xFF0066FF).withOpacity(0.24) 
                        : Colors.white.withOpacity(0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cleanContent.isNotEmpty)
                      MarkdownBody(
                        data: cleanContent,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.white, fontSize: 16.0, height: 1.5), // Goal 5: typography improvements
                          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          em: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                          h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                          h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                          h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                          listBullet: const TextStyle(color: Color(0xFF00E5FF)),
                          blockSpacing: 12.0, // Paragraph spacing
                        ),
                        builders: {
                          'code': CodeBlockBuilder(),
                        },
                      ),
                    
                    if (isPayConfirm)
                      _buildPayConfirmationCard(message, userId, messages),
                    
                    if (!isMe && !isStreaming && report != null) ...[
                      if (report.categorySpend.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        CategorySpendChart(spending: report.categorySpend),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // More Details Button
                            InkWell(
                              onTap: () => context.push('/advisor'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.18)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.analytics_outlined, color: Color(0xFF00E5FF), size: 14),
                                    SizedBox(width: 6),
                                    Text('More Details', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Corner small timestamp (Goal 5)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                child: Text(
                  timeStr,
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ),
 
              if (!isMe && !isStreaming) ...[
                MessageActionBar(
                  text: message.message,
                  onRegenerate: () => _sendMessage(userId, message.message),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayConfirmationCard(ChatHistoryItem message, String userId, List<ChatHistoryItem> messages) {
    final match = RegExp(r'^\[PAY_CONFIRM:(.*?)\]').firstMatch(message.message);
    final idsStr = match?.group(1) ?? '';
    final billIds = idsStr.split(',').where((id) => id.isNotEmpty).toList();

    final accounts = ref.watch(accountsProvider).value ?? [];
    if (accounts.isEmpty) return const SizedBox.shrink();

    // Scan preceding user message to find keywords like "sbi", "cash", "gpay", etc., and preselect matching account
    String? lastUserMsgText;
    final int idx = messages.indexOf(message);
    if (idx > 0) {
      final prev = messages[idx - 1];
      if (prev.role == 'user') {
        lastUserMsgText = prev.message;
      }
    }

    // Default detection
    Account defaultAccount = accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
    if (lastUserMsgText != null) {
      final lower = lastUserMsgText.toLowerCase();
      if (lower.contains('cash')) {
        defaultAccount = accounts.firstWhere((a) => a.name.toLowerCase().contains('cash'), orElse: () => defaultAccount);
      } else if (lower.contains('sbi')) {
        defaultAccount = accounts.firstWhere((a) => a.name.toLowerCase().contains('sbi'), orElse: () => defaultAccount);
      } else if (lower.contains('hdfc')) {
        defaultAccount = accounts.firstWhere((a) => a.name.toLowerCase().contains('hdfc'), orElse: () => defaultAccount);
      } else if (lower.contains('axis')) {
        defaultAccount = accounts.firstWhere((a) => a.name.toLowerCase().contains('axis'), orElse: () => defaultAccount);
      }
    }

    final selectedAccountId = _selectedAccountForMessage[message.id] ?? defaultAccount.id;
    if (_selectedAccountForMessage[message.id] == null) {
      _selectedAccountForMessage[message.id] = selectedAccountId;
    }

    final selectedAccount = accounts.firstWhere((a) => a.id == selectedAccountId, orElse: () => defaultAccount);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Account:',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAccountId,
                dropdownColor: const Color(0xFF0C0C0C),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.displayTitle} (₹${(acc.balance / 100.0).toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAccountForMessage[message.id] = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _messageController.clear();
                    ref.read(chatNotifierProvider.notifier).sendMessage(userId, 'Cancel Payment');
                  },
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _messageController.clear();
                    ref.read(chatNotifierProvider.notifier).sendMessage(
                      userId,
                      'Confirm Payment using ${selectedAccount.name}',
                    );
                  },
                  child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return const ThinkingIndicator();
  }
}

// Redesigned Premium Thinking Indicator (Goal 12)
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1527).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rotating sparkle icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 15),
                );
              },
            ),
            const SizedBox(width: 8),
            // Three bouncing dots
            Row(
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double delay = index * 0.2;
                    double progress = _controller.value - delay;
                    if (progress < 0) {
                      progress += 1.0;
                    }
                    final double bounce = math.sin(progress * 2 * math.pi) * -3.0; // max 3dp bounce
                    final double opacity = 0.3 + 0.7 * (1.0 - (progress - 0.5).abs() * 2);
                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, bounce),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E5FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class SineCurve extends Curve {
  const SineCurve();
  @override
  double transformInternal(double t) {
    return math.sin(t * math.pi);
  }
}

// 7. Message bubble entrance animation
class AnimatedBubble extends StatelessWidget {
  final Widget child;
  final bool isMe;

  const AnimatedBubble({super.key, required this.child, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((isMe ? 40.0 : -40.0) * (1.0 - value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String text = element.textContent;
    final bool isCodeBlock = text.contains('\n');
    
    if (!isCodeBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF00E5FF),
            fontSize: 13,
          ),
        ),
      );
    }

    return CodeBlockWidget(code: text.trim());
  }
}

class CodeBlockWidget extends StatefulWidget {
  final String code;
  const CodeBlockWidget({super.key, required this.code});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1527),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code_rounded, color: Color(0xFF00E5FF), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Code Block',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _copyCode,
                  child: Row(
                    children: [
                      Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        color: _copied ? const Color(0xFF00E676) : Colors.white54,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: TextStyle(
                          color: _copied ? const Color(0xFF00E676) : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Text(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFE2E8F0),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
