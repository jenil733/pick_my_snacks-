import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';

class KotSaveRepositoryImpl implements KotSaveRepository {
  const KotSaveRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotSaveResponse> saveKot(int tableId) async {
    final endpoint = ApiRoutes.kotSave(tableId);
    log('POST $endpoint (table_id=$tableId)', name: 'KotSaveOrder');
    final response = await _apiService.post(endpoint);
    log('Response: $response', name: 'KotSaveOrder');
    final result = KotSaveResponse.fromJson(response);
    log(
      'Status: ${result.status}, message: ${result.message} ${result.data?.completedOrder?.products}',
      name: 'KotSaveOrder',
    );
    log(
      'Completed hold order IDs: ${result.data?.completedHoldOrderIds}',
      name: 'KotSaveOrder',
    );
    log(
      'Completed hold order count: ${result.data?.completedHoldOrderCount}',
      name: 'KotSaveOrder',
    );
    log(
      'Final kitchen order ID: ${result.data?.completedOrder?.orderId}',
      name: 'KotSaveOrder',
    );
    return result;
  }
}
