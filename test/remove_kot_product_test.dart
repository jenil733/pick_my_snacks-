import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/processing_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_product_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/remove_kot_product_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_held_bill_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_processing_order_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('builds the KOT product removal request', () {
    const request = RemoveKotProductRequest(orderId: 12, detailId: 91);

    expect(ApiRoutes.remove, 'kot_hold_remove_product');
    expect(request.toFormFields(), {'order_id': 12, 'detail_id': 91});
  });

  test('parses the remove response and all updated backend totals', () {
    final response = RemoveKotProductResponse.fromJson({
      'status': true,
      'message': 'Product removed',
      'data': {
        'removed_product': {
          'detail_id': 91,
          'product_id': 101,
          'product_name': 'Burger',
          'quantity': '1',
          'row_total': '180.00',
        },
        'remaining_product_count': 1,
        'order': {
          'id': 12,
          'order_id': 'KOT-12',
          'subtotal': '190.00',
          'gst': '9.50',
          'discount': '0.00',
          'charge': '0.00',
          'total': '199.50',
          'products': [],
        },
      },
    });

    expect(response.status, isTrue);
    expect(response.data?.removedProduct?.detailId, 91);
    expect(response.data?.removedProduct?.rowTotal, 180);
    expect(response.data?.remainingProductCount, 1);
    expect(response.data?.order?.subtotal, 190);
    expect(response.data?.order?.gst, 9.5);
    expect(response.data?.order?.total, 199.5);
  });

  test('maps saved product rows to remove API order and detail IDs', () async {
    final removeRepository = _FakeRemoveKotProductRepository();
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
      SaveKotOrderUseCase(_ExactKotOrderRepository()),
      null,
      RemoveKotProductUseCase(removeRepository),
    );
    controller.takeKotTable(1, staffName: 'Staff');
    controller.addProduct(
      const Product(id: 6, name: 'DFGVH', unit: 'kg', price: 45, image: ''),
    );
    controller.addProduct(
      const Product(
        id: 5,
        name: 'MILK RUSK',
        unit: 'pcs',
        price: 50,
        image: '',
      ),
    );

    expect(await controller.saveKitchenOrder(staffId: 1), isTrue);

    final firstReference = controller.cart.first.kotProductReferences.single;
    final secondReference = controller.cart.last.kotProductReferences.single;
    expect(firstReference.orderId, 107);
    expect(firstReference.detailId, 173);
    expect(secondReference.orderId, 107);
    expect(secondReference.detailId, 174);

    expect(await controller.removeKotProduct(controller.cart.last), isTrue);
    expect(removeRepository.requests.single.orderId, 107);
    expect(removeRepository.requests.single.detailId, 174);
  });

  test('removes a sent product without closing its backend order', () async {
    final kotRepository = _FakeKotOrderRepository();
    final removeRepository = _FakeRemoveKotProductRepository();
    final deleteRepository = _FakeDeleteHeldBillRepository();
    final closeRepository = _FakeKotSaveRepository();
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
      SaveKotOrderUseCase(kotRepository),
      SaveKotUseCase(closeRepository),
      RemoveKotProductUseCase(removeRepository),
    );
    const product = Product(
      id: 101,
      name: 'Burger',
      unit: '1pcs',
      price: 180,
      image: '',
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(product);

    expect(await controller.saveKitchenOrder(staffId: 7), isTrue);
    expect(await controller.removeKotProduct(controller.cart.single), isTrue);

    expect(removeRepository.requests, hasLength(1));
    expect(removeRepository.requests.single.orderId, 12);
    expect(removeRepository.requests.single.detailId, 91);
    expect(closeRepository.tableIds, isEmpty);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.cart, isEmpty);
    expect(controller.backendSubtotal.value, isNull);
    expect(controller.backendTotal.value, isNull);
    expect(controller.activeTableNumber.value, 3);
    expect(controller.tableOrders.containsKey(3), isTrue);
  });

  test('does not refresh a missing KOT reference for local removal', () async {
    final removeRepository = _FakeRemoveKotProductRepository();
    final processingRepository = _ReferenceProcessingRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetProcessingOrderUseCase(processingRepository),
      null,
      SaveKotUseCase(_FakeKotSaveRepository()),
      RemoveKotProductUseCase(removeRepository),
    );
    await controller.getProcessingOrder(3);
    controller.continueProcessingOrder();
    final item = controller.cart.single;
    item.kotProductReferences.clear();

    final removed = await controller.removeKotProduct(item);

    expect(removed, isTrue);
    expect(removeRepository.requests, isEmpty);
    expect(processingRepository.tableIds, [3]);
    expect(controller.cart, isEmpty);
  });

  test('backend reference triggers removal even without sent memory', () async {
    final removeRepository = _FakeRemoveKotProductRepository();
    final closeRepository = _FakeKotSaveRepository();
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
      SaveKotUseCase(closeRepository),
      RemoveKotProductUseCase(removeRepository),
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 101,
        name: 'Burger',
        unit: '1pcs',
        price: 180,
        image: '',
      ),
    );
    controller.cart.single.kotProductReferences.add(
      const KotProductReference(orderId: 12, detailId: 91),
    );

    final removed = await controller.removeKotProduct(controller.cart.single);

    expect(removed, isTrue);
    expect(removeRepository.requests, hasLength(1));
    expect(removeRepository.requests.single.orderId, 12);
    expect(removeRepository.requests.single.detailId, 91);
    expect(closeRepository.tableIds, isEmpty);
    expect(controller.activeTableNumber.value, 3);
  });

  test('uses the exact IDs stored in the backend reference', () async {
    final removeRepository = _FakeRemoveKotProductRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetProcessingOrderUseCase(_ReferenceProcessingRepository()),
      null,
      SaveKotUseCase(_FakeKotSaveRepository()),
      RemoveKotProductUseCase(removeRepository),
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 101,
        name: 'Burger',
        unit: '1pcs',
        price: 180,
        image: '',
      ),
    );
    controller.addProduct(
      const Product(id: 202, name: 'Tea', unit: '1pcs', price: 20, image: ''),
    );
    final burger = controller.cart.first;
    burger.kotProductReferences.add(
      const KotProductReference(orderId: 636, detailId: 1180),
    );

    final removed = await controller.removeKotProduct(burger);

    expect(removed, isTrue);
    expect(removeRepository.requests, hasLength(1));
    expect(removeRepository.requests.single.orderId, 636);
    expect(removeRepository.requests.single.detailId, 1180);
  });

  test('keeps the product in the cart when backend removal fails', () async {
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
      RemoveKotProductUseCase(_RejectingRemoveKotProductRepository()),
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(
      const Product(
        id: 101,
        name: 'Burger',
        unit: '1pcs',
        price: 180,
        image: '',
      ),
    );
    controller.cart.single.kotProductReferences.add(
      const KotProductReference(orderId: 107, detailId: 173),
    );

    final removed = await controller.removeKotProduct(controller.cart.single);

    expect(removed, isFalse);
    expect(controller.cart, hasLength(1));
    expect(controller.removeKotProductError.value, 'Product was not removed');
  });

  test('keeps the order ID after removing its last product', () async {
    final deleteRepository = _FakeDeleteHeldBillRepository();
    final closeRepository = _FakeKotSaveRepository();
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
      RemoveKotProductUseCase(_FakeRemoveKotProductRepository()),
    );
    controller.takeKotTable(12, staffName: 'Arun');
    controller.addProduct(
      const Product(id: 6, name: 'DFGVH', unit: 'kg', price: 45, image: ''),
    );
    controller.cart.single.kotProductReferences.add(
      const KotProductReference(orderId: 120, detailId: 190),
    );

    final removed = await controller.removeKotProduct(controller.cart.single);

    expect(removed, isTrue);
    expect(controller.cart, isEmpty);
    expect(controller.activeTableNumber.value, 12);
    expect(controller.tableOrders.containsKey(12), isTrue);
    expect(closeRepository.tableIds, isEmpty);
    expect(deleteRepository.orderIds, isEmpty);
    expect(controller.removeKotProductError.value, isNull);
  });

  test('removing one item does not release a table with other items', () async {
    final removeRepository = _FakeRemoveKotProductRepository();
    final closeRepository = _FakeKotSaveRepository();
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
      SaveKotOrderUseCase(_FakeKotOrderRepository()),
      SaveKotUseCase(closeRepository),
      RemoveKotProductUseCase(removeRepository),
    );
    const burger = Product(
      id: 101,
      name: 'Burger',
      unit: '1pcs',
      price: 180,
      image: '',
    );
    const tea = Product(
      id: 202,
      name: 'Tea',
      unit: '1pcs',
      price: 20,
      image: '',
    );
    controller.takeKotTable(3, staffName: 'Arun');
    controller.addProduct(burger);
    expect(await controller.saveKitchenOrder(staffId: 7), isTrue);
    controller.addProduct(tea);

    final removed = await controller.removeKotProduct(controller.cart.first);

    expect(removed, isTrue);
    expect(controller.cart.single.product.id, 202);
    expect(controller.activeTableNumber.value, 3);
    expect(controller.tableOrders.containsKey(3), isTrue);
    expect(closeRepository.tableIds, isEmpty);
  });
}

class _ReferenceProcessingRepository implements ProcessingOrderRepository {
  final tableIds = <int>[];

  @override
  Future<ProcessingOrderResponse> getProcessingOrder(int tableId) async {
    tableIds.add(tableId);
    return ProcessingOrderResponse(
      status: true,
      data: ProcessingOrderData(
        isProcessing: true,
        table: ProcessingTable(tableId: tableId),
        order: ProcessingOrder(
          orderId: 'KOT-44',
          processingOrderCount: 1,
          processingOrderIds: <int>[44],
          tableId: 3,
          products: tableIds.length <= 2
              ? <ProcessingProduct>[
                  ProcessingProduct(
                    id: 91,
                    holdOrderId: 44,
                    holdOrderNumber: 'KOT-44',
                    productId: 101,
                    productName: 'Burger',
                    quantity: 1,
                    unit: 'pcs',
                  ),
                ]
              : <ProcessingProduct>[],
        ),
      ),
    );
  }
}

class _FakeDeleteHeldBillRepository implements DeleteHeldBillRepository {
  final orderIds = <int>[];

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    orderIds.add(orderId);
    return const DeleteHeldBillResponse(status: true, message: 'Deleted');
  }
}

class _FakeKotSaveRepository implements KotSaveRepository {
  final tableIds = <int>[];

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    tableIds.add(tableId);
    return const KotSaveResponse(status: true, message: 'Bill closed');
  }
}

class _FakeKotOrderRepository implements KotOrderRepository {
  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    return const KotOrderResponse(
      status: true,
      data: KotOrderData(
        table: KotTable(id: 1, tableId: 3, isActive: true),
        order: KotOrder(
          orderId: 'KOT-12',
          tableId: 3,
          products: <KotProduct>[
            KotProduct(id: 91, orderId: 12, productId: 101, quantity: 1),
          ],
        ),
      ),
    );
  }
}

class _ExactKotOrderRepository implements KotOrderRepository {
  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    return KotOrderResponse.fromJson({
      'status': true,
      'message': 'KOT order saved successfully.',
      'data': {
        'is_processing': 1,
        'table': {'id': 9, 'table_id': 1, 'branch_id': 4, 'is_active': 1},
        'order': {
          'id': 107,
          'order_id': 'KOT10012',
          'table_id': 1,
          'products': [
            {
              'id': 173,
              'order_id': 107,
              'product_id': 6,
              'product_name': 'DFGVH',
              'quantity': '2',
              'unit_value': '2',
              'unit': 'kg',
            },
            {
              'id': 174,
              'order_id': 107,
              'product_id': 5,
              'product_name': 'MILK RUSK',
              'quantity': '2',
              'unit_value': '2',
              'unit': 'pcs',
            },
          ],
        },
      },
    });
  }
}

class _FakeRemoveKotProductRepository implements RemoveKotProductRepository {
  final requests = <RemoveKotProductRequest>[];

  @override
  Future<RemoveKotProductResponse> removeKotProduct(
    RemoveKotProductRequest request,
  ) async {
    requests.add(request);
    return const RemoveKotProductResponse(
      status: true,
      message: 'Product removed',
      data: RemoveKotProductData(
        remainingProductCount: 0,
        order: RemoveKotOrder(
          id: 12,
          subtotal: 0,
          gst: 0,
          discount: 0,
          charge: 0,
          total: 0,
        ),
      ),
    );
  }
}

class _RejectingRemoveKotProductRepository
    implements RemoveKotProductRepository {
  @override
  Future<RemoveKotProductResponse> removeKotProduct(
    RemoveKotProductRequest request,
  ) async {
    return const RemoveKotProductResponse(
      status: false,
      message: 'Product was not removed',
    );
  }
}
