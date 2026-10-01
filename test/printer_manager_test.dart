import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_manager.dart';
import 'package:pick_my_snacks/src/printing/printer_repository.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

void main() {
  test('formats a completed order as a console receipt', () {
    final receipt = PrinterManager.formatReceiptForConsole(
      'TAKE AWAY SAVE ORDER',
      ReceiptPrintJob(
        items: [
          CartItem(
            product: const Product(
              id: 4,
              name: 'Burger',
              unit: 'pcs',
              price: 100,
              image: '',
            ),
            quantity: 2,
          ),
        ],
        subtotal: 200,
        tax: 10,
        discount: 5,
        charge: 2,
        total: 207.40,
        paymentMethod: 'cash',
        orderNumber: 'TA-1001',
        customerName: 'Anu',
      ),
    );

    expect(receipt, contains('TAKE AWAY SAVE ORDER RECEIPT'));
    expect(receipt, contains('Order Number: TA-1001'));
    expect(receipt, contains('Burger'));
    expect(receipt, contains('TOTAL:'));
    expect(receipt, contains('207.00'));
    expect(receipt, isNot(contains('Round Off')));
    expect(receipt, contains('Payment: cash'));
  });

  test('retries a failed Bluetooth connection before printing', () async {
    final service = _RetryPrinterService();
    final manager = PrinterManager(
      _FakePrinterRepository(),
      service,
      KitchenPrinter(),
    );

    await manager.printTakeAwayReceipt(
      const ReceiptPrintJob(
        items: [],
        subtotal: 0,
        tax: 0,
        discount: 0,
        charge: 0,
        total: 1119.89,
        paymentMethod: 'cash',
        orderNumber: 'TEST-1',
      ),
    );

    expect(service.connectCalls, 2);
    expect(service.printCalls, 1);
    expect(service.receivedTotal, 1120);
    expect(service.receivedRoundOff, closeTo(0.11, 0.000001));
  });
}

class _FakePrinterRepository implements PrinterRepository {
  @override
  PrinterSettingsModel? getPrinter(PrinterRole role) {
    return const PrinterSettingsModel(
      name: 'Test printer',
      address: '00:11:22:33:44:55',
      connectionType: PrinterConnectionType.bluetooth,
    );
  }

  @override
  Future<void> removePrinter(PrinterRole role) async {}

  @override
  Future<void> savePrinter(
    PrinterRole role,
    PrinterSettingsModel printer,
  ) async {}
}

class _RetryPrinterService implements ReceiptPrinterService {
  int connectCalls = 0;
  int printCalls = 0;
  double? receivedTotal;
  double? receivedRoundOff;

  @override
  Future<bool> get isBluetoothEnabled async => true;

  @override
  Future<bool> get isBluetoothPermissionGranted async => true;

  @override
  Future<bool> connect(ThermalPrinterDevice printer) async {
    connectCalls++;
    return connectCalls > 1;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> printBluetoothReceipt({
    required List<dynamic> items,
    required double subtotal,
    required double tax,
    double discount = 0,
    double charge = 0,
    required double total,
    double roundOff = 0,
    required String paymentMethod,
    required String orderNumber,
    required ReceiptPaperSize paperSize,
    bool showRate = true,
    bool showAmount = true,
    bool showTotals = true,
    bool separateProducts = false,
    int endFeedLines = 3,
    String? staffName,
    String? customerName,
    String? customerPhone,
  }) async {
    printCalls++;
    receivedTotal = total;
    receivedRoundOff = roundOff;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
