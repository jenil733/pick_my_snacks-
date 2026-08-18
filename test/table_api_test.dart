import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/get_table.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/domain/repository/table_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_table_status_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/get_tables_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';
import 'package:pick_my_snacks/src/presentation/view/homescreen/kot_tables_view.dart';

void main() {
  test('parses table API fields with numeric string support', () {
    final response = TableListResponse.fromJson({
      'status': true,
      'message': 'Tables loaded',
      'data': [
        {'id': '7', 'branch_id': '2', 'table_id': '12'},
      ],
    });

    expect(response.status, isTrue);
    expect(response.data?.single.id, 7);
    expect(response.data?.single.branchId, 2);
    expect(response.data?.single.tableId, 12);
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

class _FakeTableStatusRepository implements TableStatusRepository {
  const _FakeTableStatusRepository(this.response);

  final TableStatusResponse response;

  @override
  Future<TableStatusResponse> getTableStatuses() async => response;
}
