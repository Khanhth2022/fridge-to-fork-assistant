import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/scanner/scanner_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_indicator.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key, this.onApplyIngredients});

  final Future<void> Function(List<String> ingredients)? onApplyIngredients;

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  bool _isScanning = false;
  String? _error;
  ScannerResult? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 14),
          if (_isScanning)
            const Card(
              child: LoadingIndicator(message: 'Đang xử lý OCR và barcode...'),
            ),
          if (_error != null) ...[
            Card(
              color: AppColors.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_result != null) ...[
            _buildPreviewImage(),
            const SizedBox(height: 12),
            _buildIngredientCard(),
            const SizedBox(height: 12),
            _buildBarcodeCard(),
            const SizedBox(height: 12),
            _buildRawTextCard(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              label: _isScanning ? 'Đang quét...' : 'Chụp ảnh hóa đơn',
              icon: Icons.camera_alt_outlined,
              isLoading: _isScanning,
              onPressed: _isScanning ? null : _scanReceipt,
            ),
            const SizedBox(height: 8),
            CustomButton(
              label: 'Đẩy nguyên liệu vào kho',
              icon: Icons.inventory_2_outlined,
              type: CustomButtonType.secondary,
              onPressed: (_result == null || _result!.ingredients.isEmpty)
                  ? null
                  : _applyToPantry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quét OCR + Barcode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bước 1: Chụp ảnh hóa đơn\n'
              'Bước 2: Trích xuất text và barcode\n'
              'Bước 3: Chọn đẩy dữ liệu sang module Kho',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewImage() {
    return FutureBuilder<File?>(
      future: context.read<ScannerService>().getCapturedImage(
        _result!.imagePath,
      ),
      builder: (context, snapshot) {
        final File? file = snapshot.data;
        if (file == null) {
          return const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, height: 210, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildIngredientCard() {
    final List<String> ingredients = _result!.ingredients;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nguyên liệu gợi ý',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (ingredients.isEmpty)
              const Text('Không tìm thấy nguyên liệu rõ ràng từ hóa đơn.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .map(
                      (String item) => Chip(
                        label: Text(item),
                        avatar: const Icon(Icons.restaurant_menu, size: 16),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeCard() {
    final List<String> barcodes = _result!.barcodes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barcode tìm thấy',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (barcodes.isEmpty)
              const Text('Chưa phát hiện barcode.')
            else
              ...barcodes.map(
                (String code) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('- $code'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raw OCR Text',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(_result!.recognizedText),
          ],
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final ScannerService scanner = context.read<ScannerService>();
      final ScannerResult? result = await scanner.scanReceiptFromCamera();

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Không thể quét hóa đơn: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _applyToPantry() async {
    final List<String> ingredients = _result?.ingredients ?? <String>[];
    if (ingredients.isEmpty) {
      return;
    }

    if (widget.onApplyIngredients != null) {
      await widget.onApplyIngredients!(ingredients);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã đẩy ${ingredients.length} nguyên liệu sang module kho.',
        ),
      ),
    );
  }
}
