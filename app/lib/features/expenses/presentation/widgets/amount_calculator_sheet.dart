import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalculatorResult {
  final double? value;
  final String? error;
  final bool isValid;

  CalculatorResult.success(this.value)
      : error = null,
        isValid = true;

  CalculatorResult.error(this.error)
      : value = null,
        isValid = false;
}

class CalculatorEngine {
  /// Evaluates an arithmetic expression string offline without using unsafe eval.
  /// Supports +, -, × (*), ÷ (/), and decimal numbers.
  static CalculatorResult evaluate(String expression) {
    var cleaned = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .trim();

    if (cleaned.isEmpty) {
      return CalculatorResult.error('Empty expression');
    }

    // Strip trailing operator if user evaluates incomplete expression (e.g. "100 +")
    while (cleaned.endsWith('+') ||
        cleaned.endsWith('-') ||
        cleaned.endsWith('*') ||
        cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    if (cleaned.isEmpty) {
      return CalculatorResult.error('Invalid calculation');
    }

    try {
      final tokens = _tokenize(cleaned);
      if (tokens.isEmpty) return CalculatorResult.error('Invalid calculation');

      final val = _parseTokens(tokens);
      if (val.isNaN || val.isInfinite) {
        return CalculatorResult.error('Cannot divide by zero');
      }

      // Clean floating point artifacts
      final rounded = double.parse(val.toStringAsFixed(4));
      return CalculatorResult.success(rounded);
    } catch (e) {
      final err = e.toString();
      if (err.contains('zero')) {
        return CalculatorResult.error('Cannot divide by zero');
      }
      return CalculatorResult.error('Invalid calculation');
    }
  }

  static List<dynamic> _tokenize(String input) {
    final List<dynamic> tokens = [];
    final StringBuffer numberBuffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final code = char.codeUnitAt(0);
      if ((code >= 48 && code <= 57) || char == '.') {
        numberBuffer.write(char);
      } else if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (numberBuffer.isNotEmpty) {
          final numStr = numberBuffer.toString();
          final parsed = double.tryParse(numStr);
          if (parsed == null) throw FormatException('Invalid number: $numStr');
          tokens.add(parsed);
          numberBuffer.clear();
        } else if (char == '-' && (tokens.isEmpty || tokens.last is String)) {
          // Negative sign handling
          numberBuffer.write(char);
          continue;
        } else {
          throw const FormatException('Unexpected operator position');
        }
        tokens.add(char);
      } else if (char == ' ') {
        continue;
      } else {
        throw FormatException('Invalid character: $char');
      }
    }

    if (numberBuffer.isNotEmpty) {
      final numStr = numberBuffer.toString();
      final parsed = double.tryParse(numStr);
      if (parsed == null) throw FormatException('Invalid number: $numStr');
      tokens.add(parsed);
    }

    return tokens;
  }

  static double _parseTokens(List<dynamic> tokens) {
    if (tokens.isEmpty) throw const FormatException('No tokens');

    // First pass: Multiplication & Division
    final List<dynamic> pass1 = [];
    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token == '*' || token == '/') {
        if (pass1.isEmpty || i + 1 >= tokens.length) {
          throw const FormatException('Invalid operator placement');
        }
        final left = pass1.removeLast() as double;
        final rightToken = tokens[i + 1];
        if (rightToken is! double) throw const FormatException('Invalid operand');

        if (token == '/') {
          if (rightToken == 0.0) throw Exception('Cannot divide by zero');
          pass1.add(left / rightToken);
        } else {
          pass1.add(left * rightToken);
        }
        i += 2;
      } else {
        pass1.add(token);
        i++;
      }
    }

    // Second pass: Addition & Subtraction
    if (pass1.isEmpty) throw const FormatException('Empty tokens in pass 2');
    double result = pass1[0] as double;

    int j = 1;
    while (j < pass1.length) {
      final op = pass1[j] as String;
      final right = pass1[j + 1] as double;
      if (op == '+') {
        result += right;
      } else if (op == '-') {
        result -= right;
      }
      j += 2;
    }

    return result;
  }

  static String formatDisplay(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    final str = val.toStringAsFixed(2);
    return str.endsWith('.00') ? val.toInt().toString() : str;
  }
}

class AmountCalculatorSheet extends StatefulWidget {
  final String? initialAmountText;

  const AmountCalculatorSheet({
    super.key,
    this.initialAmountText,
  });

  @override
  State<AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();
}

class _AmountCalculatorSheetState extends State<AmountCalculatorSheet> {
  String _expression = '';
  String _displayResult = '0';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountText != null &&
        widget.initialAmountText!.trim().isNotEmpty) {
      final parsed = double.tryParse(widget.initialAmountText!.trim());
      if (parsed != null && parsed > 0) {
        _expression = CalculatorEngine.formatDisplay(parsed);
        _displayResult = _expression;
      }
    }
  }

  void _onDigitTap(String digit) {
    setState(() {
      _errorMessage = null;

      // Handle decimal point constraint
      if (digit == '.') {
        final lastNumSegment = _expression.split(RegExp(r'[+\-×÷]')).last;
        if (lastNumSegment.contains('.')) return; // Already has decimal
        if (lastNumSegment.isEmpty) {
          _expression += '0.';
        } else {
          _expression += '.';
        }
      } else {
        _expression += digit;
      }

      _autoEvaluate();
    });
  }

  void _onOperatorTap(String op) {
    setState(() {
      _errorMessage = null;

      if (_expression.isEmpty) {
        if (op == '-') {
          _expression = '-';
        }
        return;
      }

      final lastChar = _expression[_expression.length - 1];
      if (lastChar == '+' || lastChar == '-' || lastChar == '×' || lastChar == '÷') {
        // Replace last operator
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
    });
  }

  void _onClearTap() {
    setState(() {
      _expression = '';
      _displayResult = '0';
      _errorMessage = null;
    });
  }

  void _onBackspaceTap() {
    setState(() {
      _errorMessage = null;
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        _autoEvaluate();
      }
    });
  }

  void _onEqualsTap() {
    setState(() {
      _errorMessage = null;
      if (_expression.trim().isEmpty) return;

      final res = CalculatorEngine.evaluate(_expression);
      if (res.isValid && res.value != null) {
        final formatted = CalculatorEngine.formatDisplay(res.value!);
        _expression = formatted;
        _displayResult = formatted;
      } else {
        _errorMessage = res.error ?? 'Invalid calculation';
      }
    });
  }

  void _autoEvaluate() {
    if (_expression.isEmpty) {
      _displayResult = '0';
      return;
    }

    final res = CalculatorEngine.evaluate(_expression);
    if (res.isValid && res.value != null) {
      _displayResult = CalculatorEngine.formatDisplay(res.value!);
    }
  }

  void _onDoneTap() {
    if (_expression.trim().isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final res = CalculatorEngine.evaluate(_expression);
    if (res.isValid && res.value != null && res.value! > 0) {
      Navigator.pop(context, res.value);
    } else {
      setState(() {
        _errorMessage = res.error ?? 'Please enter a valid non-zero amount';
      });
    }
  }

  Widget _buildCalcButton({
    required String label,
    Color? textColor,
    Color? bgColor,
    VoidCallback? onTap,
    Widget? customChild,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Material(
          color: bgColor ?? Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: customChild ??
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D121B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Calculator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 22),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Display Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expression display
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Result display or Error message
                    _errorMessage != null
                        ? Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              _displayResult,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Keypad
              // Row 1
              Row(
                children: [
                  _buildCalcButton(
                    label: 'C',
                    textColor: Colors.redAccent,
                    bgColor: Colors.redAccent.withOpacity(0.1),
                    onTap: _onClearTap,
                  ),
                  _buildCalcButton(
                    label: '⌫',
                    textColor: Colors.white70,
                    customChild: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 20),
                    onTap: _onBackspaceTap,
                  ),
                  _buildCalcButton(
                    label: '÷',
                    textColor: const Color(0xFF00E5FF),
                    bgColor: const Color(0xFF00E5FF).withOpacity(0.12),
                    onTap: () => _onOperatorTap('÷'),
                  ),
                  _buildCalcButton(
                    label: '×',
                    textColor: const Color(0xFF00E5FF),
                    bgColor: const Color(0xFF00E5FF).withOpacity(0.12),
                    onTap: () => _onOperatorTap('×'),
                  ),
                ],
              ),
              // Row 2
              Row(
                children: [
                  _buildCalcButton(label: '7', onTap: () => _onDigitTap('7')),
                  _buildCalcButton(label: '8', onTap: () => _onDigitTap('8')),
                  _buildCalcButton(label: '9', onTap: () => _onDigitTap('9')),
                  _buildCalcButton(
                    label: '−',
                    textColor: const Color(0xFF00E5FF),
                    bgColor: const Color(0xFF00E5FF).withOpacity(0.12),
                    onTap: () => _onOperatorTap('-'),
                  ),
                ],
              ),
              // Row 3
              Row(
                children: [
                  _buildCalcButton(label: '4', onTap: () => _onDigitTap('4')),
                  _buildCalcButton(label: '5', onTap: () => _onDigitTap('5')),
                  _buildCalcButton(label: '6', onTap: () => _onDigitTap('6')),
                  _buildCalcButton(
                    label: '+',
                    textColor: const Color(0xFF00E5FF),
                    bgColor: const Color(0xFF00E5FF).withOpacity(0.12),
                    onTap: () => _onOperatorTap('+'),
                  ),
                ],
              ),
              // Row 4
              Row(
                children: [
                  _buildCalcButton(label: '1', onTap: () => _onDigitTap('1')),
                  _buildCalcButton(label: '2', onTap: () => _onDigitTap('2')),
                  _buildCalcButton(label: '3', onTap: () => _onDigitTap('3')),
                  _buildCalcButton(
                    label: '=',
                    textColor: Colors.white,
                    bgColor: const Color(0xFF0066FF),
                    onTap: _onEqualsTap,
                  ),
                ],
              ),
              // Row 5
              Row(
                children: [
                  _buildCalcButton(label: '0', flex: 2, onTap: () => _onDigitTap('0')),
                  _buildCalcButton(label: '.', onTap: () => _onDigitTap('.')),
                ],
              ),

              const SizedBox(height: 16),

              // Done Action Button
              ElevatedButton.icon(
                onPressed: _onDoneTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
