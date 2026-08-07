import 'package:pick_my_snacks/src/data/model/remove_kot_quantity.dart';
import 'package:pick_my_snacks/src/domain/repository/remove_kot_quantity_repository.dart';

class RemoveKotQuantityUseCase {
  const RemoveKotQuantityUseCase(this._repository);

  final RemoveKotQuantityRepository _repository;

  Future<RemoveKotQuantityResponse> call(RemoveKotQuantityRequest request) {
    return _repository.removeKotQuantity(request);
  }
}
