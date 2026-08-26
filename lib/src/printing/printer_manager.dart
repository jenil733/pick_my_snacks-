import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

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
    this.staffName,
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
  final String? staffName;
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
  Future<void>? _currentPrintJob;

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

  Future<void> printReceipt(ReceiptPrintJob job) async {
    if (kDebugMode) {
      _logReceipt('BILLING', job);
      return;
    }
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
        staffName: job.staffName,
        customerName: job.customerName,
        customerPhone: job.customerPhone,
      );
    });
  }

  Future<void> printTakeAwayReceipt(ReceiptPrintJob job) async {
    if (kDebugMode) {
      _logReceipt('TAKE-AWAY', job);
      return;
    }
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
        showAmount: true,
        showTotals: true,
        separateProducts: false,
        endFeedLines: 3,
        staffName: job.staffName,
        customerName: job.customerName,
        customerPhone: job.customerPhone,
      );
    });
  }

  Future<void> printKitchen(KitchenPrintJob job) async {
    if (kDebugMode) {
      _logKitchen(job);
      return;
    }
    return _withPrinter(PrinterRole.kitchen, () async {
      final bytes = await _kitchenPrinter.buildTicket(job);
      await _printerService.writeBytes(bytes, documentName: 'kitchen order');
    });
  }

  Future<void> printDuplicate(DuplicatePrintJob job) async {
    if (kDebugMode) {
      _logDuplicate(job);
      return;
    }
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

  Future<void> testPrint(PrinterRole role) async {
    if (kDebugMode) {
      log('========================================');
      log('           ${role.label} TEST               ');
      log('========================================');
      log('Printer configured successfully');
      log('========================================');
      return;
    }
    return _withPrinter(role, () async {
      final bytes = await _kitchenPrinter.buildTestTicket(
        roleLabel: role.label,
        paperSize: ReceiptPaperSize.mm58,
      );
      await _printerService.writeBytes(bytes, documentName: 'test print');
    });
  }


  void _logReceipt(String title, ReceiptPrintJob job) {
    final b = StringBuffer();
    b.writeln('========================================');
    b.writeln('           $title RECEIPT               ');
    b.writeln('========================================');
    b.writeln('Order Number: ${job.orderNumber}');
    if (job.customerName != null && job.customerName!.isNotEmpty) {
      b.writeln('Customer: ${job.customerName}');
    }
    if (job.customerPhone != null && job.customerPhone!.isNotEmpty) {
      b.writeln('Phone: ${job.customerPhone}');
    }
    b.writeln('----------------------------------------');
    b.writeln('Item                          Qty   Rate');
    b.writeln('----------------------------------------');
    for (final item in job.items) {
      final name = item.product.name.padRight(28);
      final qty = item.quantity.toString().padLeft(3);
      final rate = item.product.price.toStringAsFixed(2).padLeft(6);
      b.writeln(
        '${name.substring(0, name.length > 28 ? 28 : name.length)} $qty  $rate',
      );
    }
    b.writeln('----------------------------------------');
    b.writeln(
      'Subtotal:                     ${job.subtotal.toStringAsFixed(2)}',
    );
    b.writeln('Tax:                          ${job.tax.toStringAsFixed(2)}');
    b.writeln(
      'Discount:                     ${job.discount.toStringAsFixed(2)}',
    );
    b.writeln('Charge:                       ${job.charge.toStringAsFixed(2)}');
    b.writeln('----------------------------------------');
    b.writeln('TOTAL:                        ${job.total.toStringAsFixed(2)}');
    b.writeln('Payment: ${job.paymentMethod}');
    b.writeln('========================================');
    log(b.toString());
  }

  void _logKitchen(KitchenPrintJob job) {
    final b = StringBuffer();
    b.writeln('========================================');
    b.writeln('             ${job.title}               ');
    b.writeln('========================================');
    b.writeln('Order: ${job.orderNumber}');
    if (job.tableNumber != null && job.tableNumber!.isNotEmpty) {
      b.writeln('Table: ${job.tableNumber}');
    }
    if (job.staffName != null && job.staffName!.isNotEmpty) {
      b.writeln('Staff: ${job.staffName}');
    }
    b.writeln('----------------------------------------');
    b.writeln('Item                Unit     Qty');
    b.writeln('----------------------------------------');
    for (final item in job.items) {
      final name = item.product.name.padRight(19);
      final unit = item.displayUnit.padRight(8);
      final qty = item.quantity.toString().padLeft(3);
      b.writeln(
        '${name.substring(0, name.length > 19 ? 19 : name.length)} $unit $qty',
      );
      if (item.notes.isNotEmpty) {
        b.writeln('  EXTRA: ${item.notes}');
      }
    }
    b.writeln('========================================');
    log(b.toString());
  }

  void _logDuplicate(DuplicatePrintJob job) {
    final b = StringBuffer();
    b.writeln('========================================');
    b.writeln('             DUPLICATE BILL             ');
    b.writeln('========================================');
    b.writeln('Order: ${job.orderNumber}');
    if (job.staffName != null && job.staffName!.isNotEmpty) {
      b.writeln('Staff: ${job.staffName}');
    }
    b.writeln('----------------------------------------');
    for (final item in job.items) {
      b.writeln('${item.quantity}x ${item.product.name}');
    }
    b.writeln('========================================');
    log(b.toString());
  }


  Future<void> _withPrinter(
    PrinterRole role,
    Future<void> Function() print,
  ) async {
    final completer = Completer<void>();
    final myFuture = completer.future.catchError((_) {});
    final previousJob = _currentPrintJob;
    // Suppress unhandled exceptions on the queue itself. The caller still gets the error via rethrow.
    _currentPrintJob = myFuture;

    if (previousJob != null) {
      await previousJob.catchError((_) {});
    }

    try {
      await _executePrintJob(role, print);
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      if (identical(_currentPrintJob, myFuture)) {
        // Only clear the queue if no newer jobs were added behind us
        _currentPrintJob = null;
      }
    }
  }

  Future<void> _executePrintJob(
    PrinterRole role,
    Future<void> Function() print,
  ) async {
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

    try {
      await _ensureBluetoothAvailable();
      final device = ThermalPrinterDevice(
        name: selected.name,
        address: selected.address,
      );
      final connected = await _connectWithRetry(device);
      if (!connected) {
        throw PrinterManagerException(
          '${role.label} is unavailable. Check that it is on and retry.',
        );
      }
      try {
        await print();
      } on ReceiptPrinterException catch (error) {
        // This failure occurs before any bytes are written, so reconnecting is
        // safe and cannot create a duplicate receipt.
        if (error.message != 'The printer is not connected.') rethrow;
        final reconnected = await _connectWithRetry(device);
        if (!reconnected) {
          throw PrinterManagerException(
            '${role.label} disconnected. Turn it on and retry.',
          );
        }
        await print();
      }
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
    }
  }

  Future<bool> _connectWithRetry(ThermalPrinterDevice device) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      await _printerService.disconnect();
      await Future<void>.delayed(
        Duration(milliseconds: attempt == 0 ? 250 : 600),
      );
      if (await _printerService.connect(device)) return true;
    }
    return false;
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
