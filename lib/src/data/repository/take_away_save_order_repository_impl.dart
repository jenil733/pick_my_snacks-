import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/take_away_save_order.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_save_order_repository.dart';

class TakeAwaySaveOrderRepositoryImpl implements TakeAwaySaveOrderRepository {
  const TakeAwaySaveOrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwaySaveOrderResponse> saveTakeAwayOrder(
    TakeAwaySaveOrderRequest request,
  ) async {
    final fields = request.toFormFields();
    log('POST ${ApiRoutes.takeAwaySaveOrder}', name: 'TakeAwaySaveOrder');
    log('hold_order_id: ${request.holdOrderId}', name: 'TakeAwaySaveOrder');

    final json = await _apiService.post(
      ApiRoutes.takeAwaySaveOrder,
      data: FormData.fromMap(fields),
    );
    log('Response: $json', name: 'TakeAwaySaveOrder');

    final response = TakeAwaySaveOrderResponse.fromJson(json);
    log('Status: ${response.status}', name: 'TakeAwaySaveOrder');
    log('Message: ${response.message}', name: 'TakeAwaySaveOrder');
    log(
      'Final order ID: ${response.order?.orderId}',
      name: 'TakeAwaySaveOrder',
    );
    return response;
  }
}
