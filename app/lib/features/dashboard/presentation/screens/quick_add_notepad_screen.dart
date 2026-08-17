import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/quick_add_notepad_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/presentation/providers/account_formatters.dart';

class QuickAddNotepadScreen extends ConsumerStatefulWidget {
  const QuickAddNotepadScreen({super.key});

  @override
  ConsumerState<QuickAddNotepadScreen> createState() => _QuickAddNotepadScreenState();
}

class _QuickAddNotepadScreenState extends ConsumerState<QuickAddNotepadScreen> with WidgetsBindingObserver {
  final TextEditingController _notepadController = TextEditingController();
  final ScrollController _notepadScrollController = ScrollController();
  final ScrollController _lineRailScrollController = ScrollController();
  final FocusNode _notepadFocusNode = FocusNode();
  
  late final ValueNotifier<List<ParsedLine>> _parsedLinesNotifier;
  late final ValueNotifier<bool> _isProcessingNotifier;
  late final ValueNotifier<int> _currentLineIndexNotifier;
  late final ValueNotifier<bool> _undoStackEmptyNotifier;
  late final ValueNotifier<bool> _redoStackEmptyNotifier;

  bool get _isProcessing => _isProcessingNotifier.value;
  List<ParsedLine> get _parsedLines => _parsedLinesNotifier.value;

  int _activeTab = 0; // 0 = Notepad, 1 = Preview
  Timer? _debounceTimer;

  // Undo/Redo history stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastText = '';
  int _lastSelectionOffset = -1;

  // Distraction-free Typing Mode states
  bool _isTypingMode = false;

  bool get _showTypingMode => _isTypingMode && MediaQuery.of(context).viewInsets.bottom > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _parsedLinesNotifier = ValueNotifier<List<ParsedLine>>([]);
    _isProcessingNotifier = ValueNotifier<bool>(false);
    _currentLineIndexNotifier = ValueNotifier<int>(0);
    _undoStackEmptyNotifier = ValueNotifier<bool>(true);
    _redoStackEmptyNotifier = ValueNotifier<bool>(true);

    _notepadController.addListener(_onTextChanged);
    _notepadScrollController.addListener(_syncScroll);
    _notepadFocusNode.addListener(_onFocusChanged);
    _notepadFocusNode.requestFocus();
    
    // Quick Add must always open with an empty editor (Goal 1). No seed text.
    _notepadController.text = "";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notepadController.removeListener(_onTextChanged);
    _notepadController.dispose();
    _notepadScrollController.removeListener(_syncScroll);
    _notepadScrollController.dispose();
    _lineRailScrollController.dispose();
    _notepadFocusNode.removeListener(_onFocusChanged);
    _notepadFocusNode.dispose();
    _debounceTimer?.cancel();

    _parsedLinesNotifier.dispose();
    _isProcessingNotifier.dispose();
    _currentLineIndexNotifier.dispose();
    _undoStackEmptyNotifier.dispose();
    _redoStackEmptyNotifier.dispose();

    super.dispose();
  }

  void _onFocusChanged() {
    if (_notepadFocusNode.hasFocus != _isTypingMode) {
      setState(() {
        _isTypingMode = _notepadFocusNode.hasFocus;
      });
    }
  }

  void _syncScroll() {
    if (_lineRailScrollController.hasClients) {
      _lineRailScrollController.jumpTo(_notepadScrollController.offset);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Keep cursor in view when keyboard size changes (e.g. keyboard appears) (Goal 2 & 6: no unfocus calls)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCursor();
      }
    });
  }

  void _scrollToCursor() {
    if (!_notepadFocusNode.hasFocus) return;
    if (!_notepadScrollController.hasClients) return;

    final text = _notepadController.text;
    final selection = _notepadController.selection;
    if (selection.baseOffset < 0 || selection.baseOffset > text.length) return;

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final cursorLineIndex = '\n'.allMatches(textBeforeCursor).length;

    const double fontSize = 13.0;
    const double lineSpacingMultiplier = 1.35;
    const double lineHeight = fontSize * lineSpacingMultiplier; // ~17.55 pixels per line
    const double topPadding = 12.0;

    final cursorY = topPadding + (cursorLineIndex * lineHeight);
    final viewportHeight = _notepadScrollController.position.viewportDimension;
    final currentScroll = _notepadScrollController.offset;

    const double topSafetyMargin = 35.0;
    final double bottomSafetyMargin = _showTypingMode ? 100.0 : 60.0;

    double targetScroll = currentScroll;

    if (cursorY < currentScroll + topSafetyMargin) {
      targetScroll = (cursorY - topSafetyMargin).clamp(0.0, _notepadScrollController.position.maxScrollExtent);
    } else if (cursorY > currentScroll + viewportHeight - bottomSafetyMargin) {
      targetScroll = (cursorY - viewportHeight + bottomSafetyMargin).clamp(0.0, _notepadScrollController.position.maxScrollExtent);
    }

    if (targetScroll != currentScroll) {
      _notepadScrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged() {
    final text = _notepadController.text;
    final selection = _notepadController.selection;

    // Track active typing line index based on selection
    int newActiveLine = 0;
    if (selection.baseOffset >= 0 && selection.baseOffset <= text.length) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      newActiveLine = '\n'.allMatches(textBeforeCursor).length;
    }
    if (newActiveLine != _currentLineIndexNotifier.value) {
      _currentLineIndexNotifier.value = newActiveLine;
    }

    if (selection.baseOffset != _lastSelectionOffset) {
      _lastSelectionOffset = selection.baseOffset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToCursor();
        }
      });
    }

    // Update undo/redo empty states (Goal 6: prevent rebuilding editor)
    final undoEmpty = _undoStack.isEmpty;
    if (_undoStackEmptyNotifier.value != undoEmpty) {
      _undoStackEmptyNotifier.value = undoEmpty;
    }
    final redoEmpty = _redoStack.isEmpty;
    if (_redoStackEmptyNotifier.value != redoEmpty) {
      _redoStackEmptyNotifier.value = redoEmpty;
    }

    if (text == _lastText) return;

    // Track undo stack
    if (_lastText.isNotEmpty) {
      if (_undoStack.isEmpty || _undoStack.last != _lastText) {
        _undoStack.add(_lastText);
        if (_undoStack.length > 50) _undoStack.removeAt(0);
      }
      _redoStack.clear();
      
      _undoStackEmptyNotifier.value = _undoStack.isEmpty;
      _redoStackEmptyNotifier.value = _redoStack.isEmpty;
    }
    _lastText = text;

    // Debounce live parsing
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _runLiveParse();
    });
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      final prev = _undoStack.removeLast();
      _redoStack.add(_notepadController.text);
      _notepadController.value = TextEditingValue(
        text: prev,
        selection: TextSelection.collapsed(offset: prev.length),
      );
      _lastText = prev;
      _undoStackEmptyNotifier.value = _undoStack.isEmpty;
      _redoStackEmptyNotifier.value = _redoStack.isEmpty;
      _runLiveParse();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final next = _redoStack.removeLast();
      _undoStack.add(_notepadController.text);
      _notepadController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      _lastText = next;
      _undoStackEmptyNotifier.value = _undoStack.isEmpty;
      _redoStackEmptyNotifier.value = _redoStack.isEmpty;
      _runLiveParse();
    }
  }

  Future<void> _runLiveParse() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    _isProcessingNotifier.value = true;
    try {
      final parser = ref.read(quickAddNotepadServiceProvider);
      final accounts = ref.read(accountsProvider).value ?? [];
      final rawParsed = parser.parseDocument(_notepadController.text, accounts);
      
      // Check duplicates against SQLite
      final reconciled = await parser.detectDuplicates(rawParsed, userId);

      if (mounted) {
        _parsedLinesNotifier.value = reconciled;
      }
    } finally {
      if (mounted) {
        _isProcessingNotifier.value = false;
      }
    }
  }

  void _clearAll() {
    _notepadController.clear();
    _parsedLinesNotifier.value = [];
    _undoStack.clear();
    _redoStack.clear();
    _lastText = '';
    _undoStackEmptyNotifier.value = true;
    _redoStackEmptyNotifier.value = true;
  }

  double _calculateTotalIncome() {
    return _parsedLines
        .where((l) => l.error == null && l.type == 'income')
        .fold(0.0, (sum, l) => sum + (l.amount ?? 0));
  }

  double _calculateTotalExpense() {
    return _parsedLines
        .where((l) => l.error == null && l.type == 'expense')
        .fold(0.0, (sum, l) => sum + (l.amount ?? 0));
  }

  double _calculateTotalTransfers() {
    return _parsedLines
        .where((l) => l.error == null && (l.type == 'transfer' || l.type == 'credit_card_payment'))
        .fold(0.0, (sum, l) => sum + (l.amount ?? 0));
  }

  double _calculateTotalBills() {
    return _parsedLines
        .where((l) => l.error == null && l.type == 'upcoming_bill')
        .fold(0.0, (sum, l) => sum + (l.amount ?? 0));
  }

  int _countErrors() {
    return _parsedLines.where((l) => l.error != null).length;
  }

  int _countDuplicates() {
    return _parsedLines.where((l) => l.isDuplicate).length;
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
          Expanded(
            child: Text(
              ' ' + '.' * 50,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(color: Colors.white10, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Future<void> _triggerSaveAll() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) return;

    final accounts = ref.read(accountsProvider).value ?? [];
    final linesToProcess = List<ParsedLine>.from(_parsedLines);

    // Resolve any ambiguous accounts before saving
    for (int i = 0; i < linesToProcess.length; i++) {
      final line = linesToProcess[i];
      if (line.error != null) continue;

      final matchedAccounts = accounts.where((acc) {
        final query = (line.accountName ?? '').toLowerCase().trim();
        if (query.isEmpty) return false;
        return acc.name.toLowerCase().contains(query) || query.contains(acc.name.toLowerCase());
      }).toList();

      if (matchedAccounts.length > 1) {
        final selectedAccountName = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0C0C0C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
            ),
            title: Text(
              'Select Account for Line ${i + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The phrase "${line.accountName}" matches multiple accounts. Please select one:',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ...matchedAccounts.map((acc) => ListTile(
                      tileColor: Colors.white.withOpacity(0.02),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(acc.displayTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(acc.displaySubtitle, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54, size: 16),
                      onTap: () {
                        Navigator.pop(context, acc.displayTitle);
                      },
                    )),
                  ],
                ),
              ),
            ),
          ),
        );

        if (selectedAccountName != null) {
          linesToProcess[i] = line.copyWith(accountName: selectedAccountName);
        }
      }
    }

    _isProcessingNotifier.value = true;
    try {
      final parser = ref.read(quickAddNotepadServiceProvider);
      final results = await parser.saveAll(linesToProcess, userId);

      if (mounted) {
        final accountName = linesToProcess.firstWhere((l) => l.accountName != null && l.error == null, orElse: () => ParsedLine(rawText: '', type: '', accountName: 'Cash Wallet')).accountName ?? 'Cash Wallet';
        final hasYesterday = linesToProcess.any((l) => l.dueDate != null && l.error == null && DateFormat('yyyy-MM-dd').format(l.dueDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))));
        final dateApplied = hasYesterday ? 'Yesterday' : 'Today';
        final categoryName = linesToProcess.firstWhere((l) => l.category != null && l.error == null, orElse: () => ParsedLine(rawText: '', type: '', category: 'Food')).category ?? 'Food';
        final totalIncome = _calculateTotalIncome();
        final totalExpense = _calculateTotalExpense();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0C0C0C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF0066FF), width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        '✓ Transactions Saved',
                        style: TextStyle(color: Color(0xFF00FF88), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Lines Parsed', '${results['parsed']}'),
                    _buildSummaryRow('Saved', '${results['saved']}'),
                    _buildSummaryRow('Duplicates', '${results['skipped']}'),
                    _buildSummaryRow('Errors', '${results['failed']}'),
                    _buildSummaryRow('Net Income', '₹${totalIncome.toStringAsFixed(0)}'),
                    _buildSummaryRow('Net Expense', '₹${totalExpense.toStringAsFixed(0)}'),
                    _buildSummaryRow('Account Updated', accountName),
                    _buildSummaryRow('Date Applied', dateApplied),
                    _buildSummaryRow('Category', categoryName),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // pop dialog
                        context.pop(); // go back to dashboard
                      },
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save all: $e'), backgroundColor: const Color(0xFFFF3B30)),
        );
      }
    } finally {
      if (mounted) _isProcessingNotifier.value = false;
    }
  }

  Widget _buildAnimatedWrapper({
    required bool isVisible,
    required double height,
    required Widget child,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: isVisible ? height : 0.0,
      margin: isVisible ? margin : EdgeInsets.zero,
      child: ClipRect(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          opacity: isVisible ? 1.0 : 0.0,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      height: 72,
      color: const Color(0xFF080808),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick\nAdd AI',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.1),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Add multiple transactions at once',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _undoStackEmptyNotifier,
            builder: (context, undoEmpty, child) {
              return IconButton(
                icon: const Icon(Icons.undo, color: Colors.white54, size: 20),
                onPressed: undoEmpty ? null : _undo,
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _redoStackEmptyNotifier,
            builder: (context, redoEmpty, child) {
              return IconButton(
                icon: const Icon(Icons.redo, color: Colors.white54, size: 20),
                onPressed: redoEmpty ? null : _redo,
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFFF3B30), size: 18),
            label: const Text('Clear', style: TextStyle(color: Color(0xFFFF3B30))),
            onPressed: _clearAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCurrentLineStatusWidget(List<ParsedLine> parsedLines, int currentLineIndex) {
    if (parsedLines.isEmpty || currentLineIndex >= parsedLines.length) {
      return const Text(
        'Start typing...',
        style: TextStyle(color: Colors.white30, fontSize: 11),
      );
    }
    
    final item = parsedLines[currentLineIndex];
    if (item.error != null) {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFFF3B30), size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Line ${currentLineIndex + 1}: ${item.error}',
              style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (item.isDuplicate) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFFFFCC00), size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Line ${currentLineIndex + 1}: Duplicate',
              style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (item.amount != null) {
      final typeStr = item.type[0].toUpperCase() + item.type.substring(1);
      final categoryStr = item.category ?? 'Uncategorized';
      return Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF00FF88), size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Line ${currentLineIndex + 1}: ₹${item.amount!.toStringAsFixed(0)} ($typeStr - $categoryStr)',
              style: const TextStyle(color: Color(0xFF00FF88), fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Text(
        'Line ${currentLineIndex + 1}: ${item.rawText.isEmpty ? "Enter transaction details" : item.rawText}',
        style: const TextStyle(color: Colors.white30, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildAnimatedAccessoryBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _showTypingMode ? 54.0 : 0.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        opacity: _showTypingMode ? 1.0 : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: 54.0,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _currentLineIndexNotifier,
                      builder: (context, currentLineIndex, child) {
                        return ValueListenableBuilder<List<ParsedLine>>(
                          valueListenable: _parsedLinesNotifier,
                          builder: (context, parsedLines, child) {
                            return _buildCurrentLineStatusWidget(parsedLines, currentLineIndex);
                          },
                        );
                      },
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _undoStackEmptyNotifier,
                  builder: (context, undoEmpty, child) {
                    return IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white70, size: 20),
                      onPressed: undoEmpty ? null : _undo,
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _redoStackEmptyNotifier,
                  builder: (context, redoEmpty, child) {
                    return IconButton(
                      icon: const Icon(Icons.redo, color: Colors.white70, size: 20),
                      onPressed: redoEmpty ? null : _redo,
                    );
                  },
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<List<ParsedLine>>(
                  valueListenable: _parsedLinesNotifier,
                  builder: (context, parsedLines, child) {
                    final validLines = parsedLines.where((l) => l.error == null).length;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (validLines > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FF88),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: _isProcessing ? null : _triggerSaveAll,
                              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              _notepadFocusNode.unfocus();
                            },
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final categories = categoriesAsync.value ?? [];
    final paymentMethods = paymentMethodsAsync.value ?? [];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header is always visible (Goal 3 & 4)
            _buildCustomHeader(),

            // Tabs toggle bar (Notepad / Preview toggle) is always visible (Goal 3 & 4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF080808),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      label: 'Notepad',
                      icon: Icons.edit_note_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      label: 'Preview Table',
                      icon: Icons.preview_outlined,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _activeTab == 0
                  ? _buildNotepadEditorTab()
                  : _buildPreviewTableTab(categories, paymentMethods),
            ),

            // Collapsible Live Summary Panel
            _buildAnimatedWrapper(
              isVisible: !_showTypingMode,
              height: 96.0,
              child: _buildSummaryPanel(),
            ),

            // Collapsible Footer actions
            _buildAnimatedWrapper(
              isVisible: !_showTypingMode,
              height: 86.0,
              child: _buildFooterActions(),
            ),

            // Keyboard Accessory Bar
            _buildAnimatedAccessoryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0066FF).withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF0066FF).withOpacity(0.3) : Colors.white.withOpacity(0.05),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? const Color(0xFF00E5FF) : Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotepadEditorTab() {
    return Column(
      children: [
        // Editor view (Goal 6: Separate the editor from Live Parsing using independent widget)
        Expanded(
          child: NotepadEditor(
            controller: _notepadController,
            focusNode: _notepadFocusNode,
            scrollController: _notepadScrollController,
            lineRailScrollController: _lineRailScrollController,
            isTypingMode: _isTypingMode,
          ),
        ),

        // Collapsible Live Parsing Status list
        _buildAnimatedWrapper(
          isVisible: !_isTypingMode && MediaQuery.of(context).viewInsets.bottom == 0,
          height: 180.0, // Increase height slightly since we now show structured cards
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ValueListenableBuilder<bool>(
            valueListenable: _isProcessingNotifier,
            builder: (context, isProcessing, child) {
              return ValueListenableBuilder<List<ParsedLine>>(
                valueListenable: _parsedLinesNotifier,
                builder: (context, parsedLines, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: Color(0xFF00E5FF), size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE PARSING STATUS & ASSISTANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            if (isProcessing)
                              const SizedBox(
                                height: 10,
                                width: 10,
                                child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 1.5),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: parsedLines.isEmpty
                              ? Center(
                                  child: Text(
                                    'No transactions parsed yet. Start typing to see suggestions.',
                                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: parsedLines.length,
                                  separatorBuilder: (context, idx) => Divider(color: Colors.white.withOpacity(0.03), height: 8),
                                  itemBuilder: (context, index) {
                                    final item = parsedLines[index];
                                    return _buildLiveStatusRow(item, index);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatusRow(ParsedLine item, int index) {
    if (item.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B30).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFFF3B30), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Line ${index + 1}: "${item.rawText}"',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.error!,
                      style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLowConfidence = item.confidence < 0.8;
    final formattedDate = item.dueDate != null ? DateFormat('dd MMM yyyy').format(item.dueDate!) : '';
    final confidencePercent = (item.confidence * 100).toStringAsFixed(0);
    final typeName = item.type[0].toUpperCase() + item.type.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLowConfidence 
              ? const Color(0xFFFFCC00).withOpacity(0.06) 
              : Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowConfidence 
                ? const Color(0xFFFFCC00).withOpacity(0.3) 
                : Colors.white.withOpacity(0.05),
            width: isLowConfidence ? 1.2 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type == 'transfer'
                      ? 'Transfer • ${item.accountName ?? "From"} → ${item.merchant ?? "To"}'
                      : '$typeName • ${item.category ?? "Miscellaneous"}',
                  style: TextStyle(
                    color: item.type == 'transfer'
                        ? const Color(0xFF00E5FF)
                        : (item.type == 'income' ? const Color(0xFF00FF88) : const Color(0xFFFF9F0A)),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isLowConfidence ? const Color(0xFFFFCC00) : const Color(0xFF0066FF)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Confidence $confidencePercent%',
                    style: TextStyle(
                      color: isLowConfidence ? const Color(0xFFFFCC00) : const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                      children: [
                        if (item.type == 'transfer') ...[
                          const TextSpan(text: 'From:\n', style: TextStyle(color: Colors.white38)),
                          TextSpan(text: '${item.accountName ?? "-"}\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const TextSpan(text: 'To:\n', style: TextStyle(color: Colors.white38)),
                          TextSpan(text: '${item.merchant ?? "-"}\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ] else ...[
                          const TextSpan(text: 'Merchant:\n', style: TextStyle(color: Colors.white38)),
                          TextSpan(text: '${item.merchant ?? "-"}\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                        const TextSpan(text: 'Amount:\n', style: TextStyle(color: Colors.white38)),
                        TextSpan(text: '₹${item.amount?.toStringAsFixed(0) ?? "0"}\n', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                        if (item.type != 'transfer') ...[
                          const TextSpan(text: 'Account:\n', style: TextStyle(color: Colors.white38)),
                          TextSpan(text: '${item.accountName ?? "-"}\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const TextSpan(text: 'Payment:\n', style: TextStyle(color: Colors.white38)),
                          TextSpan(text: '${item.paymentMethod ?? "-"}\n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                        const TextSpan(text: 'Date:\n', style: TextStyle(color: Colors.white38)),
                        TextSpan(
                          text: item.dueDate != null && DateFormat('yyyy-MM-dd').format(item.dueDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)))
                              ? 'Yesterday ($formattedDate)'
                              : item.dueDate != null && DateFormat('yyyy-MM-dd').format(item.dueDate!) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                                  ? 'Today ($formattedDate)'
                                  : formattedDate,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isLowConfidence) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFFCC00), size: 14),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Confidence is low. Confirm details?',
                        style: TextStyle(color: Color(0xFFFFCC00), fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFFFFCC00).withOpacity(0.2),
                      ),
                      onPressed: () {
                        final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                        currentList[index] = currentList[index].copyWith(confidence: 1.0);
                        _parsedLinesNotifier.value = currentList;
                      },
                      child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            if (item.isDuplicate) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, color: Color(0xFFFFCC00), size: 14),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Duplicate transaction detected.', style: TextStyle(color: Color(0xFFFFCC00), fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDuplicateActionChip(index, 'skip', 'Skip', Colors.red),
                  const SizedBox(width: 8),
                  _buildDuplicateActionChip(index, 'replace', 'Replace', Colors.orange),
                  const SizedBox(width: 8),
                  _buildDuplicateActionChip(index, 'keep', 'Keep Both', Colors.green),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicateActionChip(int index, String action, String label, Color color) {
    final isSelected = _parsedLinesNotifier.value[index].duplicateAction == action;
    return GestureDetector(
      onTap: () {
        final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
        currentList[index] = currentList[index].copyWith(duplicateAction: action);
        _parsedLinesNotifier.value = currentList;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTableTab(List<Category> categories, List<PaymentMethod> paymentMethods) {
    return ValueListenableBuilder<List<ParsedLine>>(
      valueListenable: _parsedLinesNotifier,
      builder: (context, parsedLines, child) {
        if (parsedLines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.border_all, color: Colors.white12, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No items to display. Go back and type some transactions.',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.015),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'EDIT / REVIEW BEFORE SAVING',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                      columns: const [
                        DataColumn(label: Text('Line', style: TextStyle(color: Colors.white30, fontSize: 10))),
                        DataColumn(label: Text('Merchant', style: TextStyle(color: Colors.white54, fontSize: 10))),
                        DataColumn(label: Text('Category', style: TextStyle(color: Colors.white54, fontSize: 10))),
                        DataColumn(label: Text('Account', style: TextStyle(color: Colors.white54, fontSize: 10))),
                        DataColumn(label: Text('Type', style: TextStyle(color: Colors.white54, fontSize: 10))),
                        DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white54, fontSize: 10))),
                        DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white30, fontSize: 10))),
                      ],
                      rows: List<DataRow>.generate(parsedLines.length, (index) {
                        final item = parsedLines[index];
                        final isError = item.error != null;

                        return DataRow(
                          cells: [
                            // Line Index
                            DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.white30, fontSize: 11))),
                            // Merchant field (editable)
                            DataCell(
                              isError
                                  ? Text(item.rawText, style: const TextStyle(color: Colors.white30, fontSize: 11))
                                  : SizedBox(
                                      width: 100,
                                      child: TextField(
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        controller: TextEditingController(text: item.merchant),
                                        onChanged: (val) {
                                          final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                          currentList[index] = currentList[index].copyWith(merchant: val);
                                          _parsedLinesNotifier.value = currentList;
                                        },
                                      ),
                                    ),
                            ),
                            // Category (Dropdown)
                            DataCell(
                              isError
                                  ? const Text('-')
                                  : DropdownButton<String>(
                                      dropdownColor: const Color(0xFF0C0C0C),
                                      value: categories.any((c) => c.name.toLowerCase() == (item.category ?? '').toLowerCase())
                                          ? categories.firstWhere((c) => c.name.toLowerCase() == (item.category ?? '').toLowerCase()).name
                                          : (categories.isNotEmpty ? categories.first.name : null),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      underline: Container(),
                                      items: categories.map((cat) {
                                        return DropdownMenuItem<String>(
                                          value: cat.name,
                                          child: Text(cat.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                          currentList[index] = currentList[index].copyWith(category: val);
                                          _parsedLinesNotifier.value = currentList;
                                        }
                                      },
                                    ),
                            ),
                            // Account/Payment Method (Dropdown)
                            DataCell(
                              isError
                                  ? const Text('-')
                                  : DropdownButton<String>(
                                      dropdownColor: const Color(0xFF0C0C0C),
                                      value: paymentMethods.any((pm) => pm.name.toLowerCase().contains((item.accountName ?? '').toLowerCase()) || (item.accountName ?? '').toLowerCase().contains(pm.name.toLowerCase()))
                                          ? paymentMethods.firstWhere((pm) => pm.name.toLowerCase().contains((item.accountName ?? '').toLowerCase()) || (item.accountName ?? '').toLowerCase().contains(pm.name.toLowerCase())).name
                                          : (paymentMethods.isNotEmpty ? paymentMethods.first.name : null),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      underline: Container(),
                                      items: paymentMethods.map((pm) {
                                        return DropdownMenuItem<String>(
                                          value: pm.name,
                                          child: Text(pm.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                          currentList[index] = currentList[index].copyWith(accountName: val);
                                          _parsedLinesNotifier.value = currentList;
                                        }
                                      },
                                    ),
                            ),
                            // Type (Dropdown)
                            DataCell(
                              isError
                                  ? const Text('-')
                                  : DropdownButton<String>(
                                      dropdownColor: const Color(0xFF0C0C0C),
                                      value: item.type,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      underline: Container(),
                                      items: const [
                                        DropdownMenuItem(value: 'expense', child: Text('Expense')),
                                        DropdownMenuItem(value: 'income', child: Text('Income')),
                                        DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                                        DropdownMenuItem(value: 'credit_card_payment', child: Text('CC Payment')),
                                        DropdownMenuItem(value: 'upcoming_bill', child: Text('Bill')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                          currentList[index] = currentList[index].copyWith(type: val);
                                          _parsedLinesNotifier.value = currentList;
                                        }
                                      },
                                    ),
                            ),
                            // Amount (Editable)
                            DataCell(
                              isError
                                  ? const Text('Error', style: TextStyle(color: Colors.red))
                                  : SizedBox(
                                      width: 60,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        controller: TextEditingController(text: item.amount?.toStringAsFixed(0)),
                                        onChanged: (val) {
                                          final amtVal = double.tryParse(val) ?? 0.0;
                                          final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                          currentList[index] = currentList[index].copyWith(amount: amtVal);
                                          _parsedLinesNotifier.value = currentList;
                                        },
                                      ),
                                    ),
                            ),
                            // Delete Row Action
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30), size: 18),
                                onPressed: () {
                                  final currentList = List<ParsedLine>.from(_parsedLinesNotifier.value);
                                  currentList.removeAt(index);
                                  _parsedLinesNotifier.value = currentList;
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryPanel() {
    return ValueListenableBuilder<List<ParsedLine>>(
      valueListenable: _parsedLinesNotifier,
      builder: (context, parsedLines, child) {
        final income = _calculateTotalIncome();
        final expense = _calculateTotalExpense();
        final transfer = _calculateTotalTransfers();
        final bill = _calculateTotalBills();
        final net = income - expense;
        final duplicates = _countDuplicates();
        final errors = _countErrors();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF080808),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Income', '₹${income.toStringAsFixed(0)}', const Color(0xFF00FF88)),
                  _buildSummaryItem('Expenses', '₹${expense.toStringAsFixed(0)}', const Color(0xFFFF3B30)),
                  _buildSummaryItem('Transfers', '₹${transfer.toStringAsFixed(0)}', const Color(0xFF00E5FF)),
                  _buildSummaryItem('Bills', '₹${bill.toStringAsFixed(0)}', const Color(0xFFFFCC00)),
                  _buildSummaryItem('Net Cashflow', '₹${net.toStringAsFixed(0)}', net >= 0 ? const Color(0xFF00FF88) : const Color(0xFFFF3B30)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Transactions: ${parsedLines.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  if (duplicates > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFCC00).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('Duplicates: $duplicates', style: const TextStyle(color: Color(0xFFFFCC00), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (errors > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFF3B30).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('Errors: $errors', style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooterActions() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isProcessingNotifier,
      builder: (context, isProcessing, child) {
        return ValueListenableBuilder<List<ParsedLine>>(
          valueListenable: _parsedLinesNotifier,
          builder: (context, parsedLines, child) {
            final validLines = parsedLines.where((l) => l.error == null).length;
            final totalLines = parsedLines.length;

            return Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF080808),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.white.withOpacity(0.03),
                      ),
                      onPressed: (totalLines > 0 && validLines > 0 && !isProcessing) ? _triggerSaveAll : null,
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Save Valid ($validLines)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class NotepadEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final ScrollController lineRailScrollController;
  final bool isTypingMode;

  const NotepadEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.lineRailScrollController,
    required this.isTypingMode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(isTypingMode ? 4 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(isTypingMode ? 12 : 20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Line Number Rail
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final lineCount = '\n'.allMatches(controller.text).length + 1;
              return Container(
                width: 32,
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.005),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(isTypingMode ? 12 : 20)),
                ),
                child: ListView.builder(
                  controller: lineRailScrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lineCount > 100 ? lineCount : 100,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 13.0 * 1.35, // Match text line height exactly
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: (index < lineCount) ? Colors.white24 : Colors.white10,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Container(width: 1, color: Colors.white.withOpacity(0.05)),
          // Input TextField
          Expanded(
            child: TextField(
              controller: controller,
              scrollController: scrollController,
              focusNode: focusNode,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              scrollPadding: const EdgeInsets.only(bottom: 60),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.35,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
                hintText: "Type transaction here ...\n\nExample:\n\nPurchase 500 cash\nYesterday Dinner 250 from HDFC\n7 Aug Fuel 1000 SBI Credit Card\n4 July 5000 transfer HDFC to SBI",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.12), height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
