import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

class KitchenPrintJob {
  const KitchenPrintJob({
    required this.items,
    required this.orderNumber,
    required this.paperSize,
    this.title = 'KITCHEN ORDER',
    this.tableNumber,
    this.staffName,
    this.customerName,
    this.customerPhone,
  });

  final List<CartItem> items;
  final String orderNumber;
  final ReceiptPaperSize paperSize;
  final String title;
  final String? tableNumber;
  final String? staffName;
  final String? customerName;
  final String? customerPhone;
}

class KitchenPrinter {
  Future<List<int>> buildTicket(KitchenPrintJob job) async {
    final profile = await CapabilityProfile.load();
    final paperSize = job.paperSize == ReceiptPaperSize.mm58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    final now = DateTime.now();
    final bytes = <int>[];
    const normal = PosStyles(fontType: PosFontType.fontA, bold: true);

    bytes.addAll(generator.reset());
    bytes.addAll(
      generator.text(
        job.title,
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
          bold: true,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Order: ${job.orderNumber}', styles: normal));
    final table = job.tableNumber?.trim();
    if (table != null && table.isNotEmpty) {
      bytes.addAll(generator.text('Table: $table', styles: normal));
    }
    bytes.addAll(generator.text('Date: ${_dateTime(now)}', styles: normal));
    final staff = job.staffName?.trim();
    if (staff != null && staff.isNotEmpty) {
      bytes.addAll(generator.text('Staff: $staff', styles: normal));
    }
    final customerName = job.customerName?.trim();
    if (customerName != null && customerName.isNotEmpty) {
      bytes.addAll(generator.text('Customer: $customerName', styles: normal));
    }
    final customerPhone = job.customerPhone?.trim();
    if (customerPhone != null && customerPhone.isNotEmpty) {
      bytes.addAll(generator.text('Phone: $customerPhone', styles: normal));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.row(
        _itemColumns(
          item: 'Item',
          unit: 'Unit',
          quantity: 'Qty',
          style: normal,
        ),
      ),
    );
    bytes.addAll(generator.hr());
    for (final item in job.items) {
      bytes.addAll(
        generator.row(
          _itemColumns(
            item: item.product.name.toUpperCase(),
            unit: item.displayUnit.toUpperCase(),
            quantity: '${item.quantity}',
            style: normal,
          ),
        ),
      );
      final note = item.notes.trim();
      if (note.isNotEmpty) {
        bytes.addAll(generator.text('  EXTRA: $note', styles: normal));
      }
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(3));
    return bytes;
  }

  Future<List<int>> buildTestTicket({
    required String roleLabel,
    required ReceiptPaperSize paperSize,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == ReceiptPaperSize.mm58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    return [
      ...generator.reset(),
      ...generator.text(
        '$roleLabel TEST',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      ...generator.text(
        'Printer configured successfully',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...generator.feed(5),
      ...generator.cut(),
    ];
  }

  String _dateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  List<PosColumn> _itemColumns({
    required String item,
    required String unit,
    required String quantity,
    required PosStyles style,
  }) {
    return [
      PosColumn(text: item, width: 7, styles: style),
      PosColumn(
        text: unit,
        width: 3,
        styles: style.copyWith(align: PosAlign.center),
      ),
      PosColumn(
        text: quantity,
        width: 2,
        styles: style.copyWith(align: PosAlign.right),
      ),
    ];
  }
}
