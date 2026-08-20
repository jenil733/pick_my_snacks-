import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/common_widgets.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('take away item accepts an extra note below quantity controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1000));
    final controller = HomeController()..onInit();
    controller.selectFlow(PosFlow.takeAway);
    final item = CartItem(product: controller.products.first);
    controller.cart.assign(item);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BillSummaryPanel(controller: controller)),
      ),
    );
    await tester.pump();

    final extraField = find.byType(ExtraItemNoteField);
    expect(extraField, findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(BillQuantityControl)).dy,
      lessThan(tester.getTopLeft(extraField).dy),
    );

    await tester.enterText(
      find.descendant(of: extraField, matching: find.byType(TextField)),
      'Extra spicy',
    );
    expect(item.notes, 'Extra spicy');
    expect(tester.takeException(), isNull);

    controller.onClose();
  });
}
