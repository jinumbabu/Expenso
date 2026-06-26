import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/voice_service.dart';

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
    
    final notifier = ref.read(chatNotifierProvider.notifier);
    await notifier.sendMessage(userId, text);
    
    _scrollToBottom();
  }

  Future<void> _startVoiceEntry(String userId) async {
    setState(() {});
    final voiceNotifier = ref.read(voiceServiceProvider.notifier);
    
    voiceNotifier.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          setState(() {
            _messageController.text = text;
          });
        }
      },
    );

    // Show recording indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
        ),
        title: const Text('Listening...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5FF)),
            SizedBox(width: 20),
            Expanded(child: Text('Say something like:\n"How much left in my budget?"', style: TextStyle(color: Colors.white70, fontSize: 13))),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            onPressed: () {
              voiceNotifier.stopListening();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Stop & Process', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceiptAttachment(String userId) async {
    final ocrService = ref.read(ocrServiceProvider);
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Upload Receipt for AI Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF0066FF)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFF0066FF)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    
    final pickedFile = await ocrService.pickImage(source);
    if (pickedFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF050505),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF0066FF)),
            SizedBox(width: 20),
            Expanded(child: Text('Scanning receipt details...', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );

    try {
      final ocrResult = await ocrService.scanReceipt(File(pickedFile.path));
      if (mounted) Navigator.pop(context); // pop loading

      if (ocrResult != null && mounted) {
        final scannedMessage = 'Scanned Receipt: Spent ₹${ocrResult.amount.toStringAsFixed(0)} at ${ocrResult.merchant} for ${ocrResult.category}.';
        _messageController.text = scannedMessage;
        _sendMessage(userId, scannedMessage);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _confirmClearHistory(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050505),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF0066FF), width: 1.2)),
        title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete all messages? This action is local and irreversible.',
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
        backgroundColor: Color(0xFF050505),
        body: Center(child: Text('Please log in first.', style: TextStyle(color: Colors.white))),
      );
    }

    final chatState = ref.watch(chatNotifierProvider);
    final chatHistoryAsync = ref.watch(chatHistoryProvider(userId));
    final isProcessing = chatState.isLoading;

    ref.listen(chatHistoryProvider(userId), (_, __) => _scrollToBottom());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1A), Color(0xFF050505)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                            color: const Color(0xFF0066FF).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF00E5FF), size: 20),
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
                              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
                      tooltip: 'Clear Chat History',
                      onPressed: () => _confirmClearHistory(userId),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

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
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF))),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
                                  ),
                                  backgroundColor: const Color(0xFF0066FF).withOpacity(0.08),
                                  side: BorderSide(color: const Color(0xFF0066FF).withOpacity(0.2)),
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
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Attachment/Camera Scan Icon
                        IconButton(
                          icon: const Icon(Icons.attachment_outlined, color: Color(0xFF00E5FF)),
                          onPressed: () => _scanReceiptAttachment(userId),
                        ),
                        // Voice mic icon
                        IconButton(
                          icon: const Icon(Icons.mic_none_outlined, color: Color(0xFF00E5FF)),
                          onPressed: () => _startVoiceEntry(userId),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.12)),
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
                            color: isProcessing ? Colors.grey.shade900 : const Color(0xFF0066FF),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
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
              color: const Color(0xFF0066FF).withOpacity(0.08),
              border: Border.all(color: const Color(0xFF0066FF).withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Color(0xFF00E5FF),
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
                      const Icon(Icons.help_outline, color: Color(0xFF00E5FF), size: 18),
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
                    ? const Color(0xFF0066FF).withOpacity(0.2) 
                    : const Color(0xFF1E1E1E).withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isMe 
                      ? const Color(0xFF0066FF).withOpacity(0.3) 
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 14),
            SizedBox(width: 10),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
