import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('builds a table-specific KOT completion endpoint', () {
    expect(ApiRoutes.kotSave(4), 'kot_save_order/4');
    expect(ApiRoutes.kotSave(9), 'kot_save_order/9');
  });

  test('parses and completes the selected table KOT order', () async {
    final response = KotSaveResponse.fromJson({
      'status': true,
      'message': 'KOT completed',
      'data': {
        'is_processing': 0,
        'table': {'id': '2', 'table_id': '4', 'branch_id': 1},
        'completed_hold_order_ids': ['10', 11],
        'completed_hold_order_count': '2',
        'completed_order': {
          'id': 20,
          'order_id': 'ORD-20',
          'table_id': 4,
          'subtotal': '100.00',
          'gst': '5.00',
          'total': '105.00',
          'status': 'completed',
          'products': [
            {
              'id': 1,
              'product_id': 8,
              'product_name': 'Tea',
              'quantity': '2pcs',
              'price': '52.50',
              'unit_value': '1.00',
              'unit': 'pcs',
              'row_total': '105.00',
              'is_kot': '1',
            },
          ],
        },
      },
    });
    final repository = _FakeKotSaveRepository(response);
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
      SaveKotUseCase(repository),
    );
    controller.takeKotTable(4, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 8,
        productId: 'P8',
        name: 'Tea',
        unit: 'cup',
        price: 50,
        image: '',
      ),
    );
    controller.tableStatuses[4] = const TableStatusData(
      tableId: 4,
      tableStatus: 'Occupied',
      isOccupied: 1,
    );

    final completed = await controller.completeKotOrder();

    expect(completed, isTrue);
    expect(repository.tableIds, [4]);
    expect(controller.completedKotOrder.value?.isProcessing, isFalse);
    expect(controller.completedKotOrder.value?.completedHoldOrderIds, [10, 11]);
    expect(controller.completedKotOrder.value?.completedHoldOrderCount, 2);
    expect(controller.savedOrderNumber.value, 'ORD-20');
    expect(controller.backendTotal.value, 105);
    expect(controller.completedReceiptItems.single.product.price, 52.50);
    expect(controller.completedReceiptItems.single.quantity, 2);
    expect(controller.completedReceiptItems.single.displayUnit, '1pcs');
    expect(controller.completedReceiptItems.single.total, 105);

    controller.finishCompletedKotOrder();

    expect(controller.cart, isEmpty);
    expect(controller.tableOrders.containsKey(4), isFalse);
    expect(controller.tableStatuses[4]?.occupied ?? false, isFalse);
    expect(controller.deletedKitchenTables, contains(4));
    expect(controller.activeTableNumber.value, isNull);
    expect(controller.kotStage.value, KotStage.tables);
  });

  test(
    'keeps earlier kitchen items on the bill when close returns only the latest hold',
    () async {
      final kitchenRepository = _SequentialKotOrderRepository();
      final closeRepository = _FakeKotSaveRepository(
        const KotSaveResponse(
          status: true,
          data: KotSaveData(
            completedOrder: KotCompletedOrder(
              id: 20,
              orderId: 'ORD-20',
              tableId: 4,
              subtotal: 80,
              gst: 0,
              total: 80,
              products: <KotSavedProduct>[
                KotSavedProduct(
                  id: 2,
                  productId: 9,
                  productName: 'Coffee',
                  price: 30,
                  quantity: 1,
                  rowTotal: 30,
                ),
              ],
            ),
          ),
        ),
      );
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
      controller.takeKotTable(4, staffName: 'Arun');
      controller.addProduct(
        const Product(id: 8, name: 'Tea', unit: 'cup', price: 50, image: ''),
      );
      expect(await controller.saveKitchenOrder(staffId: 7), isTrue);
      controller.confirmKitchenOrderPrinted();

      controller.addProduct(
        const Product(id: 9, name: 'Coffee', unit: 'cup', price: 30, image: ''),
      );
      expect(
        await controller.saveKitchenOrder(
          staffId: 7,
          prepareForKitchenPrint: false,
        ),
        isTrue,
      );
      expect(await controller.completeKotOrder(staffId: 7), isTrue);

      expect(
        controller.completedReceiptItems.map((item) => item.product.name),
        containsAll(<String>['Tea', 'Coffee']),
      );
      expect(controller.completedReceiptItems, hasLength(2));
    },
  );

  test('does not send an empty KOT hold to regular hold deletion', () async {
    const completedResponse = KotSaveResponse(
      status: true,
      data: KotSaveData(
        completedOrder: KotCompletedOrder(
          id: 20,
          orderId: 'ORD-20',
          tableId: 4,
          subtotal: 100,
          gst: 5,
          total: 105,
          products: <KotSavedProduct>[
            KotSavedProduct(
              id: 1,
              productId: 8,
              productName: 'Tea',
              price: 50,
              quantity: 2,
              rowTotal: 100,
            ),
          ],
        ),
      ),
    );
    final repository = _RecoveringKotSaveRepository(completedResponse);
    final deleteRepository = _FakeEmptyHoldDeleteRepository();
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
      SaveKotUseCase(repository),
    );
    controller.takeKotTable(4, staffName: 'Arun');

    expect(await controller.completeKotOrder(), isFalse);
    expect(repository.callCount, 1);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.completeKotOrderError.value, contains('no products'));
  });

  test('recreates a missing KOT hold before closing the table bill', () async {
    final kotOrderRepository = _RecreatedKotOrderRepository();
    final closeRepository = _MissingThenClosingKotRepository();
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
      SaveKotOrderUseCase(kotOrderRepository),
      SaveKotUseCase(closeRepository),
    );
    controller.takeKotTable(4, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 8,
        productId: 'P8',
        name: 'Tea',
        unit: 'cup',
        price: 50,
        image: '',
      ),
    );

    final completed = await controller.completeKotOrder(staffId: 7);

    expect(completed, isTrue);
    expect(closeRepository.callCount, 2);
    expect(kotOrderRepository.requests, hasLength(1));
    expect(kotOrderRepository.requests.single.tableId, 4);
    expect(controller.completeKotOrderError.value, isNull);
  });

  test('reports a backend failure when empty-hold deletion fails', () async {
    const completedResponse = KotSaveResponse(
      status: true,
      data: KotSaveData(
        completedOrder: KotCompletedOrder(
          id: 20,
          orderId: 'ORD-20',
          tableId: 10,
          subtotal: 150,
          gst: 0,
          total: 150,
          products: <KotSavedProduct>[
            KotSavedProduct(
              id: 1,
              productId: 8,
              productName: 'Tea',
              price: 150,
              quantity: 1,
              rowTotal: 150,
            ),
          ],
        ),
      ),
    );
    final closeRepository = _RecoveringKotSaveRepository(completedResponse);
    final deleteRepository = _ThrowingEmptyHoldDeleteRepository();
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
      SaveKotUseCase(closeRepository),
    );
    controller.takeKotTable(10, staffName: 'Arun');

    final completed = await controller.completeKotOrder();

    expect(completed, isFalse);
    expect(closeRepository.callCount, 1);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.completeKotOrderError.value, isNotEmpty);
  });

  test(
    'reports that delete_hold_bill cannot delete a KOT processing hold',
    () async {
      const completedResponse = KotSaveResponse(
        status: true,
        data: KotSaveData(
          completedOrder: KotCompletedOrder(
            id: 20,
            orderId: 'ORD-20',
            tableId: 6,
            subtotal: 50,
            gst: 0,
            total: 50,
            products: <KotSavedProduct>[
              KotSavedProduct(
                id: 1,
                productId: 8,
                productName: 'Tea',
                price: 50,
                quantity: 1,
                rowTotal: 50,
              ),
            ],
          ),
        ),
      );
      final closeRepository = _RecoveringKotSaveRepository(completedResponse);
      final deleteRepository = _MissingEmptyHoldDeleteRepository();
      final kotOrderRepository = _RecreatedKotOrderRepository();
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
        SaveKotOrderUseCase(kotOrderRepository),
        SaveKotUseCase(closeRepository),
      );
      controller.takeKotTable(6, staffName: 'Arun');
      controller.addProduct(
        const Product(
          id: 8,
          productId: 'P8',
          name: 'Tea',
          unit: 'cup',
          price: 50,
          image: '',
        ),
      );

      final completed = await controller.completeKotOrder(staffId: 7);

      expect(completed, isFalse);
      expect(closeRepository.callCount, 1);
      expect(deleteRepository.orderIds, isEmpty);
      expect(kotOrderRepository.requests, isEmpty);
      expect(controller.completeKotOrderError.value, contains('no products'));
    },
  );

  test('does not retry KOT close through regular hold deletion', () async {
    final closeRepository = _MultipleEmptyKotRepository();
    final deleteRepository = _FakeEmptyHoldDeleteRepository();
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
      SaveKotUseCase(closeRepository),
    );
    controller.takeKotTable(6, staffName: 'Arun');

    final completed = await controller.completeKotOrder();

    expect(completed, isFalse);
    expect(closeRepository.callCount, 1);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.completeKotOrderError.value, contains('no products'));
  });

  test(
    'keeps an empty table occupied when backend rejects KOT close',
    () async {
      final closeRepository = _RepeatedEmptyKotRepository();
      final deleteRepository = _MissingEmptyHoldDeleteRepository();
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
        SaveKotUseCase(closeRepository),
      );
      controller.takeKotTable(12, staffName: 'Arun');
      controller.tableStatuses[12] = const TableStatusData(
        tableId: 12,
        tableStatus: 'Occupied',
        isOccupied: 1,
      );

      final closed = await controller.closeEmptyKotTable(12);

      expect(closed, isFalse);
      expect(closeRepository.callCount, 1);
      expect(deleteRepository.orderIds, isEmpty);
      expect(controller.tableStatuses[12]?.occupied, isTrue);
      expect(controller.activeTableNumber.value, 12);
      expect(controller.kotStage.value, KotStage.order);
    },
  );

  test(
    'does not create a regular bill when KOT close returns an empty hold',
    () async {
      final closeRepository = _RepeatedEmptyKotRepository();
      final deleteRepository = _MissingEmptyHoldDeleteRepository();
      final orderRepository = _FallbackOrderRepository();
      final controller = HomeController(
        null,
        SaveOrderUseCase(orderRepository),
        null,
        null,
        null,
        DeleteHeldBillUseCase(deleteRepository),
        null,
        null,
        null,
        null,
        SaveKotUseCase(closeRepository),
      );
      controller.takeKotTable(3, staffName: 'Arun');
      controller.addProduct(
        const Product(
          id: 8,
          productId: 'P8',
          name: 'Tea',
          unit: 'cup',
          price: 50,
          image: '',
        ),
      );

      final completed = await controller.completeKotOrder(staffId: 7);

      expect(completed, isFalse);
      expect(closeRepository.callCount, 1);
      expect(deleteRepository.orderIds, isEmpty);
      expect(orderRepository.requests, isEmpty);
      expect(controller.savedOrderNumber.value, isNull);
      expect(controller.completeKotOrderError.value, contains('no products'));
      expect(controller.deletedKitchenTables, isNot(contains(3)));
      expect(controller.activeTableNumber.value, 3);
    },
  );

  test('frees the table when KOT removal already discarded its hold', () async {
    final closeRepository = _MissingThenClosingKotRepository();
    final deleteRepository = _FakeEmptyHoldDeleteRepository();
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
      SaveKotUseCase(closeRepository),
    );
    controller.tableStatuses[6] = const TableStatusData(
      tableId: 6,
      tableStatus: 'Occupied',
      isOccupied: 1,
    );

    final closed = await controller.closeEmptyKotTable(6);

    expect(closed, isTrue);
    expect(closeRepository.callCount, 1);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.tableStatuses[6], isNull);
    expect(controller.deletedKitchenTables, contains(6));
  });
}

class _MultipleEmptyKotRepository implements KotSaveRepository {
  int callCount = 0;
  final emptyHoldIds = const <int>[82, 83, 84];

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    final request = RequestOptions(path: ApiRoutes.kotSave(tableId));
    if (callCount < emptyHoldIds.length) {
      final holdOrderId = emptyHoldIds[callCount++];
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 422,
          data: {
            'status': false,
            'message': 'One of the processing orders has no products.',
            'data': {
              'hold_order_id': holdOrderId,
              'order_id': 'KOT-$holdOrderId',
            },
          },
        ),
      );
    }
    callCount++;
    return KotSaveResponse(
      status: true,
      data: KotSaveData(
        completedOrder: KotCompletedOrder(
          id: 20,
          orderId: 'ORD-20',
          tableId: tableId,
          subtotal: 620,
          gst: 0,
          total: 620,
          products: const <KotSavedProduct>[],
        ),
      ),
    );
  }
}

class _RepeatedEmptyKotRepository implements KotSaveRepository {
  int callCount = 0;

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    callCount++;
    final request = RequestOptions(path: ApiRoutes.kotSave(tableId));
    throw DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 422,
        data: const {
          'status': false,
          'message': 'One of the processing orders has no products.',
          'data': {'hold_order_id': 81, 'order_id': 'KOT-81'},
        },
      ),
    );
  }
}

class _RecreatedKotOrderRepository implements KotOrderRepository {
  final requests = <KotOrderRequest>[];

  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    requests.add(request);
    return const KotOrderResponse(
      status: true,
      data: KotOrderData(
        order: KotOrder(
          id: 88,
          orderId: 'KOT-88',
          tableId: 4,
          products: <KotProduct>[
            KotProduct(id: 1, orderId: 88, productId: 8, quantity: 1),
          ],
        ),
      ),
    );
  }
}

class _MissingThenClosingKotRepository implements KotSaveRepository {
  int callCount = 0;

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    callCount++;
    if (callCount == 1) {
      final request = RequestOptions(path: ApiRoutes.kotSave(tableId));
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 404,
          data: const {'status': false, 'message': 'Hold bill not found.'},
        ),
      );
    }
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
              productId: 8,
              productName: 'Tea',
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

class _FakeKotSaveRepository implements KotSaveRepository {
  _FakeKotSaveRepository(this.response);

  final KotSaveResponse response;
  final tableIds = <int>[];

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    tableIds.add(tableId);
    return response;
  }
}

class _SequentialKotOrderRepository implements KotOrderRepository {
  int _nextOrderId = 80;

  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    final orderId = _nextOrderId++;
    return KotOrderResponse(
      status: true,
      data: KotOrderData(
        order: KotOrder(
          id: orderId,
          orderId: 'KOT-$orderId',
          tableId: request.tableId,
          products: request.products
              .map(
                (product) => KotProduct(
                  id: product.productId,
                  orderId: orderId,
                  productId: product.productId,
                  quantity: product.quantity.toInt(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _RecoveringKotSaveRepository implements KotSaveRepository {
  _RecoveringKotSaveRepository(this.response);

  final KotSaveResponse response;
  int callCount = 0;

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    callCount++;
    if (callCount == 1) {
      final request = RequestOptions(path: ApiRoutes.kotSave(tableId));
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 422,
          data: {
            'status': false,
            'message': 'One of the processing orders has no products.',
            'data': {'hold_order_id': 65, 'order_id': 'KOT202608011110046'},
          },
        ),
      );
    }
    return response;
  }
}

class _FakeEmptyHoldDeleteRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    return const DeleteHeldBillResponse(status: true, message: 'Deleted');
  }
}

class _ThrowingEmptyHoldDeleteRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    final request = RequestOptions(path: ApiRoutes.deleteHoldBill(orderId));
    throw DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 422,
        data: {
          'status': false,
          'message': 'One of the processing orders has no products.',
          'data': {'hold_order_id': orderId, 'order_id': 'KOT-EMPTY'},
        },
      ),
    );
  }
}

class _MissingEmptyHoldDeleteRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    final request = RequestOptions(path: ApiRoutes.deleteHoldBill(orderId));
    throw DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 404,
        data: const {'status': false, 'message': 'Hold bill not found.'},
      ),
    );
  }
}

class _FallbackOrderRepository implements OrderRepository {
  final requests = <SaveOrderRequest>[];

  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    requests.add(request);
    return const SaveOrderResponse(
      status: true,
      data: SaveOrderData(
        order: SavedOrder(
          id: 901,
          orderId: 'ORD-FALLBACK',
          branchId: 1,
          staffId: '7',
          subtotal: 50,
          gst: 0,
          total: 50,
          paymentMode: 'cash',
          status: 'completed',
          products: <SavedOrderProduct>[
            SavedOrderProduct(
              id: 902,
              orderId: 901,
              productId: 8,
              productName: 'Tea',
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
