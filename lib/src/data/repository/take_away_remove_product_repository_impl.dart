import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_product.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_remove_product_repository.dart';

class TakeAwayRemoveProductRepositoryImpl
    implements TakeAwayRemoveProductRepository {
  const TakeAwayRemoveProductRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<RemoveKotProductResponse> removeTakeAwayProduct(
    RemoveKotProductRequest request,
  ) async {
    final fields = <String, dynamic>{
      'order_id': request.orderId,
      'detail_id': request.detailId,
    };
    log(
      'POST ${ApiRoutes.takeAwayRemoveProduct}: $fields',
      name: 'TakeAwayRemoveProduct',
    );
    final json = await _apiService.post(
      ApiRoutes.takeAwayRemoveProduct,
      data: FormData.fromMap(fields),
    );
    return RemoveKotProductResponse.fromJson(json);
  }
}
