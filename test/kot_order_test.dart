import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/core/utils/helper/app_toast.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/get_staff.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_quantity_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_quantity_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/staff/staff_controller.dart';
import 'package:pick_my_snacks/src/presentation/widgets/homescreen/bill_summary_panel.dart';

void main() {
  test('builds the KOT request with table, staff, and product fields', () {
    const request = KotOrderRequest(
      tableId: 4,
      staffId: 7,
      paymentMode: 'cash',
      products: [
        SaveOrderProductRequest(productId: 10, quantity: 2, note: 'extra salt'),
      ],
    );

    final fields = request.toFormFields();

    expect(fields['table_id'], 4);
    expect(fields['staff_id'], 7);
    expect(fields['payment_mode'], 'cash');
    expect(fields['discount_type'], 'none');
    expect(fields['is_kot'], 1);
    expect(fields['products[0][is_kot]'], 1);
    expect(fields['products[0][qty]'], '2pcs');
    expect(fields['products[0][note]'], 'extra salt');
  });

  test('Kitchen Bill sends only items added since the previous send', () async {
    final repository = _FakeKotOrderRepository();
    final normalRepository = _FakeOrderRepository();
    final deleteRepository = _FakeDeleteHeldBillRepository();
    final quantityRepository = _FakeRemoveKotQuantityRepository();
    final controller = HomeController(
      null,
      SaveOrderUseCase(normalRepository),
      null,
      null,
      null,
      DeleteHeldBillUseCase(deleteRepository),
      null,
      null,
      null,
      SaveKotOrderUseCase(repository),
      null,
      null,
      RemoveKotQuantityUseCase(quantityRepository),
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 101,
        productId: 'P101',
        name: 'Veg Sandwich',
        unit: 'pc',
        price: 80,
        image: '',
      ),
    );
    controller.updateItemNotes(controller.cart.single, 'extra salt');
    expect(controller.submittedKitchenTables.contains(3), isFalse);

    final saved = await controller.saveKitchenOrder(staffId: 7);

    expect(saved, isTrue);
    expect(controller.submittedKitchenTables.contains(3), isTrue);
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.tableId, 3);
    expect(repository.requests.single.staffId, 7);
    expect(repository.requests.single.products.single.productId, 101);
    expect(repository.requests.single.products.single.note, 'extra salt');
    expect(controller.savedOrderNumber.value, 'KOT-12');
    expect(controller.kotOrderError.value, isNull);
    expect(controller.lastKitchenOrderItems.single.product.id, 101);

    controller.confirmKitchenOrderPrinted();
    controller.addProduct(
      const Product(
        id: 202,
        productId: 'P202',
        name: 'Tea',
        unit: 'cup',
        price: 20,
        image: '',
      ),
    );

    final secondSaved = await controller.saveKitchenOrder(staffId: 7);

    expect(secondSaved, isTrue);
    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.products, hasLength(1));
    expect(repository.requests.last.products.single.productId, 202);
    expect(controller.lastKitchenOrderItems.single.product.id, 202);
    expect(controller.cart, hasLength(2));
    expect(controller.subtotal, 100);

    controller.confirmKitchenOrderPrinted();
    final duplicateSaved = await controller.saveKitchenOrder(staffId: 7);

    expect(duplicateSaved, isFalse);
    expect(repository.requests, hasLength(2));
    expect(controller.kotOrderError.value, 'No new kitchen items to send.');
    expect(normalRepository.requests, isEmpty);

    controller.tableStatuses[3] = const TableStatusData(
      tableId: 3,
      tableStatus: 'Occupied',
      isOccupied: 1,
    );
    final deleted = await controller.deleteActiveKotOrder();

    expect(deleted, isTrue);
    expect(deleteRepository.orderIds, isEmpty);
    expect(quantityRepository.requests, isEmpty);
    expect(controller.cart, isEmpty);
    expect(controller.tableOrders.containsKey(3), isFalse);
    expect(controller.submittedKitchenTables.contains(3), isFalse);
    expect(controller.tableStatuses[3]?.occupied ?? false, isFalse);
    expect(controller.activeTableNumber.value, isNull);
    expect(controller.kotStage.value, KotStage.tables);
  });

  test(
    'saves a new Kitchen Bill item while an earlier print is pending',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      const firstProduct = Product(
        id: 101,
        name: 'Naan',
        unit: 'pcs',
        price: 50,
        image: '',
      );
      const secondProduct = Product(
        id: 202,
        name: 'Tea',
        unit: 'pcs',
        price: 20,
        image: '',
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(firstProduct);
      controller.setKitchenItemSelected(controller.cart.single, true);

      expect(
        await controller.saveKitchenOrder(staffId: 7, selectedOnly: true),
        isTrue,
      );
      expect(controller.hasKitchenOrderAwaitingPrint, isTrue);

      controller.addProduct(secondProduct);
      controller.setKitchenItemSelected(controller.cart.last, true);
      expect(controller.hasSelectedPendingKitchenItems, isTrue);

      expect(
        await controller.saveKitchenOrder(staffId: 7, selectedOnly: true),
        isTrue,
      );
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.products.single.productId, 202);
      expect(controller.lastKitchenOrderItems.map((item) => item.product.id), [
        101,
        202,
      ]);
    },
  );

  test(
    'same KOT product can be manually selected after holding the table',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      const product = Product(
        id: 101,
        productId: 'P101',
        name: 'Veg Sandwich',
        unit: 'pc',
        price: 80,
        image: '',
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(product);
      expect(controller.kitchenSelectedItems, isEmpty);
      controller.setKitchenItemSelected(controller.cart.single, true);

      expect(
        await controller.saveKitchenOrder(staffId: 7, selectedOnly: true),
        isTrue,
      );
      controller.confirmKitchenOrderPrinted();
      expect(await controller.holdActiveKotTable(staffId: 7), isTrue);
      controller.continueKotTable(3);

      controller.addProduct(product);

      final pendingItem = controller.cart.last;
      expect(controller.isKitchenItemSelected(pendingItem), isFalse);
      controller.setKitchenItemSelected(pendingItem, true);
      expect(controller.selectedPendingKitchenItems, hasLength(1));
      expect(controller.selectedPendingKitchenItems.single.quantity, 1);
      expect(
        await controller.saveKitchenOrder(staffId: 7, selectedOnly: true),
        isTrue,
      );
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.products.single.productId, 101);
      expect(repository.requests.last.products.single.quantity, 1);
    },
  );

  test(
    'closing a KOT sends products left out of the selected Kitchen Bill',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(
        const Product(
          id: 101,
          productId: 'P101',
          name: 'Tea',
          unit: 'pcs',
          price: 15,
          image: '',
        ),
      );
      controller.addProduct(
        const Product(
          id: 202,
          productId: 'P202',
          name: 'Unselected item',
          unit: 'pcs',
          price: 50,
          image: '',
        ),
      );
      controller.setKitchenItemSelected(controller.cart.first, true);

      expect(
        await controller.saveKitchenOrder(staffId: 7, selectedOnly: true),
        isTrue,
      );
      expect(repository.requests.single.products.single.productId, 101);
      expect(controller.pendingKitchenItems, hasLength(1));

      expect(await controller.prepareKotOrderForCompletion(staffId: 7), isTrue);

      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.products, hasLength(1));
      expect(repository.requests.last.products.single.productId, 202);
      expect(controller.pendingKitchenItems, isEmpty);
    },
  );

  test('deletes a KOT from local state without remove APIs', () async {
    final deleteRepository = _FakeDeleteHeldBillRepository();
    final quantityRepository = _FakeRemoveKotQuantityRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      DeleteHeldBillUseCase(deleteRepository),
      null,
      null,
      null,
      null,
      null,
      null,
      RemoveKotQuantityUseCase(quantityRepository),
    );
    controller.activeTableNumber.value = 5;
    controller.submittedKitchenTables.add(5);
    controller.processingOrders[5] = const ProcessingOrderData(
      order: ProcessingOrder(
        id: 77,
        tableId: 5,
        products: <ProcessingProduct>[
          ProcessingProduct(
            id: 91,
            holdOrderId: 77,
            productId: 101,
            quantity: 1,
          ),
        ],
      ),
    );
    controller.cart.add(
      CartItem(
        product: const Product(
          id: 101,
          name: 'Veg Sandwich',
          unit: 'pc',
          price: 80,
          image: '',
        ),
      ),
    );

    final deleted = await controller.deleteActiveKotOrder();

    expect(deleted, isTrue);
    expect(deleteRepository.orderIds, isEmpty);
    expect(quantityRepository.requests, isEmpty);
    expect(controller.cart, isEmpty);
    expect(controller.activeTableNumber.value, isNull);
    expect(controller.kotStage.value, KotStage.tables);
  });

  test(
    'saves pending KOT items for billing without requesting a kitchen print',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(
        const Product(
          id: 101,
          productId: 'P101',
          name: 'Veg Sandwich',
          unit: 'pc',
          price: 80,
          image: '',
        ),
      );

      final saved = await controller.saveKitchenOrder(
        staffId: 7,
        prepareForKitchenPrint: false,
      );

      expect(saved, isTrue);
      expect(repository.requests, hasLength(1));
      expect(controller.submittedKitchenTables, contains(3));
      expect(controller.pendingKitchenItems, isEmpty);
      expect(controller.hasKitchenOrderAwaitingPrint, isFalse);
      expect(controller.lastKitchenOrderItems, isEmpty);
    },
  );

  testWidgets('Close Bill saves new products without sending a Kitchen Bill', (
    tester,
  ) async {
    Get.testMode = true;
    final staffController = Get.put(StaffController());
    staffController.selectedStaff.value = const StaffData(id: 7, name: 'Arun');
    final kitchenRepository = _FakeKotOrderRepository();
    final closeRepository = _TrackingKotSaveRepository();
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
      SaveKotOrderUseCase(kitchenRepository),
      SaveKotUseCase(closeRepository),
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.isCustomerDetailsPrompted.value = true;
    controller.addProduct(
      const Product(
        id: 101,
        productId: 'P101',
        name: 'Naan',
        unit: 'pcs',
        price: 50,
        image: '',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => closeKotBill(context, controller),
            child: const Text('Close Bill'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Close Bill'));
    await tester.pumpAndSettle();

    expect(kitchenRepository.requests, hasLength(1));
    expect(kitchenRepository.requests.single.products.single.productId, 101);
    expect(controller.hasKitchenOrderAwaitingPrint, isFalse);
    expect(controller.lastKitchenOrderItems, isEmpty);
    expect(closeRepository.tableIds, <int>[3]);
    AppToast.dismiss();
    Get.reset();
  });

  test(
    'holds a KOT table as occupied without requesting a kitchen print',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(
        const Product(
          id: 101,
          productId: 'P101',
          name: 'Veg Sandwich',
          unit: 'pc',
          price: 80,
          image: '',
        ),
      );

      final held = await controller.holdActiveKotTable(staffId: 7);

      expect(held, isTrue);
      expect(repository.requests, hasLength(1));
      expect(controller.tableStatuses[3]?.occupied, isTrue);
      expect(controller.submittedKitchenTables, contains(3));
      expect(controller.tableOrders[3]?.itemCount, 1);
      expect(controller.cart, hasLength(1));
      expect(controller.activeTableNumber.value, 3);
      expect(controller.kotStage.value, KotStage.tables);
      expect(controller.hasKitchenOrderAwaitingPrint, isFalse);
    },
  );

  test(
    'keeps different QR weights of the same product as separate KOT lines',
    () async {
      final repository = _FakeKotOrderRepository();
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
        SaveKotOrderUseCase(repository),
      );
      controller.products.add(
        const Product(
          id: 1,
          productId: '0001',
          name: 'Mixture',
          unit: 'kg',
          price: 200,
          image: '',
        ),
      );
      controller.takeKotTable(3, staffName: 'Arun');

      controller.addProductFromQr('000190250');
      controller.addProductFromQr('000190500');

      expect(controller.cart, hasLength(2));
      expect(
        controller.cart.map((item) => item.scannedWeightCode),
        containsAll(<String>['0250', '0500']),
      );

      final saved = await controller.saveKitchenOrder(staffId: 7);

      expect(saved, isTrue);
      expect(repository.requests.single.products, hasLength(2));
      expect(
        repository.requests.single.products.map((item) => item.productId),
        everyElement(1),
      );
      expect(
        repository.requests.single.products.map((item) => item.quantity),
        containsAll(<num>[0.25, 0.5]),
      );
      expect(controller.lastKitchenOrderItems, hasLength(2));

      controller.confirmKitchenOrderPrinted();
      controller.addProductFromQr('000190750');
      final nextSaved = await controller.saveKitchenOrder(staffId: 7);

      expect(nextSaved, isTrue);
      expect(repository.requests, hasLength(2));
      expect(repository.requests.last.products, hasLength(1));
      expect(repository.requests.last.products.single.quantity, 0.75);
    },
  );

  test('does not use hold-bill deletion to reconcile an edited KOT', () async {
    final repository = _FakeKotOrderRepository();
    final deleteRepository = _FakeDeleteHeldBillRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      DeleteHeldBillUseCase(deleteRepository),
      null,
      null,
      null,
      SaveKotOrderUseCase(repository),
    );
    const product = Product(
      id: 101,
      productId: 'P101',
      name: 'Chicken Patty Burger',
      unit: '1pcs',
      price: 180,
      image: '',
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(product);
    expect(await controller.saveKitchenOrder(staffId: 7), isTrue);
    controller.confirmKitchenOrderPrinted();

    controller.remove(controller.cart.single);
    controller.addProduct(product);

    expect(controller.pendingKitchenItems, hasLength(1));
    expect(controller.pendingKitchenItems.single.quantity, 1);
    expect(await controller.reconcileEditedKotOrder(staffId: 7), isFalse);
    expect(deleteRepository.orderIds, isEmpty);
    expect(repository.requests, hasLength(1));
    expect(controller.kotOrderError.value, contains('unsynchronized edit'));
  });

  test('never calls delete_hold_bill during KOT reconciliation', () async {
    final repository = _FakeKotOrderRepository();
    final deleteRepository = _MissingKotHoldRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      DeleteHeldBillUseCase(deleteRepository),
      null,
      null,
      null,
      SaveKotOrderUseCase(repository),
    );
    const product = Product(
      id: 101,
      productId: 'P101',
      name: 'Chicken Patty Burger',
      unit: '1pcs',
      price: 180,
      image: '',
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(product);
    expect(await controller.saveKitchenOrder(staffId: 7), isTrue);
    controller.confirmKitchenOrderPrinted();
    controller.remove(controller.cart.single);
    controller.addProduct(product);

    final reconciled = await controller.reconcileEditedKotOrder(staffId: 7);

    expect(reconciled, isFalse);
    expect(deleteRepository.orderIds, isEmpty);
    expect(repository.requests, hasLength(1));
    expect(controller.kotOrderError.value, contains('unsynchronized edit'));
  });
}

class _MissingKotHoldRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    return const DeleteHeldBillResponse(
      status: false,
      message: 'Hold bill not found.',
    );
  }
}

class _FakeDeleteHeldBillRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    return const DeleteHeldBillResponse(status: true);
  }
}

class _FakeOrderRepository implements OrderRepository {
  final requests = <SaveOrderRequest>[];

  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    requests.add(request);
    return const SaveOrderResponse(status: true);
  }
}

class _FakeKotOrderRepository implements KotOrderRepository {
  final requests = <KotOrderRequest>[];

  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    requests.add(request);
    final orderId = 11 + requests.length;
    final detailId = 90 + requests.length;
    return KotOrderResponse(
      status: true,
      data: KotOrderData(
        table: const KotTable(id: 1, tableId: 3, isActive: true),
        order: KotOrder(
          id: orderId,
          orderId: 'KOT-$orderId',
          tableId: 3,
          staffId: 7,
          subtotal: 80,
          gst: 4,
          total: 84,
          products: <KotProduct>[
            for (final product in request.products)
              KotProduct(
                id: detailId,
                orderId: orderId,
                productId: product.productId,
                quantity: product.quantity.round(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackingKotSaveRepository implements KotSaveRepository {
  final tableIds = <int>[];

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    tableIds.add(tableId);
    return KotSaveResponse(
      status: true,
      data: KotSaveData(
        completedOrder: KotCompletedOrder(
          id: 20,
          orderId: 'ORD-20',
          tableId: tableId,
          subtotal: 50,
          gst: 0,
          total: 50,
          products: const <KotSavedProduct>[
            KotSavedProduct(
              id: 1,
              productId: 101,
              productName: 'Naan',
              price: 50,
              quantity: 1,
              rowTotal: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeRemoveKotQuantityRepository implements RemoveKotQuantityRepository {
  final requests = <RemoveKotQuantityRequest>[];

  @override
  Future<RemoveKotQuantityResponse> removeKotQuantity(
    RemoveKotQuantityRequest request,
  ) async {
    requests.add(request);
    return const RemoveKotQuantityResponse(
      status: true,
      message: 'Quantity removed',
    );
  }
}
