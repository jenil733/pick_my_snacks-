import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<SaveOrderResponse> saveOrder(SaveOrderRequest request) async {
    final fields = request.toFormFields();

    log('POST ${ApiRoutes.save}', name: 'SaveOrder');
    log('Save-order request fields:', name: 'SaveOrder');
    for (final field in fields.entries) {
      log('${field.key}: ${field.value}', name: 'SaveOrder');
    }

    final response = await _apiService.post(
      ApiRoutes.save,
      data: FormData.fromMap(fields),
    );
    log('Save-order response: $response', name: 'SaveOrder');

    final result = SaveOrderResponse.fromJson(response);
    final order = result.data?.order;
    log('Save-order status: ${result.status}', name: 'SaveOrder');
    log('Save-order message: ${result.message}', name: 'SaveOrder');
    log('Order database ID: ${order?.id}', name: 'SaveOrder');
    log('Order ID: ${order?.orderId}', name: 'SaveOrder');
    log('Order staff ID: ${order?.staffId}', name: 'SaveOrder');
    log('Order payment mode: ${order?.paymentMode}', name: 'SaveOrder');
    log('Order total: ${order?.total}', name: 'SaveOrder');

    return result;
  }
}
