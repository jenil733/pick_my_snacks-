import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/processing_order_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_processing_order_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_table_status_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/save_kot_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  test('builds a table-specific processing-order endpoint', () {
    expect(ApiRoutes.processingOrder(12), 'get_processing_order/12');
    expect(ApiRoutes.processingOrder(4), 'get_processing_order/4');
  });

  test('parses aggregated KOT hold IDs and product hold references', () {
    final response = ProcessingOrderResponse.fromJson({
      'status': true,
      'data': {
        'is_processing': true,
        'order': {
          'table_id': 6,
          'processing_order_count': 5,
          'processing_order_ids': [82, 83, 84, 85, 86],
          'processing_order_numbers': [
            'KOT10004',
            'KOT10005',
            'KOT10006',
            'KOT10007',
            'KOT10008',
          ],
          'products': [
            {
              'id': 133,
              'hold_order_id': 85,
              'hold_order_number': 'KOT10007',
              'product_id': 7,
              'quantity': 1,
            },
          ],
        },
      },
    });

    final order = response.data!.order!;
    expect(order.id, isNull);
    expect(order.processingOrderCount, 5);
    expect(order.processingOrderIds, [82, 83, 84, 85, 86]);
    expect(order.processingOrderNumbers.last, 'KOT10008');
    expect(order.products!.single.holdOrderId, 85);
    expect(order.products!.single.holdOrderNumber, 'KOT10007');
  });

  test(
    'keeps the status API occupied state when order details are empty',
    () async {
      final response = ProcessingOrderResponse.fromJson({
        'status': false,
        'message': 'No processing orders found for this table.',
        'data': {'table_id': 8, 'is_processing': 0},
      });
      final controller = HomeController(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        GetTableStatusUseCase(_OccupiedStatusRepository()),
        GetProcessingOrderUseCase(_ProcessingRepository(response)),
      );

      await controller.getTableStatuses();

      expect(response.data?.isProcessing, isFalse);
      expect(controller.tableStatuses[8]?.occupied, isTrue);
      expect(controller.processingOrders.containsKey(8), isFalse);
      expect(controller.tableStatusError.value, isNull);
    },
  );

  test('parses and restores a processing table order', () async {
    final response = ProcessingOrderResponse.fromJson({
      'status': true,
      'message': 'Processing order loaded',
      'data': {
        'is_processing': true,
        'table': {'id': 2, 'table_id': 8, 'branch_id': 1, 'is_active': true},
        'order': {
          'id': 55,
          'order_id': 'ORD-55',
          'table_id': 8,
          'staff_name': 'Arun',
          'subtotal': '80.00',
          'gst': '4.00',
          'total': '84.00',
          'payment_mode': 'cash',
          'status': 'processing',
          'created_at': '2026-07-29T10:30:00',
          'products': [
            {
              'id': 10,
              'product_id': 101,
              'product_name': 'Veg Sandwich',
              'price': '80.00',
              'quantity': 2,
              'unit': 'pc',
              'is_kot': true,
            },
          ],
        },
      },
    });
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetTableStatusUseCase(_OccupiedStatusRepository()),
      GetProcessingOrderUseCase(_ProcessingRepository(response)),
    );

    await controller.getTableStatuses();
    expect(controller.processingOrders[8]?.order?.products?.single.quantity, 2);
    expect(controller.processingOrders[8]?.order?.staffName, 'Arun');
    await controller.showKotTableDetails(8);

    expect(controller.processingOrder.value?.order?.orderId, 'ORD-55');
    expect(controller.kotStage.value, KotStage.details);

    controller.continueProcessingOrder();

    expect(controller.activeTableNumber.value, 8);
    expect(controller.savedOrderNumber.value, 'ORD-55');
    expect(controller.cart.single.product.name, 'Veg Sandwich');
    expect(controller.cart.single.quantity, 2);
    expect(controller.kotStage.value, KotStage.order);
  });

  test('does not override a free status returned by the status API', () async {
    const response = ProcessingOrderResponse(
      status: true,
      data: ProcessingOrderData(
        isProcessing: true,
        table: ProcessingTable(tableId: 8),
        order: ProcessingOrder(
          id: 55,
          tableId: 8,
          products: <ProcessingProduct>[
            ProcessingProduct(id: 10, productId: 101, quantity: 1),
          ],
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
      GetTableStatusUseCase(_FreeStatusRepository()),
      const GetProcessingOrderUseCase(_ProcessingRepository(response)),
    );

    await controller.getTableStatuses();

    expect(controller.tableStatuses[8]?.occupied, isFalse);
    expect(controller.processingOrders.containsKey(8), isFalse);
  });

  test(
    'a refreshed occupied API status replaces the locally closed state',
    () async {
      const response = ProcessingOrderResponse(
        status: true,
        data: ProcessingOrderData(
          isProcessing: true,
          table: ProcessingTable(tableId: 8),
          order: ProcessingOrder(
            id: 55,
            tableId: 8,
            products: <ProcessingProduct>[
              ProcessingProduct(id: 10, productId: 101, quantity: 1),
            ],
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
        GetTableStatusUseCase(_OccupiedStatusRepository()),
        const GetProcessingOrderUseCase(_ProcessingRepository(response)),
      );
      controller.deletedKitchenTables.add(8);

      await controller.getTableStatuses();

      expect(controller.tableStatuses[8]?.occupied, isTrue);
      expect(controller.processingOrders[8]?.order?.id, 55);
      expect(controller.deletedKitchenTables, isNot(contains(8)));
    },
  );

  test(
    'does not infer a free table from zero-quantity order details',
    () async {
      const emptyResponse = ProcessingOrderResponse(
        status: true,
        data: ProcessingOrderData(
          isProcessing: true,
          order: ProcessingOrder(
            id: 77,
            tableId: 8,
            products: <ProcessingProduct>[
              ProcessingProduct(id: 10, productId: 101, quantity: 0),
            ],
          ),
        ),
      );
      final closeRepository = _ClosingKotRepository();
      final controller = HomeController(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        GetTableStatusUseCase(_OccupiedStatusRepository()),
        const GetProcessingOrderUseCase(_ProcessingRepository(emptyResponse)),
        null,
        SaveKotUseCase(closeRepository),
      );

      await controller.getTableStatuses();

      expect(closeRepository.tableIds, isEmpty);
      expect(controller.tableStatuses[8]?.occupied, isTrue);
      expect(controller.processingOrders[8]?.order, isNotNull);
      expect(controller.deletedKitchenTables, isNot(contains(8)));
    },
  );
}

class _ClosingKotRepository implements KotSaveRepository {
  final tableIds = <int>[];

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    tableIds.add(tableId);
    return const KotSaveResponse(status: true, message: 'Bill closed');
  }
}

class _ProcessingRepository implements ProcessingOrderRepository {
  const _ProcessingRepository(this.response);

  final ProcessingOrderResponse response;

  @override
  Future<ProcessingOrderResponse> getProcessingOrder(int tableId) async {
    final responseTableId =
        response.data?.table?.tableId ?? response.data?.order?.tableId;
    if (responseTableId != null && responseTableId != tableId) {
      return ProcessingOrderResponse(
        status: false,
        message: 'No processing orders found for this table.',
        data: ProcessingOrderData(
          isProcessing: false,
          table: ProcessingTable(tableId: tableId),
        ),
      );
    }
    return response;
  }
}

class _FreeStatusRepository implements TableStatusRepository {
  @override
  Future<TableStatusResponse> getTableStatuses() async {
    return const TableStatusResponse(
      status: true,
      data: [
        TableStatusData(id: 1, tableId: 8, tableStatus: 'Free', isOccupied: 0),
      ],
    );
  }
}

class _OccupiedStatusRepository implements TableStatusRepository {
  @override
  Future<TableStatusResponse> getTableStatuses() async {
    return const TableStatusResponse(
      status: true,
      data: [
        TableStatusData(
          id: 1,
          tableId: 8,
          tableStatus: 'Occupied',
          isOccupied: 1,
        ),
      ],
    );
  }
}
