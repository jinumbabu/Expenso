import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

class OcrResult {
  final String merchant;
  final double amount;
  final String category;
  final String date;
  final double confidence;

  OcrResult({
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    required this.confidence,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      merchant: json['merchant'] as String? ?? 'Scanned Store',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Shopping',
      date: json['date'] as String? ?? 'today',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
    );
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
      return null;
    }
  }

  Future<OcrResult?> scanReceipt(File file) async {
    try {
      // 1. Perform On-Device Text Recognition using Google ML Kit
      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final fullText = recognizedText.text;
      
      // Parse local text
      final localResult = _parseRecognizedText(fullText);
      if (localResult != null && localResult.amount > 0) {
        return localResult;
      }
      
      // 2. Fallback to API scanning
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
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return OcrResult.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('OcrService: Receipt scanning failed: $e');
      rethrow;
    }
    return null;
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

    // 2. Match amounts using regex (e.g. Total: ₹540.00 or Total: 450)
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
    );
  }
}

final Provider<OcrService> ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(ref);
});
