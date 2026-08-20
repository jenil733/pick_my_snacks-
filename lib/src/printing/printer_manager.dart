import 'dart:async';

import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_repository.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

class PrinterManagerException implements Exception {
  const PrinterManagerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptPrintJob {
  const ReceiptPrintJob({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.charge,
    required this.total,
    required this.paymentMethod,
    required this.orderNumber,
    this.paperSize = ReceiptPaperSize.mm58,
    this.showRate = true,
    this.customerName,
    this.customerPhone,
  });

  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double charge;
  final double total;
  final String paymentMethod;
  final String orderNumber;
  final ReceiptPaperSize paperSize;
  final bool showRate;
  final String? customerName;
  final String? customerPhone;
}

class DuplicatePrintJob {
  const DuplicatePrintJob({
    required this.items,
    required this.orderNumber,
    this.paperSize = ReceiptPaperSize.mm58,
    this.staffName,
  });

  final List<CartItem> items;
  final String orderNumber;
  final ReceiptPaperSize paperSize;
  final String? staffName;
}

class PrinterManager {
  PrinterManager(this._repository, this._printerService, this._kitchenPrinter);

  final PrinterRepository _repository;
  final ReceiptPrinterService _printerService;
  final KitchenPrinter _kitchenPrinter;
  bool _isPrinting = false;

  PrinterSettingsModel? printerFor(PrinterRole role) {
    return _repository.getPrinter(role);
  }

  Future<List<PrinterSettingsModel>> scanPrinters() async {
    await _ensureBluetoothAvailable();
    final devices = await _printerService.pairedPrinters;
    return devices
        .map(
          (device) => PrinterSettingsModel(
            name: device.name,
            address: device.address,
            connectionType: PrinterConnectionType.bluetooth,
          ),
        )
        .toList();
  }

  Future<void> assignPrinter(PrinterRole role, PrinterSettingsModel printer) {
    return _repository.savePrinter(role, printer);
  }

  Future<void> printReceipt(ReceiptPrintJob job) {
    return _withPrinter(PrinterRole.billing, () {
      return _printerService.printBluetoothReceipt(
        items: job.items,
        subtotal: job.subtotal,
        tax: job.tax,
        discount: job.discount,
        charge: job.charge,
        total: job.total,
        paymentMethod: job.paymentMethod,
        orderNumber: job.orderNumber,
        paperSize: job.paperSize,
        showRate: job.showRate,
        customerName: job.customerName,
        customerPhone: job.customerPhone,
      );
    });
  }

  Future<void> printTakeAwayReceipt(ReceiptPrintJob job) {
    return _withPrinter(PrinterRole.takeAway, () {
      return _printerService.printBluetoothReceipt(
        items: job.items,
        subtotal: job.subtotal,
        tax: job.tax,
        discount: job.discount,
        charge: job.charge,
        total: job.total,
        paymentMethod: job.paymentMethod,
        orderNumber: job.orderNumber,
        paperSize: job.paperSize,
        showRate: job.showRate,
        showAmount: false,
        showTotals: false,
        separateProducts: true,
        endFeedLines: 5,
        customerName: job.customerName,
        customerPhone: job.customerPhone,
      );
    });
  }

  Future<void> printKitchen(KitchenPrintJob job) {
    return _withPrinter(PrinterRole.kitchen, () async {
      final bytes = await _kitchenPrinter.buildTicket(job);
      await _printerService.writeBytes(bytes, documentName: 'kitchen order');
    });
  }

  Future<void> printDuplicate(DuplicatePrintJob job) {
    return _withPrinter(PrinterRole.billing, () async {
      final bytes = await _printerService.buildDuplicateBillBytes(
        items: job.items,
        orderNumber: job.orderNumber,
        paperSize: job.paperSize,
        staffName: job.staffName,
      );
      await _printerService.writeBytes(bytes, documentName: 'duplicate bill');
    });
  }

  Future<void> testPrint(PrinterRole role) {
    return _withPrinter(role, () async {
      final bytes = await _kitchenPrinter.buildTestTicket(
        roleLabel: role.label,
        paperSize: ReceiptPaperSize.mm58,
      );
      await _printerService.writeBytes(bytes, documentName: 'test print');
    });
  }

  Future<void> _withPrinter(
    PrinterRole role,
    Future<void> Function() print,
  ) async {
    if (_isPrinting) {
      throw const PrinterManagerException(
        'Another print is in progress. Please wait and retry.',
      );
    }
    final selected = _repository.getPrinter(role);
    if (selected == null) {
      throw PrinterManagerException(
        'No ${role.label.toLowerCase()} is selected. Open Printer Settings.',
      );
    }
    if (selected.connectionType != PrinterConnectionType.bluetooth) {
      throw const PrinterManagerException(
        'Wi-Fi printing is not available in this version.',
      );
    }

    _isPrinting = true;
    try {
      await _ensureBluetoothAvailable();
      await _printerService.disconnect();
      final connected = await _printerService.connect(
        ThermalPrinterDevice(name: selected.name, address: selected.address),
      );
      if (!connected) {
        throw PrinterManagerException(
          '${role.label} is unavailable. Check that it is on and retry.',
        );
      }
      await print();
    } on PrinterManagerException {
      rethrow;
    } on ReceiptPrinterException catch (error) {
      throw PrinterManagerException(error.message);
    } on TimeoutException {
      throw PrinterManagerException(
        '${role.label} connection timed out. Please retry.',
      );
    } catch (_) {
      throw PrinterManagerException(
        'Could not print to ${role.label.toLowerCase()}. Please retry.',
      );
    } finally {
      await _printerService.disconnect();
      _isPrinting = false;
    }
  }

  Future<void> _ensureBluetoothAvailable() async {
    var hasPermission = await _printerService.isBluetoothPermissionGranted;
    if (!hasPermission) {
      hasPermission = await _printerService.requestBluetoothPermission();
    }
    if (!hasPermission) {
      throw const PrinterManagerException(
        'Nearby devices permission is required for Bluetooth printing.',
      );
    }
    if (!await _printerService.isBluetoothEnabled) {
      throw const PrinterManagerException('Turn on Bluetooth, then retry.');
    }
  }
}
