import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';

class TableStatusRepositoryImpl implements TableStatusRepository {
  const TableStatusRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TableStatusResponse> getTableStatuses() async {
    log('GET ${ApiRoutes.tableStatus}', name: 'KotTableStatus');
    final response = await _apiService.get(ApiRoutes.tableStatus);
    log('Response: $response', name: 'KotTableStatus');
    final result = TableStatusResponse.fromJson(response);
    log(
      'Status: ${result.status}, message: ${result.message}, '
      'tables: ${result.data?.length ?? 0}',
      name: 'KotTableStatus',
    );
    return result;
  }
}
