import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  test('calculates discounts and charges and defaults discount to none', () {
    final controller = _controllerWithCart();

    expect(controller.discountType.value, 'none');
    expect(controller.total, 200);

    controller.applyDiscount(type: 'percentage', value: 10);
    expect(controller.discountAmount, 20);
    expect(controller.total, 180);

    controller.applyCharge(amount: 5, reason: 'Packing');
    expect(controller.total, 185);

    controller.startNewBill();
    expect(controller.discountType.value, 'none');
    expect(controller.discountAmount, 0);
    expect(controller.chargeAmount.value, 0);
  });

  testWidgets('opens and applies discount and charge dialogs', (tester) async {
    final controller = _controllerWithCart();
    await tester.binding.setSurfaceSize(const Size(700, 900));
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: BillSummaryPanel(controller: controller)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Discount'));
    await tester.pumpAndSettle();
    expect(find.text('Add Discount'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply Discount'));
    await tester.pumpAndSettle();

    expect(controller.discountType.value, 'flat');
    expect(controller.discountAmount, 25);
    expect(find.text('- ₹25.00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Charge'));
    await tester.pumpAndSettle();
    expect(find.text('Add Charge'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, 'Packing');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(controller.chargeAmount.value, 10);
    expect(find.text('+ ₹10.00'), findsOneWidget);
    expect(controller.total, 185);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canceling discount keeps its type as none', (tester) async {
    final controller = _controllerWithCart();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: BillSummaryPanel(controller: controller)),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Discount'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(controller.discountType.value, 'none');
  });

  testWidgets('changes product quantity from the bill summary', (tester) async {
    final controller = _controllerWithCart();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: BillSummaryPanel(controller: controller)),
      ),
    );

    await tester.tap(find.byTooltip('Increase Test Product'));
    await tester.pump();
    expect(controller.cart.single.quantity, 3);
    expect(controller.total, 300);

    await tester.tap(find.byTooltip('Decrease Test Product'));
    await tester.pump();
    expect(controller.cart.single.quantity, 2);
    expect(controller.total, 200);
    expect(tester.takeException(), isNull);
  });
}

HomeController _controllerWithCart() {
  final controller = HomeController();
  controller.cart.add(
    CartItem(
      product: const Product(
        id: 1,
        name: 'Test Product',
        unit: '1pc',
        price: 100,
        image: '',
      ),
      quantity: 2,
    ),
  );
  return controller;
}
