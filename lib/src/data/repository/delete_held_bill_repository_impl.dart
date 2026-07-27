import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_delete.dart';
import 'package:pick_my_snacks/src/domain/repository/delete_held_bill_repository.dart';

class DeleteHeldBillRepositoryImpl implements DeleteHeldBillRepository {
  const DeleteHeldBillRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<DeleteHeldBillResponse> deleteHeldBill(int orderId) async {
    final endpoint = ApiRoutes.deleteHoldBill(orderId);
    log('GET $endpoint', name: 'DeleteHeldBill');
    final json = await _apiService.get(endpoint);
    log('Delete-held-bill response: $json', name: 'DeleteHeldBill');

    final response = DeleteHeldBillResponse.fromJson(json);
    log('Delete status: ${response.status}', name: 'DeleteHeldBill');
    log('Delete message: ${response.message}', name: 'DeleteHeldBill');
    return response;
  }
}
