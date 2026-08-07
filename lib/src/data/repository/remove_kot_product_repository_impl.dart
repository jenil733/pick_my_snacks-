import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_product_repository.dart';

class RemoveKotProductRepositoryImpl implements RemoveKotProductRepository {
  const RemoveKotProductRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<RemoveKotProductResponse> removeKotProduct(
    RemoveKotProductRequest request,
  ) async {
    final fields = request.toFormFields();
    log('POST ${ApiRoutes.remove}', name: 'RemoveKotProduct');
    log('Request fields: $fields', name: 'RemoveKotProduct');
    log(
      'DELETE TARGET -> order_id=${request.orderId}, '
      'detail_id=${request.detailId}',
      name: 'RemoveKotProduct',
    );

    final json = await _apiService.post(
      ApiRoutes.remove,
      data: FormData.fromMap(fields),
    );
    log('Response: $json', name: 'RemoveKotProduct');

    final response = RemoveKotProductResponse.fromJson(json);
    final removed = response.data?.removedProduct;
    final order = response.data?.order;
    log(
      'DELETE RESULT -> requested_order_id=${request.orderId}, '
      'requested_detail_id=${request.detailId}, '
      'removed_product_id=${removed?.productId}, '
      'removed_detail_id=${removed?.detailId}, '
      'response_order_id=${order?.id}, '
      'remaining_product_count=${response.data?.remainingProductCount}',
      name: 'RemoveKotProduct',
    );
    log('Status: ${response.status}', name: 'RemoveKotProduct');
    log('Message: ${response.message}', name: 'RemoveKotProduct');
    log(
      'Removed detail: ${removed?.detailId}, product: ${removed?.productId} '
      '(${removed?.productName}), quantity: ${removed?.quantity}, '
      'row total: ${removed?.rowTotal}',
      name: 'RemoveKotProduct',
    );
    log(
      'Remaining products: ${response.data?.remainingProductCount}',
      name: 'RemoveKotProduct',
    );
    log(
      'Updated order ${order?.id}: subtotal=${order?.subtotal}, '
      'gst=${order?.gst}, total=${order?.total}',
      name: 'RemoveKotProduct',
    );
    return response;
  }
}
