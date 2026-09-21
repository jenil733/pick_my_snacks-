import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/kot_get_persons.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_get_persons_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_kot_persons_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/kot_persons_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(CartController());
  });

  tearDown(Get.reset);

  testWidgets('opens a new person bill and hides it until confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = HomeController();
    await controller.showKotPersons(4);
    final staffController = Get.put(StaffController());
    await staffController.selectStaff(const StaffData(id: 1, name: 'Staff'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KotPersonsView(controller: controller)),
      ),
    );

    expect(find.text('Add Person'), findsOneWidget);
    expect(find.text('Person 1'), findsNothing);

    await tester.tap(find.text('Add Person'));
    await tester.pump();
    expect(controller.kotStage.value, KotStage.order);
    expect(controller.activeKotPersonNumber.value, 1);
    expect(find.text('Person 1'), findsNothing);
  });

  testWidgets('asks for staff selection before adding a person', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = HomeController();
    await controller.showKotPersons(4);
    Get.put(StaffController());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: KotPersonsView(controller: controller)),
      ),
    );

    await tester.tap(find.text('Add Person'));
    await tester.pump();

    expect(find.text('Please select a staff member.'), findsOneWidget);
    expect(controller.kotStage.value, KotStage.persons);
    expect(controller.activeKotPersonNumber.value, isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('shows delete menu for confirmed people', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = HomeController();
    await controller.showKotPersons(4);
    controller.kotPersonBills[4] = [
      KotPersonBill(
        personNumber: 1,
        isConfirmed: true,
        order: KotTableOrder(
          tableNumber: 4,
          staffName: 'Staff',
          openedAt: DateTime(2026),
          items: const [],
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KotPersonsView(controller: controller)),
      ),
    );

    expect(find.text('Person 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Person options'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Person 1'), findsNothing);
  });

  test('closing one person keeps the other person bill', () async {
    final controller = HomeController();
    await controller.showKotPersons(4);
    final firstOrder = KotTableOrder(
      tableNumber: 4,
      staffName: 'Staff',
      openedAt: DateTime(2026),
      items: [
        CartItem(
          product: const Product(
            id: 1,
            name: 'Snack',
            unit: '1 pc',
            price: 120,
            image: '',
          ),
        ),
      ],
    );
    final secondOrder = KotTableOrder(
      tableNumber: 4,
      staffName: 'Staff',
      openedAt: DateTime(2026),
      items: const [],
    );
    controller.kotPersonBills[4] = [
      KotPersonBill(personNumber: 1, order: firstOrder, isConfirmed: true),
      KotPersonBill(personNumber: 2, order: secondOrder, isConfirmed: true),
    ];

    controller.openKotPersonBill(1);
    controller.finishCompletedKotOrder();

    expect(controller.kotStage.value, KotStage.persons);
    expect(controller.selectedKotTableNumber.value, 4);
    expect(controller.kotPersonBills[4], hasLength(1));
    expect(controller.kotPersonBills[4]!.single.personNumber, 2);
  });

  test('person refresh keeps products not yet sent to the kitchen', () async {
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetKotPersonsUseCase(_SavedProductPersonsRepository()),
    );
    controller.kotPersonBills[4] = <KotPersonBill>[
      KotPersonBill(
        personNumber: 1,
        personId: 'P1-260918-12',
        isConfirmed: true,
        order: KotTableOrder(
          tableNumber: 4,
          staffName: 'Staff',
          openedAt: DateTime(2026),
          items: <CartItem>[
            CartItem(
              product: const Product(
                id: 1,
                name: 'Sent snack',
                unit: '1 pc',
                price: 120,
                image: '',
              ),
              kotProductReferences: <KotProductReference>[
                const KotProductReference(orderId: 265, detailId: 401),
              ],
            ),
            CartItem(
              product: const Product(
                id: 2,
                name: 'Unsent drink',
                unit: '1 pc',
                price: 20,
                image: '',
              ),
            ),
          ],
        ),
      ),
    ];

    await controller.getKotPersons(4);

    final items = controller.kotPersonBills[4]!.single.order.items;
    expect(items.map((item) => item.product.id), containsAll(<int>[1, 2]));
    expect(items, hasLength(2));
    expect(
      items.singleWhere((item) => item.product.id == 2).kotProductReferences,
      isEmpty,
    );
  });

  test(
    'restores checked kitchen products after visiting another table',
    () async {
      final controller = HomeController();
      controller.takeKotTable(1, staffName: 'Staff');
      controller.addProduct(
        const Product(
          id: 1,
          name: 'Selected snack',
          unit: '1 pc',
          price: 50,
          image: '',
        ),
      );
      controller.addProduct(
        const Product(
          id: 2,
          name: 'Normal drink',
          unit: '1 pc',
          price: 20,
          image: '',
        ),
      );
      controller.setKitchenItemSelected(controller.cart.first, true);

      await controller.showKotPersons(2);
      await controller.showKotPersons(1);
      controller.openKotPersonBill(1);

      expect(controller.cart, hasLength(2));
      expect(controller.kitchenSelectedItems, hasLength(1));
      expect(controller.kitchenSelectedItems.single.product.id, 1);
      expect(controller.isKitchenItemSelected(controller.cart.first), isTrue);
      expect(controller.isKitchenItemSelected(controller.cart.last), isFalse);
    },
  );

  test(
    'preserves increased item quantity when switching bills and returning to first bill',
    () async {
      final controller = HomeController();
      const product1 = Product(
        id: 1,
        name: 'Snack A',
        unit: '1 pc',
        price: 50,
        image: '',
      );
      const product2 = Product(
        id: 2,
        name: 'Snack B',
        unit: '1 pc',
        price: 30,
        image: '',
      );

      // Start Table 1 bill and add Snack A
      controller.takeKotTable(1, staffName: 'Staff');
      controller.addProduct(product1);
      expect(controller.cart.single.quantity, 1);

      // Increase quantity of Snack A to 2
      controller.increment(controller.cart.single);
      expect(controller.cart.single.quantity, 2);

      // Switch to Table 2 bill and add Snack B
      controller.takeKotTable(2, staffName: 'Staff');
      controller.addProduct(product2);
      expect(controller.cart.single.product.id, 2);
      expect(controller.cart.single.quantity, 1);

      // Return to Table 1 bill
      await controller.showKotPersons(1);
      controller.openKotPersonBill(1);

      // Verify Snack A has quantity 2 and Snack B is not in Table 1 bill
      expect(controller.cart, hasLength(1));
      expect(controller.cart.single.product.id, 1);
      expect(controller.cart.single.quantity, 2);
    },
  );

  test(
    'addProduct on existing product in KOT cart increments quantity without duplicating rows',
    () async {
      final controller = HomeController();
      const product1 = Product(
        id: 1,
        name: 'Snack A',
        unit: '1 pc',
        price: 50,
        image: '',
      );

      controller.takeKotTable(1, staffName: 'Staff');
      controller.addProduct(product1);

      // Simulate product having a kotProductReference (sent to kitchen or restored)
      controller.cart.single.kotProductReferences.add(
        const KotProductReference(orderId: 10, detailId: 100),
      );

      // Adding the product again should increment quantity on the same item, not duplicate
      controller.addProduct(product1);

      expect(controller.cart, hasLength(1));
      expect(controller.cart.single.product.id, 1);
      expect(controller.cart.single.quantity, 2);
    },
  );
}

class _SavedProductPersonsRepository implements KotGetPersonsRepository {
  @override
  Future<KotGetPersonsResponse> getPersons(int tableId) async {
    return const KotGetPersonsResponse(
      status: true,
      persons: <KotPersonData>[
        KotPersonData(
          personId: 'P1-260918-12',
          personNumber: 1,
          holdOrderIds: <int>[265],
          products: <ProcessingProduct>[
            ProcessingProduct(
              id: 401,
              holdOrderId: 265,
              productId: 1,
              productName: 'Sent snack',
              quantity: 1,
              price: 120,
              unit: '1 pc',
            ),
          ],
        ),
      ],
    );
  }
}
