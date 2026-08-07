import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_view_repository.dart';

class TakeAwayCompletedViewRepositoryImpl
    implements TakeAwayCompletedViewRepository {
  const TakeAwayCompletedViewRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwayProcessingResponse> getCompletedTakeAwayView(
    int completedOrderId,
    int holdOrderId,
  ) async {
    final endpoint = ApiRoutes.takeAwayCompletedView(completedOrderId);
    log(
      'GET $endpoint (hold_order_id=$holdOrderId)',
      name: 'TakeAwayCompletedView',
    );
    final json = await _apiService.getWithData(
      endpoint,
      data: FormData.fromMap(<String, dynamic>{'hold_order_id': holdOrderId}),
    );
    log('Response: $json', name: 'TakeAwayCompletedView');
    final response = TakeAwayProcessingResponse.fromJson(json);
    log('Status: ${response.status}', name: 'TakeAwayCompletedView');
    return response;
  }
}
