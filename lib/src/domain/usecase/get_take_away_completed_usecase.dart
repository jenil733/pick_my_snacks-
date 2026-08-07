import 'package:pick_my_snacks/src/data/model/take_away_processing.dart';
import 'package:pick_my_snacks/src/domain/repository/take_away_completed_repository.dart';

class GetTakeAwayCompletedUseCase {
  const GetTakeAwayCompletedUseCase(this._repository);

  final TakeAwayCompletedRepository _repository;

  Future<TakeAwayProcessingResponse> call([int? holdOrderId]) {
    return _repository.getCompletedTakeAway(holdOrderId);
  }
}
