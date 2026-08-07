import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/post_kot_model.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_order_repository.dart';

class KotOrderRepositoryImpl implements KotOrderRepository {
  const KotOrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotOrderResponse> saveKotOrder(KotOrderRequest request) async {
    final fields = request.toFormFields();
    log('POST ${ApiRoutes.kot}', name: 'KotHoldSaveOrder');
    log('Request fields: $fields', name: 'KotHoldSaveOrder');
    final response = await _apiService.post(
      ApiRoutes.kot,
      data: FormData.fromMap(fields),
    );
    log('Response: $response', name: 'KotHoldSaveOrder');

    final result = KotOrderResponse.fromJson(response);
    final order = result.data?.order;
    final productOrderIds =
        order?.products
            ?.map((product) => product.orderId)
            .whereType<int>()
            .toSet()
            .toList() ??
        const <int>[];
    log('Database order ID: ${order?.id}', name: 'KotHoldSaveOrder');
    log('Kitchen order ID: ${order?.orderId}', name: 'KotHoldSaveOrder');
    log('Table ID: ${order?.tableId}', name: 'KotHoldSaveOrder');
    log('Product order IDs: $productOrderIds', name: 'KotHoldSaveOrder');
    return result;
  }
}
