import 'package:pick_my_snacks/src/data/model/kot_get_persons.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_get_persons_repository.dart';

class GetKotPersonsUseCase {
  const GetKotPersonsUseCase(this._repository);

  final KotGetPersonsRepository _repository;

  Future<KotGetPersonsResponse> call(int tableId) {
    return _repository.getPersons(tableId);
  }
}
