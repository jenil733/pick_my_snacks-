import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';

void main() {
  tearDown(Get.reset);

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

  test(
    'shows the table owner while continuing and restores prior staff',
    () async {
      final staffController = Get.put(StaffController());
      const arun = StaffData(id: 1, name: 'Arun');
      const sam = StaffData(id: 2, name: 'Sam');
      await staffController.selectStaff(arun);
      final controller = HomeController()..onInit();
      const product = Product(
        id: 101,
        name: 'Veg Sandwich',
        unit: '1 pc',
        price: 80,
        image: '',
      );

      controller.takeKotTable(1, staffName: 'Arun', staffId: 1);
      controller.addProduct(product);
      controller.showKotTables();
      await staffController.selectStaff(sam);

      controller.continueKotTable(1);
      expect(staffController.selectedStaffName, 'Arun');
      expect(controller.tableOrders[1]?.staffName, 'Arun');

      await staffController.selectStaff(const StaffData(id: 3, name: 'Priya'));
      expect(staffController.selectedStaffName, 'Priya');
      expect(controller.tableOrders[1]?.staffName, 'Priya');
      expect(controller.tableOrders[1]?.staffId, 3);

      controller.showKotTables();
      expect(staffController.selectedStaffName, 'Sam');
      expect(controller.tableOrders[1]?.staffName, 'Priya');

      controller.onClose();
    },
  );
}
