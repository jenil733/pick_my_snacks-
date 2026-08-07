import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_hold_repository.dart';

class TakeAwayHoldRepositoryImpl implements TakeAwayHoldRepository {
  const TakeAwayHoldRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwayHoldResponse> holdTakeAway(TakeAwayHoldRequest request) async {
    final fields = request.toFormFields();
    log('POST ${ApiRoutes.takeAwayHold}', name: 'TakeAwayHold');
    for (final field in fields.entries) {
      log('${field.key}: ${field.value}', name: 'TakeAwayHold');
    }

    final json = await _apiService.post(
      ApiRoutes.takeAwayHold,
      data: FormData.fromMap(fields),
    );
    log('Response: $json', name: 'TakeAwayHold');

    final response = TakeAwayHoldResponse.fromJson(json);
    final order = response.data?.order;
    log('Status: ${response.status}', name: 'TakeAwayHold');
    log('Message: ${response.message}', name: 'TakeAwayHold');
    log('Order database ID: ${order?.id}', name: 'TakeAwayHold');
    log('Order ID: ${order?.orderId}', name: 'TakeAwayHold');
    log('Order total: ${order?.total}', name: 'TakeAwayHold');
    return response;
  }
}
