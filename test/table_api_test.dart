import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/get_table.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/domain/repository/table_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_table_status_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_tables_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/kot_tables_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(CartController());
  });

  tearDown(Get.reset);

  test('parses table API fields with numeric string support', () {
    final response = TableListResponse.fromJson({
      'status': true,
      'message': 'Tables loaded',
      'data': [
        {'id': '7', 'branch_id': '2', 'table_id': '12', 'person_count': '3'},
      ],
    });

    expect(response.status, isTrue);
    expect(response.data?.single.id, 7);
    expect(response.data?.single.branchId, 2);
    expect(response.data?.single.tableId, 12);
    expect(response.data?.single.personCount, 3);
  });

  test('controller displays table IDs returned by the use case', () async {
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      GetTablesUseCase(_FakeTableRepository()),
    );

    await controller.getTables();

    expect(controller.availableTableNumbers, [3, 8]);
    expect(controller.tableError.value, isNull);
    expect(controller.isLoadingTables.value, isFalse);
  });

  test('refreshes tables every time the table screen is opened', () async {
    final repository = _CountingTableRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      GetTablesUseCase(repository),
    );

    controller.selectFlow(PosFlow.kot);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requestCount, 1);

    controller.selectFlow(PosFlow.billing);
    controller.selectFlow(PosFlow.kot);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requestCount, 2);
  });

  test('loads occupied table status and blocks taking that table', () async {
    final response = TableStatusResponse.fromJson({
      'status': true,
      'data': [
        {
          'id': '20',
          'table_id': '8',
          'table_status': 'Occupied',
          'is_occupied': true,
        },
      ],
    });
    expect(response.data?.single.occupied, isTrue);

    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      GetTableStatusUseCase(_FakeTableStatusRepository(response)),
    );
    await controller.getTableStatuses();
    controller.takeKotTable(8, staffName: 'Arun');

    expect(controller.tableStatuses[8]?.occupied, isTrue);
    expect(controller.activeTableNumber.value, isNull);
    expect(controller.tableOrders, isEmpty);
  });

  test(
    'person count keeps a restored table occupied when status says free',
    () async {
      final controller = HomeController(
        null,
        null,
        null,
        null,
        null,
        null,
        GetTablesUseCase(_PersonCountTableRepository()),
        GetTableStatusUseCase(
          _FakeTableStatusRepository(
            const TableStatusResponse(
              status: true,
              data: [
                TableStatusData(
                  id: 1,
                  tableId: 1,
                  tableStatus: 'free',
                  personCount: 0,
                ),
              ],
            ),
          ),
        ),
      );

      await controller.getTables();

      expect(controller.tables.single.personCount, 3);
      expect(controller.tableStatuses[1]?.occupied, isTrue);
      expect(controller.tableStatuses[1]?.personCount, 3);
    },
  );

  test('uses and displays the table_status value returned by the API', () {
    final response = TableStatusResponse.fromJson({
      'status': true,
      'data': [
        {'id': 9, 'table_id': 1, 'table_status': 'free'},
        {'id': 10, 'table_id': 2, 'table_status': 'processing'},
      ],
    });

    expect(response.data![0].occupied, isFalse);
    expect(response.data![0].displayStatus, 'Free');
    expect(response.data![1].occupied, isTrue);
    expect(response.data![1].displayStatus, 'Processing');
  });

  test(
    'free backend status does not clear unsent products from the active KOT',
    () async {
      final controller = HomeController(
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        GetTableStatusUseCase(
          _FakeTableStatusRepository(
            const TableStatusResponse(
              status: true,
              data: [
                TableStatusData(
                  id: 1,
                  tableId: 1,
                  tableStatus: 'free',
                  personCount: 0,
                ),
              ],
            ),
          ),
        ),
      );
      controller.takeKotTable(1, staffName: 'Staff', staffId: 3);
      controller.addProduct(
        const Product(
          id: 4,
          name: 'Local product',
          unit: '1 pc',
          price: 20,
          image: '',
        ),
      );
      controller.tableStatuses[1] = const TableStatusData(
        id: 1,
        tableId: 1,
        tableStatus: 'occupied',
        personCount: 1,
      );

      await controller.getTableStatuses(silent: true);

      expect(controller.activeTableNumber.value, 1);
      expect(controller.cart.single.product.id, 4);
      expect(controller.tableOrders[1]?.items.single.product.id, 4);
    },
  );

  testWidgets('table screen shows the status returned by the API', (
    tester,
  ) async {
    const statuses = TableStatusResponse(
      status: true,
      data: [
        TableStatusData(id: 10, tableId: 8, tableStatus: 'free'),
        TableStatusData(id: 11, tableId: 3, tableStatus: 'processing'),
      ],
    );
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      GetTablesUseCase(_FakeTableRepository()),
      GetTableStatusUseCase(_FakeTableStatusRepository(statuses)),
    );
    await controller.getTables();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KotTablesView(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Processing'), findsOneWidget);
  });

  testWidgets('table screen does not count KOT submissions as persons', (
    tester,
  ) async {
    final controller = HomeController();
    controller.tables.assignAll(const <TableData>[
      TableData(id: 1, branchId: 1, tableId: 1, personCount: 1),
    ]);
    controller.tableStatuses[1] = const TableStatusData(
      id: 1,
      tableId: 1,
      tableStatus: 'occupied',
      isOccupied: 1,
      personCount: 1,
    );
    controller.processingOrders[1] = const ProcessingOrderData(
      isProcessing: true,
      order: ProcessingOrder(
        tableId: 1,
        staffName: 'Arun',
        processingOrderCount: 5,
        processingOrderIds: <int>[11, 12, 13, 14, 15],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KotTablesView(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('1 Person - Arun'), findsOneWidget);
    expect(find.textContaining('5 Persons'), findsNothing);
  });
}

class _FakeTableRepository implements TableRepository {
  @override
  Future<TableListResponse> getTables() async {
    return const TableListResponse(
      status: true,
      data: [
        TableData(id: 10, branchId: 1, tableId: 8),
        TableData(id: 11, branchId: 1, tableId: 3),
      ],
    );
  }
}

class _CountingTableRepository implements TableRepository {
  int requestCount = 0;

  @override
  Future<TableListResponse> getTables() async {
    requestCount++;
    return const TableListResponse(status: true, data: []);
  }
}

class _PersonCountTableRepository implements TableRepository {
  @override
  Future<TableListResponse> getTables() async {
    return const TableListResponse(
      status: true,
      data: [TableData(id: 1, branchId: 1, tableId: 1, personCount: 3)],
    );
  }
}

class _FakeTableStatusRepository implements TableStatusRepository {
  const _FakeTableStatusRepository(this.response);

  final TableStatusResponse response;

  @override
  Future<TableStatusResponse> getTableStatuses({
    int? staffId,
    required String paymentMode,
    List<int> productIds = const <int>[1],
  }) async => response;
}
