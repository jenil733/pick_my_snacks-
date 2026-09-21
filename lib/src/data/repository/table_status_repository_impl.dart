import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_table_status.dart';
import 'package:pick_my_snacks/src/domain/repository/table_status_repository.dart';

class TableStatusRepositoryImpl implements TableStatusRepository {
  const TableStatusRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TableStatusResponse> getTableStatuses({
    int? staffId,
    required String paymentMode,
    List<int> productIds = const <int>[1],
  }) async {
    final fields = <String, dynamic>{'payment_mode': paymentMode};
    if (staffId != null) fields['staff_id'] = staffId;
    final formData = FormData.fromMap(fields);
    for (final productId in productIds) {
      formData.fields.add(MapEntry('products[]', productId.toString()));
    }
    debugPrint(
      '[KotTableStatus] API CALL: GET '
      '${ApiRoutes.baseUrl}${ApiRoutes.tableStatus}',
    );
    debugPrint('[KotTableStatus] FORM FIELDS: ${formData.fields}');
    final response = await _apiService.getWithData(
      ApiRoutes.tableStatus,
      data: formData,
    );
    debugPrint('[KotTableStatus] API RESPONSE: $response');
    final result = TableStatusResponse.fromJson(response);
    return result;
  }
}
