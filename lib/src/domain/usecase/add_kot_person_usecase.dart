import 'package:pick_my_snacks/src/data/model/kot_add_person.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_add_person_repository.dart';

class AddKotPersonUseCase {
  const AddKotPersonUseCase(this._repository);

  final KotAddPersonRepository _repository;

  Future<KotAddPersonResponse> call(KotAddPersonRequest request) {
    return _repository.addPerson(request);
  }
}
