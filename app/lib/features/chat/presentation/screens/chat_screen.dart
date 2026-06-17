import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/database/app_database.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<String> _suggestions = [
    'How much did I spend on food this month?',
    'What is my remaining budget?',
    'Can I afford a 20k phone?',
    'Show my recent transactions',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String userId, String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    
    // Send message via provider
    final notifier = ref.read(chatNotifierProvider.notifier);
    await notifier.sendMessage(userId, text);
    
    _scrollToBottom();
  }

  void _confirmClearHistory(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete all messages? This action is local and irreversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatNotifierProvider.notifier).clearChat(userId);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Please log in first.', style: TextStyle(color: Colors.white))),
      );
    }

    final chatState = ref.watch(chatNotifierProvider);
    final chatHistoryAsync = ref.watch(chatHistoryProvider(userId));
    final isProcessing = chatState.isLoading;

    // Trigger auto-scroll on new data / build
    ref.listen(chatHistoryProvider(userId), (_, __) => _scrollToBottom());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF002D27), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Chat Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenso AI Assistant',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Online • Secure Memory Active',
                              style: TextStyle(color: Colors.tealAccent, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white70),
                      tooltip: 'Clear Chat History',
                      onPressed: () => _confirmClearHistory(userId),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Chat Messages List
              Expanded(
                child: chatHistoryAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return _buildWelcomeState(userId);
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      itemCount: messages.length + (isProcessing ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _buildThinkingIndicator();
                        }
                        
                        final message = messages[index];
                        final isMe = message.role == 'user';
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),

              // Input Bar & Suggestion Chips
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Suggestions horizontal list (hide when typing or messages exist)
                  if (!isProcessing)
                    chatHistoryAsync.maybeWhen(
                      data: (messages) {
                        if (messages.length > 5) return const SizedBox.shrink();
                        return Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(
                                    suggestion,
                                    style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
                                  ),
                                  backgroundColor: const Color(0xFF00241F).withOpacity(0.5),
                                  side: BorderSide(color: Colors.tealAccent.withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onPressed: () => _sendMessage(userId, suggestion),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  
                  // Text input container
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Ask financial helper...',
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              onSubmitted: (_) => _sendMessage(userId, _messageController.text),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isProcessing ? Colors.grey.shade800 : Colors.tealAccent.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Color(0xFF001A16)),
                            onPressed: isProcessing
                                ? null
                                : () => _sendMessage(userId, _messageController.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeState(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal.withOpacity(0.08),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.purpleAccent, Colors.tealAccent],
              ).createShader(bounds),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Expenso AI Chat',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask me questions about your monthly spending, category budgets, or savings. '
            'Your conversations are encrypted and context minimizations are processed on-device for total privacy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTED QUERIES',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _sendMessage(userId, suggestion),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, color: Colors.tealAccent, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
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

  Widget _buildMessageBubble(ChatHistoryItem message, bool isMe) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFF004D40) 
                    : const Color(0xFF1E1E1E).withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isMe 
                      ? Colors.tealAccent.withOpacity(0.15) 
                      : Colors.white.withOpacity(0.04),
                ),
              ),
              child: Text(
                message.message,
                style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(color: Colors.white30, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 14),
            const SizedBox(width: 10),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent.shade100),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thinking...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
