import 'package:flutter/foundation.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/core/services/api_services.dart';
import 'package:pick_my_snacks/src/data/model/kot_delete_person.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_delete_person_repository.dart';

class KotDeletePersonRepositoryImpl implements KotDeletePersonRepository {
  const KotDeletePersonRepositoryImpl(this._apiService);

  final ApiService _apiService;

  @override
  Future<KotDeletePersonResponse> deletePerson(
    int tableId,
    String personId,
  ) async {
    final endpoint = ApiRoutes.kotDeletePerson(tableId, personId);
    debugPrint(
      '[KotPersonDelete] API CALL: POST ${ApiRoutes.baseUrl}$endpoint',
    );
    final response = await _apiService.post(endpoint);
    debugPrint('[KotPersonDelete] API RESPONSE: $response');
    return KotDeletePersonResponse.fromJson(response);
  }
}
