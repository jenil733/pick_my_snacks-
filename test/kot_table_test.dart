import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('does not occupy a KOT table until an item is added', () {
    final controller = HomeController();

    controller.takeKotTable(1, staffName: 'Arun');
    controller.showKotTables();

    expect(controller.tableOrders, isEmpty);
    expect(controller.activeTableNumber.value, isNull);
    expect(controller.kotStage.value, KotStage.tables);
  });

  test('stores and resumes items for a free unheld KOT table', () {
    final controller = HomeController();
    const product = Product(
      id: 101,
      name: 'Veg Sandwich',
      unit: '1 pc',
      price: 80,
      image: '',
    );

    controller.takeKotTable(1, staffName: 'Arun');
    controller.addProduct(product);
    controller.showKotTables();

    expect(controller.tableOrders[1]?.staffName, 'Arun');
    expect(controller.tableOrders[1]?.itemCount, 1);
    expect(controller.kotStage.value, KotStage.tables);

    controller.continueKotTable(1);

    expect(controller.activeTableNumber.value, 1);
    expect(controller.kotStage.value, KotStage.order);
    expect(controller.cart.single.product.name, 'Veg Sandwich');
  });
}
