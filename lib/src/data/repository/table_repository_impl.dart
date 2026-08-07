import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_table.dart';
import 'package:pick_my_snacks/src/domain/repository/table_repository.dart';

class TableRepositoryImpl implements TableRepository {
  const TableRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TableListResponse> getTables() async {
    log('GET ${ApiRoutes.tables}', name: 'GetKotTables');
    final response = await _apiService.get(ApiRoutes.tables);
    log('Response: $response', name: 'GetKotTables');
    final result = TableListResponse.fromJson(response);
    log(
      'Status: ${result.status}, message: ${result.message}, '
      'tables: ${result.data?.length ?? 0}',
      name: 'GetKotTables',
    );
    return result;
  }
}
