import 'package:pick_my_snacks/src/data/model/get_saveorder.dart';
import 'package:pick_my_snacks/src/data/model/kot_save_request.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_save_repository.dart';

class SaveKotUseCase {
  const SaveKotUseCase(this._repository);

  final KotSaveRepository _repository;

  Future<KotSaveResponse> call(KotSaveRequest request) {
    return _repository.saveKot(request);
  }
}
