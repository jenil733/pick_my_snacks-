import 'package:pick_my_snacks/src/data/model/take_away_change_quantity.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_change_quantity_repository.dart';

class TakeAwayChangeQuantityUseCase {
  const TakeAwayChangeQuantityUseCase(this._repository);

  final TakeAwayChangeQuantityRepository _repository;

  Future<TakeAwayChangeQuantityResponse> call(
    TakeAwayChangeQuantityRequest request,
  ) {
    return _repository.changeTakeAwayQuantity(request);
  }
}
