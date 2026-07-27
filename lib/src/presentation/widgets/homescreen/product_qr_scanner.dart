import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

Future<void> showProductQrScanner(
  BuildContext context,
  HomeController controller, {
  VoidCallback? onProductAdded,
}) async {
  final result = await Navigator.of(context).push<QrAddResult>(
    MaterialPageRoute(
      builder: (_) => _ProductQrScannerScreen(controller: controller),
    ),
  );
  if (!context.mounted || result == null) return;

  if (result.isSuccess) {
    onProductAdded?.call();
    final item = result.item!;
    AppToast.show(
      context,
      '${item.product.name} (${item.displayUnit}) added to the bill.',
    );
  }
}

class _ProductQrScannerScreen extends StatefulWidget {
  const _ProductQrScannerScreen({required this.controller});

  final HomeController controller;

  @override
  State<_ProductQrScannerScreen> createState() =>
      _ProductQrScannerScreenState();
}

class _ProductQrScannerScreenState extends State<_ProductQrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _handlingCode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingCode) return;
    String? value;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        value = barcode.rawValue;
        break;
      }
    }
    if (value == null) return;

    _handlingCode = true;
    final result = widget.controller.addProductFromQr(value);
    if (result.isSuccess) {
      await _scannerController.stop();
      if (mounted) Navigator.of(context).pop(result);
      return;
    }

    if (mounted) setState(() => _error = result.error);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _handlingCode = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Scan Product QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            onPressed: _scannerController.toggleTorch,
            icon: const Icon(Icons.flash_on_rounded),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: _scannerController.switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Place the 9-digit product QR inside the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
