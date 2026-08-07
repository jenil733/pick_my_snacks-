import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_quantity_repository.dart';

class RemoveKotQuantityRepositoryImpl implements RemoveKotQuantityRepository {
  const RemoveKotQuantityRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<RemoveKotQuantityResponse> removeKotQuantity(
    RemoveKotQuantityRequest request,
  ) async {
    final fields = request.toFormFields();
    log('POST ${ApiRoutes.rquantity}', name: 'RemoveKotQuantity');
    log('Request fields: $fields', name: 'RemoveKotQuantity');
    final json = await _apiService.post(
      ApiRoutes.rquantity,
      data: FormData.fromMap(fields),
    );
    log('Response: $json', name: 'RemoveKotQuantity');

    final response = RemoveKotQuantityResponse.fromJson(json);
    final product = response.data?.product;
    final order = response.data?.order;
    log('Status: ${response.status}', name: 'RemoveKotQuantity');
    log('Message: ${response.message}', name: 'RemoveKotQuantity');
    log(
      'Product ${product?.productId}, detail ${product?.detailId}: '
      '${product?.previousQuantity} - ${product?.removedQuantity} = '
      '${product?.remainingQuantity}, row total=${product?.rowTotal}',
      name: 'RemoveKotQuantity',
    );
    log(
      'Updated order ${order?.id}: subtotal=${order?.subtotal}, '
      'gst=${order?.gst}, total=${order?.total}',
      name: 'RemoveKotQuantity',
    );
    return response;
  }
}
