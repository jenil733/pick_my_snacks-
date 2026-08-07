import 'package:pick_my_snacks/src/data/model/take_away_hold.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_hold_repository.dart';

class TakeAwayHoldUseCase {
  const TakeAwayHoldUseCase(this._repository);

  final TakeAwayHoldRepository _repository;

  Future<TakeAwayHoldResponse> call(TakeAwayHoldRequest request) {
    return _repository.holdTakeAway(request);
  }
}
