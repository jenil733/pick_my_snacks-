import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/services/local_storage.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/printing/kitchen_printer.dart';
import 'package:pick_my_snacks/src/printing/printer_repository.dart';
import 'package:pick_my_snacks/src/printing/printer_settings_model.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'stores billing, kitchen, and take away printers independently',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.initialize();
      final repository = LocalPrinterRepository(storage);
      const billing = PrinterSettingsModel(
        name: 'Front Desk',
        address: 'AA:BB:CC:11',
        connectionType: PrinterConnectionType.bluetooth,
      );
      const kitchen = PrinterSettingsModel(
        name: 'Kitchen',
        address: 'AA:BB:CC:22',
        connectionType: PrinterConnectionType.bluetooth,
      );
      const takeAway = PrinterSettingsModel(
        name: 'Take Away',
        address: 'AA:BB:CC:33',
        connectionType: PrinterConnectionType.bluetooth,
      );

      await repository.savePrinter(PrinterRole.billing, billing);
      await repository.savePrinter(PrinterRole.kitchen, kitchen);
      await repository.savePrinter(PrinterRole.takeAway, takeAway);

      expect(
        repository.getPrinter(PrinterRole.billing)?.address,
        billing.address,
      );
      expect(
        repository.getPrinter(PrinterRole.kitchen)?.address,
        kitchen.address,
      );
      expect(
        repository.getPrinter(PrinterRole.takeAway)?.address,
        takeAway.address,
      );
    },
  );

  test(
    'kitchen order contains item, unit, and quantity without prices',
    () async {
      final bytes = await KitchenPrinter().buildTicket(
        KitchenPrintJob(
          items: [
            CartItem(
              product: const Product(
                id: 1,
                name: 'Masala Sandwich',
                unit: '1 pc',
                price: 149.75,
                image: '',
              ),
              quantity: 2,
              notes: 'No onion',
            ),
          ],
          orderNumber: 'ORD-42',
          tableNumber: 'T7',
          staffName: 'Arun',
          paperSize: ReceiptPaperSize.mm58,
        ),
      );
      final printable = String.fromCharCodes(bytes);

      expect(printable, contains('KITCHEN ORDER'));
      expect(printable, isNot(contains('TICKET')));
      expect(printable, isNot(contains('KOT')));
      expect(printable, contains('Order: ORD-42'));
      expect(printable, contains('Table: T7'));
      expect(printable, contains('Item'));
      expect(printable, contains('Unit'));
      expect(printable, contains('Qty'));
      expect(printable, contains('MASALA SANDWICH'));
      expect(printable, contains('1PC'));
      expect(printable, contains('EXTRA: No onion'));
      expect(printable, contains('Staff: Arun'));
      expect(printable, isNot(contains('149.75')));
      expect(printable.toLowerCase(), isNot(contains('payment')));
    },
  );

  test(
    'take away ticket keeps order details but excludes all prices',
    () async {
      final bytes = await KitchenPrinter().buildTicket(
        KitchenPrintJob(
          items: [
            CartItem(
              product: const Product(
                id: 2,
                name: 'Take Away Mixture',
                unit: '250 g',
                price: 87.50,
                image: '',
              ),
              quantity: 3,
              notes: 'Pack separately',
            ),
          ],
          orderNumber: 'TA-12345',
          staffName: 'Sam',
          customerName: 'Anu',
          customerPhone: '9876543210',
          title: 'TAKE AWAY',
          paperSize: ReceiptPaperSize.mm58,
        ),
      );
      final printable = String.fromCharCodes(bytes);

      expect(printable, contains('TAKE AWAY'));
      expect(printable, contains('Order: TA-12345'));
      expect(printable, contains('Date:'));
      expect(printable, contains('Staff: Sam'));
      expect(printable, contains('Customer: Anu'));
      expect(printable, contains('Phone: 9876543210'));
      expect(printable, contains('TAKE AWAY MIXTURE'));
      expect(printable, contains('250G'));
      expect(printable, contains('3'));
      expect(printable, contains('EXTRA: Pack separately'));
      expect(printable, isNot(contains('Rate')));
      expect(printable, isNot(contains('Amount')));
      expect(printable, isNot(contains('87.50')));
      expect(printable, isNot(contains('262.50')));
    },
  );

  test('take away receipt excludes all monetary values', () async {
    final bytes = await ReceiptPrinterService().buildReceiptBytes(
      items: [
        CartItem(
          product: const Product(
            id: 3,
            name: 'Parcel Snack',
            unit: '1 pc',
            price: 87.50,
            image: '',
          ),
          quantity: 2,
          notes: 'Extra spicy',
        ),
      ],
      subtotal: 175,
      tax: 8.75,
      total: 183.75,
      paymentMethod: 'cash',
      orderNumber: 'TA-67890',
      paperSize: ReceiptPaperSize.mm58,
      showRate: false,
      showAmount: false,
      showTotals: false,
      separateProducts: true,
      endFeedLines: 5,
      customerName: 'Anu',
      customerPhone: '9876543210',
    );
    final printable = String.fromCharCodes(bytes);

    expect(printable, contains('Order No: TA-67890'));
    expect(printable, contains('Customer: Anu'));
    expect(printable, contains('Phone: 9876543210'));
    expect(printable, contains('Item'));
    expect(printable, contains('Unit'));
    expect(printable, contains('Qty'));
    expect(printable, isNot(contains('Rate')));
    expect(printable, isNot(contains('Amount')));
    expect(printable, isNot(contains('175.00')));
    expect(printable, isNot(contains('87.50')));
    expect(printable, isNot(contains('Grand Total')));
    expect(printable, isNot(contains('183.75')));
    expect(printable, isNot(contains('GST')));
    expect(printable, isNot(contains('Extra spicy')));
    final lines = printable.split('\n');
    final productLine = lines.indexWhere(
      (line) => line.contains('PARCEL SNACK'),
    );
    expect(productLine, greaterThanOrEqualTo(0));
    expect(lines[productLine + 1], contains('---'));
    expect(bytes.sublist(bytes.length - 3), orderedEquals([27, 100, 5]));
  });

  test('take away receipt can show rate without amount', () async {
    final bytes = await ReceiptPrinterService().buildReceiptBytes(
      items: [
        CartItem(
          product: const Product(
            id: 4,
            name: 'Banana Chips',
            unit: '1 pc',
            price: 80,
            image: '',
          ),
          quantity: 2,
        ),
      ],
      subtotal: 160,
      tax: 8,
      total: 168,
      paymentMethod: 'cash',
      orderNumber: 'TA-67891',
      paperSize: ReceiptPaperSize.mm58,
      showRate: true,
      showAmount: false,
      showTotals: false,
      separateProducts: true,
      endFeedLines: 5,
    );
    final printable = String.fromCharCodes(bytes);

    expect(printable, contains('Rate'));
    expect(printable, contains('80.00'));
    expect(printable, isNot(contains('Amount')));
    expect(printable, isNot(contains('160.00')));
    expect(printable, isNot(contains('Grand Total')));
  });

  test('completed take away receipt uses the normal bill layout', () async {
    final bytes = await ReceiptPrinterService().buildReceiptBytes(
      items: [
        CartItem(
          product: const Product(
            id: 5,
            name: 'Potato Chips',
            unit: '1 pc',
            price: 100,
            image: '',
          ),
          quantity: 2,
        ),
      ],
      subtotal: 200,
      tax: 10,
      total: 210,
      paymentMethod: 'cash',
      orderNumber: 'TA-67892',
      paperSize: ReceiptPaperSize.mm58,
      showRate: true,
      showAmount: true,
      showTotals: true,
      separateProducts: false,
      endFeedLines: 3,
    );
    final printable = String.fromCharCodes(bytes);

    expect(printable, contains('Rate'));
    expect(printable, contains('Amount'));
    expect(printable, contains('100.00'));
    expect(printable, contains('200.00'));
    expect(printable, contains('Grand Total'));
    expect(printable, contains('210.00'));
  });
}
