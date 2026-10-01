import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/data/model/take_away_change_quantity.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_change_quantity_repository.dart';

class TakeAwayChangeQuantityRepositoryImpl
    implements TakeAwayChangeQuantityRepository {
  const TakeAwayChangeQuantityRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<TakeAwayChangeQuantityResponse> changeTakeAwayQuantity(
    TakeAwayChangeQuantityRequest request,
  ) async {
    final fields = request.toFormFields();
    log(
      'POST ${ApiRoutes.takeAwayChangeQuantity}: $fields',
      name: 'TakeAwayChangeQuantity',
    );
    final json = await _apiService.post(
      ApiRoutes.takeAwayChangeQuantity,
      data: FormData.fromMap(fields),
    );
    return RemoveKotQuantityResponse.fromJson(json);
  }
}
