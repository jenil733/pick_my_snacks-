import 'dart:developer';

import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/get_hold.dart';
import 'package:pick_my_snacks/src/domain/repository/get_hold_orders_repository.dart';

class GetHoldOrdersRepositoryImpl implements GetHoldOrdersRepository {
  const GetHoldOrdersRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<GetHoldOrdersResponse> getHoldOrders() async {
    log('GET ${ApiRoutes.getHold}', name: 'GetHoldOrders');
    final json = await _apiService.get(ApiRoutes.getHold);
    log('Get-held-orders response: $json', name: 'GetHoldOrders');

    final response = GetHoldOrdersResponse.fromJson(json);
    log(
      'Held orders received: ${response.data?.length ?? 0}',
      name: 'GetHoldOrders',
    );
    for (final order in response.data ?? const <HeldOrderSummary>[]) {
      log(
        'Order ID: ${order.orderId}, items: ${order.itemsCount}, '
        'GST: ${order.gst}, total: ${order.total}, status: ${order.status}',
        name: 'GetHoldOrders',
      );
    }
    return response;
  }
}
