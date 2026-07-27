import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pick_my_snacks/main.dart';
import 'package:pick_my_snacks/src/core/utils/navigation/approutes.dart';
import 'package:pick_my_snacks/src/data/model/post_login.dart';
import 'package:pick_my_snacks/src/domain/repository/login_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/login_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/login/login_controller.dart';
import 'package:pick_my_snacks/src/services/receipt_printer_service.dart';

void main() {
  const homeApp = MyApp(initialRoute: AppRoutes.homescreen);

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('logs in to home and logs out from the Staff menu', (
    tester,
  ) async {
    Get.lazyPut<LoginController>(
      () => LoginController(LoginUseCase(_FakeLoginRepository())),
      fenix: true,
    );
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'staff',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Tablet billing'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);

    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Tablet billing'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays on login when the API rejects the credentials', (
    tester,
  ) async {
    Get.lazyPut<LoginController>(
      () => LoginController(LoginUseCase(_FakeLoginRepository())),
      fenix: true,
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'wrong-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Products'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses product and bill screens on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Products'), findsWidgets);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Cart'), findsNothing);
    expect(find.textContaining('View bill'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('View bill'));
    await tester.pumpAndSettle();
    expect(find.text('Bill Summary'), findsOneWidget);
    expect(find.text('Print Receipt'), findsOneWidget);
    expect(find.text('Cart'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Print Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('The printer is not connected.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 9));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('adds and removes a product from its inline quantity control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HomeController>();
    final initialCount = controller.itemCount;
    final cocaCola = controller.products.singleWhere(
      (product) => product.name == 'Coca Cola',
    );

    await tester.tap(find.byTooltip('Add Coca Cola'));
    await tester.pumpAndSettle();

    expect(controller.itemCount, initialCount + 1);
    expect(
      controller.cart
          .singleWhere((item) => item.product.name == 'Coca Cola')
          .quantity,
      1,
    );

    final cocaColaQuantityControl = find.byKey(
      ValueKey('product-quantity-${cocaCola.id}'),
    );
    await tester.tap(
      find.descendant(
        of: cocaColaQuantityControl,
        matching: find.byTooltip('Remove one'),
      ),
    );
    await tester.pump();

    expect(controller.itemCount, initialCount);
    expect(
      controller.cart.where((item) => item.product.name == 'Coca Cola'),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('holds the current bill from the mobile bill summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HomeController>();
    await tester.tap(find.textContaining('View bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Hold Bill'));
    await tester.pump();

    expect(controller.cart, isEmpty);
    expect(controller.heldBills, hasLength(1));
    expect(find.text('Bill #1 held successfully.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starts a new bill and returns to mobile products', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HomeController>();
    expect(controller.cart, isNotEmpty);

    await tester.tap(find.textContaining('View bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'New Bill'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(controller.cart, isEmpty);
    expect(controller.paymentMethod.value, 'cash');
    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Bill Summary'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a two-pane product and billing workspace on tablet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tablet billing'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Selected Items (4)'), findsOneWidget);
    expect(find.text('Bill Summary'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    expect(find.text('Bill Summary'), findsOneWidget);
    expect(find.text('Print Receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the three-panel tablet billing screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Selected Items (4)'), findsOneWidget);
    expect(find.text('Bill Summary'), findsOneWidget);
    expect(find.text('Items (3)'), findsOneWidget);
    expect(find.text('Print Receipt'), findsOneWidget);
    expect(find.text('Held Bills'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsNothing);
    expect(find.text('UPI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates cart totals when a product is added', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HomeController>();
    expect(tester.takeException(), isNull);
    controller.addProduct(controller.products.first);
    await tester.pump();

    expect(find.text('Selected Items (5)'), findsOneWidget);
    expect(find.text('₹110.00'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('prints directly and warns when the printer is not connected', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Print Receipt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose connection'), findsNothing);
    expect(find.text('Bluetooth'), findsNothing);
    expect(find.text('USB cable'), findsNothing);
    expect(find.text('The printer is not connected.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 9));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('opens and restores a held bill from the app bar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(homeApp);
    await tester.pump(const Duration(milliseconds: 300));

    final controller = Get.find<HomeController>();
    controller.holdCurrentBill();
    await tester.pump();

    await tester.tap(find.text('Held Bills'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Bill #1'), findsOneWidget);

    await tester.tap(find.text('Bill #1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Continue Bill #1?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.itemCount, 4);
    expect(controller.heldBills, isEmpty);
    Get.closeAllSnackbars();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  test('holds and restores a bill without sharing cart item state', () {
    final controller = HomeController();
    controller.onInit();

    final heldBill = controller.holdCurrentBill();
    expect(controller.cart, isEmpty);
    expect(controller.heldBills.length, 1);
    expect(heldBill.itemCount, 4);

    controller.restoreHeldBill(heldBill);
    expect(controller.itemCount, 4);
    expect(controller.heldBills, isEmpty);

    controller.increment(controller.cart.first);
    expect(controller.itemCount, 5);
    expect(heldBill.itemCount, 4);
    controller.onClose();
  });

  test('finds a product by its exact product ID', () {
    final controller = HomeController()..onInit();

    controller.searchQuery.value = '2';

    expect(controller.filteredProducts, hasLength(1));
    expect(controller.filteredProducts.single.id, 2);
    controller.onClose();
  });

  test('adds a weighted product from a 9-digit QR code', () {
    final controller = HomeController()..onInit();

    final result = controller.addProductFromQr('000190250');

    expect(result.isSuccess, isTrue);
    expect(result.item!.product.id, 1);
    expect(result.item!.displayUnit, '0.250');
    expect(result.item!.scannedWeightGrams, 250);
    expect(result.item!.total, 5);

    final repeatedResult = controller.addProductFromQr('000190250');
    expect(repeatedResult.item!.quantity, 2);
    expect(repeatedResult.item!.total, 10);

    final kilogramResult = controller.addProductFromQr('000191250');
    expect(kilogramResult.item!.displayUnit, '1.250');
    expect(kilogramResult.item!.total, 25);
    controller.onClose();
  });

  test('rejects an invalid product QR code', () {
    final controller = HomeController()..onInit();

    expect(controller.addProductFromQr('123').isSuccess, isFalse);
    expect(controller.addProductFromQr('999990250').isSuccess, isFalse);
    expect(controller.addProductFromQr('000190000').isSuccess, isFalse);
    controller.onClose();
  });

  test('builds the receipt with the backend GST total', () async {
    final controller = HomeController()..onInit();
    final receiptItems = [
      ...controller.cart,
      CartItem(
        product: const Product(
          id: 999,
          name: 'Test Product',
          unit: '1pc',
          price: 1300,
          image: '',
        ),
      ),
      CartItem(
        product: const Product(
          id: 1000,
          name: 'Fixed columns',
          unit: '100pcs',
          price: 500,
          image: '',
        ),
      ),
    ];
    final bytes = await ReceiptPrinterService().buildReceiptBytes(
      items: receiptItems,
      subtotal: controller.subtotal,
      tax: 65,
      total: 1365,
      orderNumber: 'ORD0012',
      paperSize: ReceiptPaperSize.mm58,
    );
    final receiptText = String.fromCharCodes(bytes);

    expect(_containsBytes(bytes, const [29, 118, 48]), isTrue);
    expect(_rasterInkRatio(bytes), greaterThan(.05));
    expect(_rasterInkRatio(bytes), lessThan(.60));
    expect(receiptText, contains('Vettturnimadam, Nagercoil'));
    expect(receiptText, contains('- 629001  CELL: 7339595793'));
    expect(receiptText, isNot(contains('GSTIN')));
    expect(receiptText, contains('CELL: 7339595793'));
    expect(receiptText, contains('   ORIGINAL'));
    expect(receiptText, contains('Order No: ORD0012'));
    expect(receiptText, contains('Item'));
    expect(receiptText, contains('Total Items:'));
    expect(receiptText, contains('Subtotal'));
    expect(receiptText, contains('GST'));
    expect(receiptText, contains('Grand Total'));
    expect(receiptText, contains('65.00'));
    expect(receiptText, contains('1365.00'));
    expect(receiptText, contains('20.00'));
    expect(receiptText, contains('1300.00'));
    expect(receiptText, contains('TEST'));
    expect(receiptText, contains('RODUCT'));
    expect(receiptText, isNot(contains('TEST PRODUCT')));
    expect(receiptText, contains('Unit'));
    expect(receiptText, contains('1PC'));
    expect(receiptText.indexOf('Unit'), lessThan(receiptText.indexOf('Qty')));
    final receiptLines = receiptText.split('\n');
    final firstProductLine = receiptLines.firstWhere(
      (line) => line.contains('TEST') && line.contains('1300.00'),
    );
    expect(firstProductLine, contains('1PC'));
    final secondProductNameLine = receiptLines.firstWhere(
      (line) => line.contains('RODUCT'),
    );
    expect(secondProductNameLine, isNot(contains('1300.00')));
    final fixedColumnLine = receiptLines.firstWhere(
      (line) => line.contains('FIXED') && line.contains('500.00'),
    );
    expect(fixedColumnLine, contains('100PCS'));
    final moneyLines = receiptText
        .split('\n')
        .where(
          (line) =>
              line.contains('Subtotal') ||
              line.contains('GST') ||
              line.contains('Grand Total'),
        )
        .toList();
    expect(moneyLines, hasLength(3));
    expect(
      moneyLines.map((line) {
        final label = line.contains('Subtotal')
            ? 'Subtotal'
            : line.contains('Grand Total')
            ? 'Grand Total'
            : 'GST';
        return line.indexOf('Rs.') - line.indexOf(label);
      }).toSet(),
      hasLength(1),
    );
    expect(receiptText, isNot(contains('CGST')));
    expect(receiptText, isNot(contains('SGST')));
    expect(receiptText, contains('THANK YOU VISIT AGAIN'));
    controller.onClose();
  });
}

class _FakeLoginRepository implements LoginRepository {
  @override
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    if (username != 'staff' || password != 'password') {
      return LoginResponse(
        status: false,
        message: 'Invalid username or password.',
      );
    }

    return LoginResponse(
      status: true,
      message: 'Login successful',
      data: LoginData(
        token: 'test-token',
        counterName: 'Test Counter',
        loginId: username,
      ),
    );
  }
}

bool _containsBytes(List<int> source, List<int> pattern) {
  for (var index = 0; index <= source.length - pattern.length; index++) {
    var matches = true;
    for (var offset = 0; offset < pattern.length; offset++) {
      if (source[index + offset] != pattern[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

double _rasterInkRatio(List<int> receipt) {
  const rasterCommand = [29, 118, 48];
  var commandIndex = -1;
  for (var index = 0; index <= receipt.length - rasterCommand.length; index++) {
    if (receipt[index] == rasterCommand[0] &&
        receipt[index + 1] == rasterCommand[1] &&
        receipt[index + 2] == rasterCommand[2]) {
      commandIndex = index;
      break;
    }
  }
  if (commandIndex < 0) return 0;

  final widthBytes =
      receipt[commandIndex + 4] + (receipt[commandIndex + 5] << 8);
  final height = receipt[commandIndex + 6] + (receipt[commandIndex + 7] << 8);
  final dataStart = commandIndex + 8;
  final dataEnd = dataStart + (widthBytes * height);
  var printedDots = 0;

  for (final byte in receipt.sublist(dataStart, dataEnd)) {
    for (var bit = 0; bit < 8; bit++) {
      if ((byte & (1 << bit)) != 0) printedDots++;
    }
  }

  return printedDots / (widthBytes * 8 * height);
}
