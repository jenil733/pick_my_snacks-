import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/kot_save_request.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';

class KotSaveRepositoryImpl implements KotSaveRepository {
  const KotSaveRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotSaveResponse> saveKot(KotSaveRequest request) async {
    final endpoint = ApiRoutes.kotSave(request.tableId);
    final fields = request.toFormFields();
    debugPrint('[KotSaveOrder] API CALL: POST ${ApiRoutes.baseUrl}$endpoint');
    debugPrint('[KotSaveOrder] FORM FIELDS: $fields');
    log('POST $endpoint (table_id=${request.tableId})', name: 'KotSaveOrder');
    final response = await _apiService.post(
      endpoint,
      data: FormData.fromMap(fields),
    );
    debugPrint('[KotSaveOrder] API RESPONSE: $response');
    log('Response: $response', name: 'KotSaveOr0811der');
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
