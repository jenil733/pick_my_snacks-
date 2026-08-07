import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pick_my_snacks/src/core/const/appcolors.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class ExternalQrScannerButton extends StatefulWidget {
  const ExternalQrScannerButton({
    required this.controller,
    this.onProductAdded,
    this.showLabel = false,
    super.key,
  });

  final HomeController controller;
  final VoidCallback? onProductAdded;
  final bool showLabel;

  @override
  State<ExternalQrScannerButton> createState() =>
      _ExternalQrScannerButtonState();
}

class _ExternalQrScannerButtonState extends State<ExternalQrScannerButton> {
  static const _scannerKeyGap = Duration(milliseconds: 250);

  bool _enabled = false;
  String _buffer = '';
  DateTime? _lastKeyAt;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleScannerKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleScannerKey);
    super.dispose();
  }

  bool _handleScannerKey(KeyEvent event) {
    if (!_enabled || event is! KeyDownEvent || !mounted) return false;

    final character = _scannerCharacter(event);
    if (character != null) {
      final now = DateTime.now();
      final previousKeyAt = _lastKeyAt;
      if (previousKeyAt == null ||
          now.difference(previousKeyAt) > _scannerKeyGap) {
        _buffer = '';
      }
      _lastKeyAt = now;
      _buffer += character;

      if (RegExp(r'^\d{9}$').hasMatch(_buffer)) {
        _processCode(_buffer);
        _resetBuffer();
      }
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_buffer.isNotEmpty) _processCode(_buffer);
      _resetBuffer();
    }
    return false;
  }

  String? _scannerCharacter(KeyEvent event) {
    final character = event.character;
    if (character != null &&
        character.length == 1 &&
        character.codeUnitAt(0) >= 32) {
      return character;
    }
    return null;
  }

  void _processCode(String code) {
    setState(() => _enabled = false);
    widget.controller.searchController.clear();
    widget.controller.searchQuery.value = '';

    final result = widget.controller.addProductFromQr(code);
    if (!mounted) return;
    if (!result.isSuccess) {
      AppToast.error(context, result.error ?? 'Unable to read the QR code.');
      return;
    }

    widget.onProductAdded?.call();
    final item = result.item!;
    AppToast.show(
      context,
      '${item.product.name} (${item.displayUnit}) added to the bill.',
    );
  }

  void _resetBuffer() {
    _buffer = '';
    _lastKeyAt = null;
  }

  void _toggle() {
    setState(() => _enabled = !_enabled);
    _resetBuffer();
    if (_enabled) {
      AppToast.show(
        context,
        'Scanner ready. Scan a 9-digit weight code or product QR.',
      );
    } else {
      AppToast.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _enabled ? AppColors.navy : Colors.white;
    final backgroundColor = _enabled
        ? AppColors.yellow
        : Colors.white.withValues(alpha: .12);
    final side = BorderSide(color: _enabled ? AppColors.yellow : Colors.white);
    final tooltip = _enabled
        ? 'Cancel external scanner'
        : 'Activate external scanner';

    if (widget.showLabel) {
      return Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: _toggle,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 21),
          label: const Text('Scanner'),
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            side: side,
          ),
        ),
      );
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: _toggle,
      style: IconButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: side,
      ),
      icon: const Icon(Icons.qr_code_scanner_rounded),
    );
  }
}
