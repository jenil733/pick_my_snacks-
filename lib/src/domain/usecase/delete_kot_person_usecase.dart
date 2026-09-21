import 'package:pick_my_snacks/src/data/model/kot_delete_person.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_delete_person_repository.dart';

class DeleteKotPersonUseCase {
  const DeleteKotPersonUseCase(this._repository);

  final KotDeletePersonRepository _repository;

  Future<KotDeletePersonResponse> call(int tableId, String personId) {
    return _repository.deletePerson(tableId, personId);
  }
}
