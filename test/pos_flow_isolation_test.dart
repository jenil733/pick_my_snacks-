import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  const product = Product(
    id: 101,
    name: 'Veg Sandwich',
    unit: '1 pc',
    price: 80,
    image: '',
  );

  test('normal billing items do not continue into KOT or take away', () {
    final controller = HomeController();

    controller.addProduct(product);
    controller.selectFlow(PosFlow.kot);

    expect(controller.flow.value, PosFlow.kot);
    expect(controller.cart, isEmpty);

    controller.takeKotTable(1, staffName: 'Arun');
    controller.addProduct(product);
    controller.selectFlow(PosFlow.takeAway);

    expect(controller.flow.value, PosFlow.takeAway);
    expect(controller.cart, isEmpty);
    expect(controller.activeTableNumber.value, isNull);
  });

  test('KOT draft stays with its table when another billing mode opens', () {
    final controller = HomeController();

    controller.selectFlow(PosFlow.kot);
    controller.takeKotTable(1, staffName: 'Arun');
    controller.addProduct(product);
    controller.selectFlow(PosFlow.billing);

    expect(controller.cart, isEmpty);
    expect(controller.tableOrders[1]?.itemCount, 1);

    controller.selectFlow(PosFlow.kot);
    controller.continueKotTable(1);

    expect(controller.cart.single.product.name, 'Veg Sandwich');
  });

  test('take away items do not continue into normal billing', () {
    final controller = HomeController();

    controller.selectFlow(PosFlow.takeAway);
    controller.addProduct(product);
    controller.selectFlow(PosFlow.billing);

    expect(controller.flow.value, PosFlow.billing);
    expect(controller.cart, isEmpty);
  });
}
