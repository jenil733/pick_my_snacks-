import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_processing_repository.dart';

class TakeAwayProcessingRepositoryImpl implements TakeAwayProcessingRepository {
  const TakeAwayProcessingRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwayProcessingResponse> getProcessingTakeAway([
    int? holdOrderId,
  ]) async {
    log(
      'GET ${ApiRoutes.takeAwayProcessing}'
      '${holdOrderId == null ? '' : ' (hold_order_id=$holdOrderId)'}',
      name: 'TakeAwayProcessing',
    );
    final json = holdOrderId == null
        ? await _apiService.get(ApiRoutes.takeAwayProcessing)
        : await _apiService.getWithData(
            ApiRoutes.takeAwayProcessingView(holdOrderId),
            data: FormData.fromMap(<String, dynamic>{
              'hold_order_id': holdOrderId,
            }),
          );
    log('Response: $json', name: 'TakeAwayProcessing');
    final response = TakeAwayProcessingResponse.fromJson(json);
    log('Status: ${response.status}', name: 'TakeAwayProcessing');
    log('Orders: ${response.orders.length}', name: 'TakeAwayProcessing');
    return response;
  }
}
