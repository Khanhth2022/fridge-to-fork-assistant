import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScannerService {
  ScannerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<ScannerResult?> scanReceiptFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(photo.path);
    final recognizedText = await _extractText(inputImage);
    final barcodes = await _extractBarcodes(inputImage);
    final ingredients = _extractIngredientCandidates(recognizedText.text);

    return ScannerResult(
      imagePath: photo.path,
      recognizedText: recognizedText.text,
      ingredients: ingredients,
      barcodes: barcodes,
    );
  }

  Future<RecognizedText> _extractText(InputImage inputImage) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await recognizer.processImage(inputImage);
    } finally {
      await recognizer.close();
    }
  }

  Future<List<String>> _extractBarcodes(InputImage inputImage) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    try {
      final barcodes = await scanner.processImage(inputImage);
      return barcodes
          .map((code) => code.rawValue)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList();
    } finally {
      await scanner.close();
    }
  }

  List<String> _extractIngredientCandidates(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    const blockedKeywords = <String>{
      'tong',
      'tien',
      'thue',
      'giam gia',
      'subtotal',
      'total',
      'cash',
      'visa',
      'master',
    };

    final candidates = <String>[];
    for (final line in lines) {
      final normalized = line.toLowerCase();
      final hasBlockedKeyword = blockedKeywords.any(normalized.contains);
      final hasPricePattern = RegExp(r'\d+[\.,]\d{3}').hasMatch(normalized);
      final looksLikeCode = RegExp(r'^[0-9\-\/]{5,}$').hasMatch(normalized);

      if (hasBlockedKeyword || hasPricePattern || looksLikeCode) {
        continue;
      }

      final cleaned = normalized
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleaned.length < 3) {
        continue;
      }
      candidates.add(_toTitleCase(cleaned));
    }

    return candidates.toSet().toList();
  }

  String _toTitleCase(String value) {
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  Future<File?> getCapturedImage(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    return file;
  }
}

class ScannerResult {
  const ScannerResult({
    required this.imagePath,
    required this.recognizedText,
    required this.ingredients,
    required this.barcodes,
  });

  final String imagePath;
  final String recognizedText;
  final List<String> ingredients;
  final List<String> barcodes;
}
