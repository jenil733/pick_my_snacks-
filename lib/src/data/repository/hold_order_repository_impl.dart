import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/hold_order.dart';
import 'package:pick_my_snacks/src/domain/repository/hold_order_repository.dart';

class HoldOrderRepositoryImpl implements HoldOrderRepository {
  const HoldOrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<HoldOrderResponse> holdOrder(HoldOrderRequest request) async {
    final fields = request.toFormFields();

    log('POST ${ApiRoutes.hold}', name: 'HoldOrder');
    log('Hold-order request fields:', name: 'HoldOrder');
    for (final field in fields.entries) {
      log('${field.key}: ${field.value}', name: 'HoldOrder');
    }

    final response = await _apiService.post(
      ApiRoutes.hold,
      data: FormData.fromMap(fields),
    );
    log('Hold-order response: $response', name: 'HoldOrder');

    final result = HoldOrderResponse.fromJson(response);
    final order = result.data?.order;
    log('Hold-order status: ${result.status}', name: 'HoldOrder');
    log('Hold-order message: ${result.message}', name: 'HoldOrder');
    log('Held order database ID: ${order?.id}', name: 'HoldOrder');
    log('Held order ID: ${order?.orderId}', name: 'HoldOrder');
    log('Held order staff ID: ${order?.staffId}', name: 'HoldOrder');
    log('Held order payment mode: ${order?.paymentMode}', name: 'HoldOrder');
    log('Held order total: ${order?.total}', name: 'HoldOrder');

    return result;
  }
}
