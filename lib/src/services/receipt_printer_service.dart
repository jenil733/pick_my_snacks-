import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

enum ReceiptPaperSize { mm58, mm80 }

class ReceiptPrinterException implements Exception {
  const ReceiptPrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ThermalPrinterDevice {
  const ThermalPrinterDevice({required this.name, required this.address});

  final String name;
  final String address;
}

class ReceiptPrinterService {
  static const _statusTimeout = Duration(seconds: 3);
  static const _connectionTimeout = Duration(seconds: 15);
  static const _printTimeout = Duration(seconds: 20);

  Future<bool> get isConnected async {
    try {
      return await PrintBluetoothThermal.connectionStatus.timeout(
        _statusTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> get isBluetoothPermissionGranted async {
    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted.timeout(
        _statusTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> get isBluetoothEnabled async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled.timeout(
        _statusTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestBluetoothPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return (await Permission.bluetooth.request()).isGranted;
    }

    return isBluetoothPermissionGranted;
  }

  Future<bool> openPermissionSettings() => openAppSettings();

  Future<List<ThermalPrinterDevice>> get pairedPrinters async {
    final printers = await PrintBluetoothThermal.pairedBluetooths.timeout(
      const Duration(seconds: 8),
      onTimeout: () => const [],
    );
    return printers
        .map(
          (printer) => ThermalPrinterDevice(
            name: printer.name.trim().isEmpty
                ? 'Unnamed printer'
                : printer.name.trim(),
            address: printer.macAdress,
          ),
        )
        .toList();
  }

  Future<bool> connect(ThermalPrinterDevice printer) async {
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: printer.address,
    ).timeout(_connectionTimeout, onTimeout: () => false);
    if (!connected) return false;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    return isConnected;
  }

  Future<void> printBluetoothReceipt({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    required String orderNumber,
    required ReceiptPaperSize paperSize,
  }) async {
    if (!await isConnected) {
      throw const ReceiptPrinterException('The printer is not connected.');
    }

    final bytes = await buildReceiptBytes(
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      orderNumber: orderNumber,
      paperSize: paperSize,
    );
    final printed = await PrintBluetoothThermal.writeBytes(
      bytes,
    ).timeout(_printTimeout, onTimeout: () => false);
    if (!printed) {
      throw const ReceiptPrinterException(
        'The printer did not accept the receipt. Please reconnect and retry.',
      );
    }
  }

  Future<List<int>> buildReceiptBytes({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    required String orderNumber,
    required ReceiptPaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final printerPaperSize = paperSize == ReceiptPaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final generator = Generator(printerPaperSize, profile);
    final tableGenerator = Generator(
      printerPaperSize,
      profile,
      spaceBetweenRows: 0,
    );
    final charactersPerLine = paperSize == ReceiptPaperSize.mm58 ? 32 : 48;
    final now = DateTime.now();
    final date =
        '${_twoDigits(now.month)}/${_twoDigits(now.day)}/${now.year} '
        '${_twelveHour(now.hour)}:${_twoDigits(now.minute)} '
        '${now.hour >= 12 ? 'PM' : 'AM'}';
    final logo = await _receiptLogo(paperSize);
    final itemCount = items.fold(0, (sum, item) => sum + item.quantity);
    const receiptStyle = PosStyles(fontType: PosFontType.fontA, bold: true);
    const boldReceiptStyle = PosStyles(fontType: PosFontType.fontA, bold: true);
    const tableStyle = PosStyles(fontType: PosFontType.fontA, bold: true);
    const compactProductNameStyle = PosStyles(
      fontType: PosFontType.fontB,
      bold: true,
    );
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.imageRaster(logo, align: PosAlign.center));
    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        'Vettturnimadam, Nagercoil',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
          bold: true,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        '- 629001  CELL: 7339595793',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        'Order No: $orderNumber   ORIGINAL',
        styles: boldReceiptStyle,
      ),
    );
    bytes.addAll(generator.text('Date $date', styles: receiptStyle));
    bytes.addAll(generator.hr());
    bytes.addAll(
      tableGenerator.row(
        _itemTableColumns(
          productName: 'Item',
          rate: 'Rate',
          unit: 'Unit',
          quantity: 'Qty',
          amount: 'Amount',
          productNameStyle: tableStyle,
          isHeader: true,
        ),
        multiLine: false,
      ),
    );
    bytes.addAll(generator.hr());

    for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
      if (itemIndex > 0) {
        // Use the same small gap between every pair of products.
        bytes.addAll(generator.rawBytes(const [27, 74, 12]));
      }
      // Explicitly enable bold for every product, including the first one.
      bytes.addAll(generator.rawBytes(const [27, 69, 1]));
      final item = items[itemIndex];
      final productName = item.product.name.toUpperCase();
      final productUnit = item.displayUnit.trim().toUpperCase();
      final wrappedProductName = _wrapParticulars(
        productName,
        paperSize: paperSize,
      );
      final useCompactProductName = wrappedProductName.length >= 3;
      final compactNameWidth = paperSize == ReceiptPaperSize.mm58 ? 6 : 20;
      final productNameLines = useCompactProductName
          ? _chunkText(productName, compactNameWidth).take(2).toList()
          : wrappedProductName.take(2).toList();
      final productNameStyle = useCompactProductName
          ? compactProductNameStyle
          : tableStyle;

      for (var index = 0; index < productNameLines.length; index++) {
        final isFirstLine = index == 0;
        bytes.addAll(
          tableGenerator.row(
            _itemTableColumns(
              productName: productNameLines[index],
              quantity: isFirstLine ? '${item.quantity}' : '',
              rate: isFirstLine ? _amount(item.product.price) : '',
              unit: isFirstLine ? productUnit : '',
              amount: isFirstLine ? _amount(item.total) : '',
              productNameStyle: productNameStyle,
            ),
            multiLine: false,
          ),
        );
      }
    }

    bytes.addAll(generator.hr(ch: '='));
    bytes.addAll(
      generator.text(
        _twoColumns('Total Items:', '$itemCount', charactersPerLine),
        styles: boldReceiptStyle,
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        _moneyLine('Subtotal', subtotal, charactersPerLine),
        styles: receiptStyle,
      ),
    );
    bytes.addAll(
      generator.text(
        _moneyLine('GST', tax, charactersPerLine),
        styles: receiptStyle,
      ),
    );
    bytes.addAll(
      generator.text(
        _moneyLine('Grand Total', total, charactersPerLine),
        styles: const PosStyles(fontType: PosFontType.fontA, bold: true),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        'THANK YOU VISIT AGAIN',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.feed(3));
    return bytes;
  }

  Future<img.Image> _receiptLogo(ReceiptPaperSize paperSize) async {
    final logoData = await rootBundle.load('assets/images/app_icon.png');
    final decodedLogo = img.decodeImage(logoData.buffer.asUint8List());
    if (decodedLogo == null) {
      throw const ReceiptPrinterException('Unable to prepare receipt logo.');
    }

    final croppedLogo = img.trim(decodedLogo, mode: img.TrimMode.topLeftColor);
    final resizedLogo = img.copyResize(
      croppedLogo,
      width: paperSize == ReceiptPaperSize.mm58 ? 240 : 320,
      interpolation: img.Interpolation.linear,
    );

    // Match the legacy receipt logo: the dark outline prints in black while
    // the yellow lettering and white background remain unprinted.
    return img.luminanceThreshold(resizedLogo, threshold: .50);
  }

  String _twoColumns(String left, String right, int width) {
    final safeRight = right.length > width ? right.substring(0, width) : right;
    final leftWidth = width - safeRight.length - 1;
    if (leftWidth <= 0) return safeRight;

    final safeLeft = left.length > leftWidth
        ? left.substring(0, leftWidth)
        : left;
    return '${safeLeft.padRight(width - safeRight.length)}$safeRight';
  }

  String _moneyLine(String label, double value, int width) {
    final amountWidth = width == 32 ? 10 : 12;
    const currency = 'Rs.';
    final labelWidth = width - currency.length - amountWidth;
    return '${_fitLeft(label, labelWidth)}'
        '$currency'
        '${_fitRight(_amount(value), amountWidth)}';
  }

  List<PosColumn> _itemTableColumns({
    required String productName,
    required String rate,
    required String unit,
    required String quantity,
    required String amount,
    required PosStyles productNameStyle,
    bool isHeader = false,
  }) {
    const valueStyle = PosStyles(
      fontType: PosFontType.fontA,
      bold: true,
      align: PosAlign.right,
    );
    return [
      PosColumn(text: productName, width: 2, styles: productNameStyle),
      PosColumn(text: rate, width: 3, styles: valueStyle),
      PosColumn(
        text: unit,
        width: 3,
        styles: const PosStyles(
          fontType: PosFontType.fontA,
          bold: true,
          align: PosAlign.center,
        ),
      ),
      PosColumn(
        text: quantity,
        width: 1,
        styles: isHeader
            ? const PosStyles(
                fontType: PosFontType.fontB,
                bold: true,
                align: PosAlign.center,
              )
            : valueStyle,
      ),
      PosColumn(text: amount, width: 3, styles: valueStyle),
    ];
  }

  List<String> _wrapParticulars(
    String text, {
    required ReceiptPaperSize paperSize,
  }) {
    final width = paperSize == ReceiptPaperSize.mm58 ? 5 : 15;
    return _wrapText(text, width);
  }

  List<String> _wrapText(String text, int width) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var line = '';

    for (final word in words) {
      if (word.length > width) {
        if (line.isNotEmpty) {
          lines.add(line);
          line = '';
        }
        for (var start = 0; start < word.length; start += width) {
          final end = start + width < word.length ? start + width : word.length;
          lines.add(word.substring(start, end));
        }
        continue;
      }

      final candidate = line.isEmpty ? word : '$line $word';
      if (candidate.length <= width) {
        line = candidate;
      } else {
        lines.add(line);
        line = word;
      }
    }

    if (line.isNotEmpty) lines.add(line);
    return lines.isEmpty ? [''] : lines;
  }

  List<String> _chunkText(String text, int width) {
    final lines = <String>[];
    for (var start = 0; start < text.length; start += width) {
      final end = start + width < text.length ? start + width : text.length;
      lines.add(text.substring(start, end));
    }
    return lines.isEmpty ? [''] : lines;
  }

  String _amount(double value) => value.toStringAsFixed(2);

  String _fitLeft(String value, int width) {
    final fitted = _clip(value, width);
    return fitted.padRight(width);
  }

  String _fitRight(String value, int width) {
    final fitted = _clip(value, width);
    return fitted.padLeft(width);
  }

  String _clip(String value, int width) {
    if (value.length <= width) return value;
    return value.substring(0, width);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _twelveHour(int hour) {
    final value = hour % 12;
    return _twoDigits(value == 0 ? 12 : value);
  }
}
