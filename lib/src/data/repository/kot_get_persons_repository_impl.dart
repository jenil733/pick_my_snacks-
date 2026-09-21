import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/kot_get_persons.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_get_persons_repository.dart';

class KotGetPersonsRepositoryImpl implements KotGetPersonsRepository {
  const KotGetPersonsRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotGetPersonsResponse> getPersons(int tableId) async {
    final endpoint = ApiRoutes.kotGetPersons(tableId);
    debugPrint('[KotGetPersons] API CALL: GET ${ApiRoutes.baseUrl}$endpoint');
    log('GET $endpoint', name: 'KotGetPersons');
    final json = await _apiService.get(endpoint);
    debugPrint('[KotGetPersons] API RESPONSE: $json');
    return KotGetPersonsResponse.fromJson(json);
  }
}
