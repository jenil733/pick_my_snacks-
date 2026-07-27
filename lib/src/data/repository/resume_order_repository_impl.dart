import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_resume.dart';
import 'package:pick_my_snacks/src/domain/repository/resume_order_repository.dart';

class ResumeOrderRepositoryImpl implements ResumeOrderRepository {
  const ResumeOrderRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<ResumeOrderResponse> resumeOrder(int orderId) async {
    final endpoint = ApiRoutes.resumeHoldBill(orderId);
    log('GET $endpoint', name: 'ResumeOrder');
    final json = await _apiService.get(endpoint);
    log('Resume-order response: $json', name: 'ResumeOrder');

    final response = ResumeOrderResponse.fromJson(json);
    log(
      'Resumed order ID: ${response.data?.bill?.orderId}, '
      'products: ${response.data?.products?.length ?? 0}, '
      'GST: ${response.data?.bill?.gst}, '
      'total: ${response.data?.bill?.total}',
      name: 'ResumeOrder',
    );
    return response;
  }
}
