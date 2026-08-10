import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'ai_provider_orchestrator.dart';

class OcrItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double discount;

  OcrItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
  });

  factory OcrItem.fromJson(Map<String, dynamic> json) {
    return OcrItem(
      name: json['name'] as String? ?? json['item_name'] as String? ?? 'Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num? ?? json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }
}

class OcrResult {
  final String merchant;
  final String? merchantAddress;
  final String date;
  final String? time;
  final double amount;
  final double tax;
  final String currency;
  final String paymentMethod;
  final String? cardType;
  final String? last4Digits;
  final String? receiptNumber;
  final String? invoiceNumber;
  final double discount;
  final double tips;
  final String category;
  final String? accountSuggestion;
  final double confidence;
  final List<OcrItem> items;

  OcrResult({
    required this.merchant,
    this.merchantAddress,
    required this.date,
    this.time,
    required this.amount,
    required this.tax,
    required this.currency,
    required this.paymentMethod,
    this.cardType,
    this.last4Digits,
    this.receiptNumber,
    this.invoiceNumber,
    required this.discount,
    required this.tips,
    required this.category,
    this.accountSuggestion,
    required this.confidence,
    required this.items,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List?;
    List<OcrItem> parsedItems = [];
    if (rawItems != null) {
      try {
        parsedItems = rawItems.map((i) => OcrItem.fromJson(i as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('OcrResult: failed parsing items list: $e');
      }
    }
    
    return OcrResult(
      merchant: json['merchant'] as String? ?? json['merchant_name'] as String? ?? 'Scanned Store',
      merchantAddress: json['merchantAddress'] as String? ?? json['merchant_address'] as String?,
      date: json['date'] as String? ?? 'today',
      time: json['time'] as String?,
      amount: (json['amount'] as num? ?? json['total_amount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      paymentMethod: json['paymentMethod'] as String? ?? json['payment_method'] as String? ?? 'Cash',
      cardType: json['cardType'] as String? ?? json['card_type'] as String?,
      last4Digits: json['last4Digits']?.toString() ?? json['last_4_digits']?.toString(),
      receiptNumber: json['receiptNumber']?.toString() ?? json['receipt_number']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString() ?? json['invoice_number']?.toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tips: (json['tips'] as num? ?? json['tip'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Shopping',
      accountSuggestion: json['accountSuggestion'] as String? ?? json['account_suggestion'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'merchantAddress': merchantAddress,
      'date': date,
      'time': time,
      'amount': amount,
      'tax': tax,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'cardType': cardType,
      'last4Digits': last4Digits,
      'receiptNumber': receiptNumber,
      'invoiceNumber': invoiceNumber,
      'discount': discount,
      'tips': tips,
      'category': category,
      'accountSuggestion': accountSuggestion,
      'confidence': confidence,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class OcrService {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  OcrService(this._ref);

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source, imageQuality: 80);
    } catch (e) {
      debugPrint('OcrService pickImage error: $e');
      return null;
    }
  }

  Future<OcrResult?> scanReceipt(File file, {void Function(String)? onStatusChanged}) async {
    onStatusChanged?.call('Preparing Image...');
    
    // Check file exists
    if (!await file.exists()) {
      throw Exception('Receipt file does not exist.');
    }
    
    // Check size limit (e.g. 10MB)
    final size = await file.length();
    if (size > 10 * 1024 * 1024) {
      throw Exception('Receipt image is too large (>10MB).');
    }

    OcrResult? result;

    // 1. Try On-Device ML Kit recognition first (offline/basic fallback)
    try {
      onStatusChanged?.call('Analyzing Receipt...');
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final fullText = recognizedText.text;
      
      // Parse local text
      final localResult = _parseRecognizedText(fullText);
      if (localResult != null && localResult.amount > 0) {
        result = localResult;
      }
    } catch (e, stack) {
      debugPrint('On-device ML Kit failed or unsupported: $e\n$stack');
    }

    if (result != null) {
      onStatusChanged?.call('Matching Categories...');
      return result;
    }

    // 2. Try Backend AI OCR endpoint
    onStatusChanged?.call('Uploading...');
    try {
      final client = _ref.read(dioClientProvider);
      final fileName = file.path.split(Platform.pathSeparator).last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await client.dio.post(
        '/ai/ocr',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        onStatusChanged?.call('Extracting Details...');
        final parsed = OcrResult.fromJson(response.data);
        onStatusChanged?.call('Matching Categories...');
        return parsed;
      }
    } catch (e) {
      debugPrint('Backend OCR failed: $e. Attempting direct client-side AI fallback...');
    }

    // 3. Fallback to direct client-side AI scan using active/configured API keys
    onStatusChanged?.call('Analyzing Receipt...');
    final orchestrator = _ref.read(aiProviderOrchestratorProvider.notifier);
    final config = _ref.read(aiProviderOrchestratorProvider);
    
    final activeProv = config.aiProvider;
    final activeKey = orchestrator.getActiveKeyForProvider(activeProv);
    
    if (activeKey != null && activeKey.key.trim().isNotEmpty && (activeProv == 'gemini' || activeProv == 'openai' || activeProv == 'claude')) {
      try {
        final activeModel = config.selectedModels[activeProv] ?? _getDefaultModelForProvider(activeProv);
        result = await _scanDirectlyWithClientAI(file, activeProv, activeKey.key, activeModel);
        if (result != null) {
          onStatusChanged?.call('Extracting Details...');
          onStatusChanged?.call('Matching Categories...');
          return result;
        }
      } catch (e) {
        debugPrint('Active provider client-side AI scan failed: $e. Trying other configured fallback keys...');
      }
    }

    // Fallback chain
    final visionProviders = ['gemini', 'openai', 'claude'];
    for (var prov in visionProviders) {
      if (prov == activeProv) continue;
      
      final key = orchestrator.getActiveKeyForProvider(prov);
      if (key != null && key.key.trim().isNotEmpty) {
        try {
          final model = config.selectedModels[prov] ?? _getDefaultModelForProvider(prov);
          result = await _scanDirectlyWithClientAI(file, prov, key.key, model);
          if (result != null) {
            await orchestrator.setAiProvider(prov);
            onStatusChanged?.call('Extracting Details...');
            onStatusChanged?.call('Matching Categories...');
            return result;
          }
        } catch (e) {
          debugPrint('Fallback provider $prov client-side AI scan failed: $e');
        }
      }
    }

    throw Exception('All receipt scanning methods failed. Please check network connectivity or your AI Settings API keys.');
  }

  String _getDefaultModelForProvider(String provider) {
    if (provider == 'gemini') return 'gemini-2.5-flash';
    if (provider == 'openai') return 'gpt-4o-mini';
    if (provider == 'claude') return 'claude-3-5-sonnet-20241022';
    return '';
  }

  Future<OcrResult?> _scanDirectlyWithClientAI(
    File file,
    String provider,
    String key,
    String model,
  ) async {
    final imageBytes = await file.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final mimeType = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    final prompt = """
    Analyze this receipt image and extract the following details in JSON format conforming exactly to this structure:
    {
      "merchant": "Merchant Name",
      "merchantAddress": "Merchant Address (or null)",
      "date": "YYYY-MM-DD (format: YYYY-MM-DD. If not found, use today)",
      "time": "HH:MM (format: HH:MM, or null)",
      "amount": 120.50 (total transaction amount as a float),
      "tax": 10.50 (tax amount as a float, or 0.0),
      "currency": "INR" (or USD, EUR, etc. default: INR),
      "paymentMethod": "UPI" (UPI, Credit Card, Debit Card, Cash, or Net Banking),
      "cardType": "Visa" (Visa, Mastercard, Rupay, Amex, etc. or null),
      "last4Digits": "1234" (or null),
      "receiptNumber": "12345" (or null),
      "invoiceNumber": "INV-12345" (or null),
      "discount": 5.00 (discount amount as a float, or 0.0),
      "tips": 2.00 (tips/tip amount as a float, or 0.0),
      "category": "Grocery" (Food, Fuel, Grocery, Utilities, Shopping, Entertainment, Salary, Freelance, Investment, Transfer, Travel, Healthcare, Education, Bills, Other),
      "accountSuggestion": "HDFC Bank" (specific bank or credit card name if visible on the receipt),
      "confidence": 0.95 (confidence rating as a float between 0.0 and 1.0),
      "items": [
        {
          "name": "Item name",
          "quantity": 2,
          "unitPrice": 50.00,
          "discount": 0.00
        }
      ]
    }
    """;

    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);

    if (provider == 'gemini') {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key';
      final response = await dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          final jsonMap = jsonDecode(text.trim());
          return OcrResult.fromJson(jsonMap);
        }
      }
    } else if (provider == 'openai') {
      final response = await dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                  }
                }
              ]
            }
          ],
          'response_format': {'type': 'json_object'},
        },
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          final text = choices[0]['message']['content'] as String;
          final jsonMap = jsonDecode(text.trim());
          return OcrResult.fromJson(jsonMap);
        }
      }
    } else if (provider == 'claude') {
      final response = await dio.post(
        'https://api.anthropic.com/v1/messages',
        options: Options(headers: {
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mimeType,
                    'data': base64Image,
                  }
                },
                {'type': 'text', 'text': prompt}
              ]
            }
          ],
          'max_tokens': 1024,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as List;
        if (content.isNotEmpty) {
          final text = content[0]['text'] as String;
          final jsonMap = jsonDecode(text.trim());
          return OcrResult.fromJson(jsonMap);
        }
      }
    }
    
    throw Exception('Unsupported AI provider or empty response.');
  }

  OcrResult? _parseRecognizedText(String text) {
    if (text.trim().isEmpty) return null;

    final lines = text.split('\n');
    double amount = 0.0;
    String merchant = 'Walmart Store';
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. First non-numerical line is likely the merchant
    for (var line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.length > 3 && !cleanLine.contains(RegExp(r'\d'))) {
        merchant = cleanLine;
        break;
      }
    }

    // 2. Match amounts using regex
    final totalRegex = RegExp(r'(total|amt|due|net|paid|sum)[\s:]*([\$₹€]*\s*\d+[\.,]\d{2})', caseSensitive: false);
    for (var line in lines) {
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        final amountString = match.group(2)?.replaceAll(RegExp(r'[^\d\.]'), '') ?? '';
        final parsedAmount = double.tryParse(amountString);
        if (parsedAmount != null && parsedAmount > amount) {
          amount = parsedAmount;
        }
      }
    }

    // 3. Match dates
    final dateRegex = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})');
    for (var line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        date = match.group(0) ?? date;
        break;
      }
    }

    return OcrResult(
      merchant: merchant,
      amount: amount,
      category: 'Grocery',
      date: date,
      confidence: 0.85,
      items: [],
      tax: 0.0,
      currency: 'INR',
      paymentMethod: 'Cash',
      discount: 0.0,
      tips: 0.0,
    );
  }
}

final Provider<OcrService> ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(ref);
});
