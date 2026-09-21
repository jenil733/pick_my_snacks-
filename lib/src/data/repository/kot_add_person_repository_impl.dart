import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/kot_add_person.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_add_person_repository.dart';

class KotAddPersonRepositoryImpl implements KotAddPersonRepository {
  const KotAddPersonRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotAddPersonResponse> addPerson(KotAddPersonRequest request) async {
    final endpoint = ApiRoutes.kotAddPerson(request.tableId);
    final formData = FormData.fromMap(request.toFormFields());
    for (final productId in request.productIds) {
      formData.fields.add(MapEntry('products[]', productId.toString()));
    }
    debugPrint('[KotAddPerson] API CALL: POST ${ApiRoutes.baseUrl}$endpoint');
    debugPrint('[KotAddPerson] FORM FIELDS: ${formData.fields}');
    log('POST $endpoint', name: 'KotAddPerson');
    try {
      final response = await _apiService.post(endpoint, data: formData);
      debugPrint('[KotAddPerson] API RESPONSE: $response');
      log('Response: $response', name: 'KotAddPerson');
      return KotAddPersonResponse.fromJson(response);
    } catch (error, stackTrace) {
      debugPrint('[KotAddPerson] API ERROR: $error');
      debugPrintStack(
        label: '[KotAddPerson] STACK TRACE',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
