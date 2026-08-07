import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_repository.dart';

class TakeAwayCompletedRepositoryImpl implements TakeAwayCompletedRepository {
  const TakeAwayCompletedRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwayProcessingResponse> getCompletedTakeAway([
    int? holdOrderId,
  ]) async {
    log(
      'GET ${ApiRoutes.takeAwayCompleted}'
      '${holdOrderId == null ? '' : ' (hold_order_id=$holdOrderId)'}',
      name: 'TakeAwayCompleted',
    );
    final json = holdOrderId == null
        ? await _apiService.get(ApiRoutes.takeAwayCompleted)
        : await _apiService.getWithData(
            ApiRoutes.takeAwayCompleted,
            data: FormData.fromMap(<String, dynamic>{
              'hold_order_id': holdOrderId,
            }),
          );
    log('Response: $json', name: 'TakeAwayCompleted');
    final response = TakeAwayProcessingResponse.fromJson(json);
    log('Status: ${response.status}', name: 'TakeAwayCompleted');
    log('Orders: ${response.orders.length}', name: 'TakeAwayCompleted');
    return response;
  }
}
