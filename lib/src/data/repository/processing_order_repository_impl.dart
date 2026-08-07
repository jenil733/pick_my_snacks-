import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/processing.dart';
import 'package:pick_my_snacks/src/domain/repository/processing_order_repository.dart';

class ProcessingOrderRepositoryImpl implements ProcessingOrderRepository {
  const ProcessingOrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<ProcessingOrderResponse> getProcessingOrder(int tableId) async {
    final endpoint = ApiRoutes.processingOrder(tableId);
    log('GET $endpoint (table_id=$tableId)', name: 'GetProcessingOrder');
    final response = await _apiService.get(
      endpoint,
      acceptedStatusCodes: const <int>{404},
    );
    log('Response: $response', name: 'GetProcessingOrder');
    final result = ProcessingOrderResponse.fromJson(response);
    log(
      'Status: ${result.status}, message: ${result.message}, '
      'is_processing: ${result.data?.isProcessing}, '
      'products: ${result.data?.order?.products?.length ?? 0}',
      name: 'GetProcessingOrder',
    );
    return result;
  }
}
